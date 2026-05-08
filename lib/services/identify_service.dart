import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

enum IdentifyKind { plant, animal }

class IdentifyCandidate {
  final String scientificName;
  final String? commonName;
  final double score; // 0..1

  const IdentifyCandidate({
    required this.scientificName,
    required this.score,
    this.commonName,
  });

  String displayName() {
    final c = (commonName ?? '').trim();
    if (c.isNotEmpty) return c;
    return scientificName;
  }
}

class IdentifyResult {
  final List<IdentifyCandidate> candidates;

  const IdentifyResult(this.candidates);
}

class IdentifyException implements Exception {
  final String message;
  final int? statusCode;

  const IdentifyException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// Online identify:
/// - Plant: Pl@ntNet (API key)
/// - Animal: Clarifai (PAT + model)
class IdentifyService {
  // Pl@ntNet
  static final Uri _plantNetBase = Uri.parse('https://my-api.plantnet.org/v2/identify/all');

  // Pl@ntNet requires an API key as query parameter.
  // Provide at runtime using: --dart-define=PLANTNET_API_KEY="YOUR_KEY"
  static const String _plantNetApiKey = String.fromEnvironment('PLANTNET_API_KEY', defaultValue: '2b10mYYBZgyjpegGaXXFWTMnMO');

  // Clarifai requires a PAT for API access.
  // Provide at runtime using: --dart-define=CLARIFAI_PAT="YOUR_PAT"
  static const String _clarifaiPat = String.fromEnvironment('CLARIFAI_PAT', defaultValue: '575eaab93cfb40508695862b7cd83213');
  // Default Clarifai public "general" model (works well for animals too).
  // Override with: --dart-define=CLARIFAI_MODEL_ID="YOUR_MODEL_ID"
  static const String _clarifaiModelId =
      String.fromEnvironment('CLARIFAI_MODEL_ID', defaultValue: 'aaa03c23b3724a16a56b629203edc62c');
  static final Uri _clarifaiModelsBase = Uri.parse('https://api.clarifai.com/v2/models');

  Future<IdentifyResult> identifyFromImageFile(
    IdentifyKind kind,
    File file, {
    String locale = 'en',
    int maxResults = 8,
  }) {
    switch (kind) {
      case IdentifyKind.plant:
        return identifyPlantFromImageFile(file, locale: locale, maxResults: maxResults);
      case IdentifyKind.animal:
        return identifyAnimalFromImageFile(file, maxResults: maxResults);
    }
  }

  Future<IdentifyResult> identifyPlantFromImageFile(
    File file, {
    String locale = 'en',
    int maxResults = 8,
  }) async {
    final key = _plantNetApiKey.trim();
    if (key.isEmpty) {
      throw const IdentifyException('Online identification not configured (missing PLANTNET_API_KEY).');
    }

    final uri = _plantNetBase.replace(
      queryParameters: <String, String>{
        'api-key': key,
        'lang': locale,
        'nb-results': maxResults.toString(),
        'no-reject': 'true',
      },
    );

    // PlantNet expects multipart "images" (one or more). We'll send one image.
    final req = http.MultipartRequest('POST', uri)
      ..headers['Accept'] = 'application/json'
      ..files.add(await http.MultipartFile.fromPath('images', file.path));

    final streamed = await req.send();
    final resp = await http.Response.fromStream(streamed);
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw IdentifyException('Identify failed (${resp.statusCode})', statusCode: resp.statusCode);
    }

    final Map<String, dynamic> json = jsonDecode(resp.body) as Map<String, dynamic>;
    final List<dynamic> results = (json['results'] as List<dynamic>? ?? const []);

    final candidates = <IdentifyCandidate>[];
    for (final r in results) {
      if (r is! Map<String, dynamic>) continue;
      final species = r['species'];
      if (species is! Map<String, dynamic>) continue;

      // Prefer full scientificName (includes authorship).
      final scientific = (species['scientificName'] as String?)?.trim();
      if (scientific == null || scientific.isEmpty) continue;

      String? common;
      final cn = species['commonNames'];
      if (cn is List && cn.isNotEmpty) {
        final first = cn.first;
        if (first is String && first.trim().isNotEmpty) {
          common = first.trim();
        }
      }

      final scoreRaw = r['score'];
      final score = scoreRaw is num ? scoreRaw.toDouble().clamp(0.0, 1.0) : 0.0;

      candidates.add(
        IdentifyCandidate(
          scientificName: scientific,
          commonName: (common == null || common.isEmpty) ? null : common,
          score: score,
        ),
      );
      if (candidates.length >= maxResults) break;
    }

    return IdentifyResult(candidates);
  }

  Future<IdentifyResult> identifyAnimalFromImageFile(
    File file, {
    int maxResults = 8,
  }) async {
    final pat = _clarifaiPat.trim();
    if (pat.isEmpty) {
      throw const IdentifyException('Online identification not configured (missing CLARIFAI_PAT).');
    }

    final Uint8List bytes = await file.readAsBytes();
    final b64 = base64Encode(bytes);
    final uri = _clarifaiModelsBase.replace(path: '${_clarifaiModelsBase.path}/$_clarifaiModelId/outputs');

    final resp = await http.post(
      uri,
      headers: <String, String>{
        'Authorization': 'Key $pat',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(<String, dynamic>{
        'inputs': [
          {
            'data': {
              'image': {'base64': b64}
            }
          }
        ]
      }),
    );

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw IdentifyException('Identify failed (${resp.statusCode})', statusCode: resp.statusCode);
    }

    final Map<String, dynamic> json = jsonDecode(resp.body) as Map<String, dynamic>;
    final outputs = json['outputs'];
    if (outputs is! List || outputs.isEmpty) return const IdentifyResult([]);
    final o0 = outputs.first;
    if (o0 is! Map<String, dynamic>) return const IdentifyResult([]);
    final data = o0['data'];
    if (data is! Map<String, dynamic>) return const IdentifyResult([]);
    final concepts = data['concepts'];
    if (concepts is! List) return const IdentifyResult([]);

    final candidates = <IdentifyCandidate>[];
    for (final c in concepts) {
      if (c is! Map<String, dynamic>) continue;
      final name = (c['name'] as String?)?.trim();
      if (name == null || name.isEmpty) continue;
      final valueRaw = c['value'];
      final score = valueRaw is num ? valueRaw.toDouble().clamp(0.0, 1.0) : 0.0;
      candidates.add(
        IdentifyCandidate(
          scientificName: name,
          commonName: name,
          score: score,
        ),
      );
      if (candidates.length >= maxResults) break;
    }

    return IdentifyResult(candidates);
  }
}

