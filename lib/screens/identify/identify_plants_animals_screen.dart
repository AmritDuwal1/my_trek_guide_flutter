import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tour_mobile/services/identify_service.dart';
import 'package:tour_mobile/theme/travel_theme.dart';

class IdentifyPlantsAnimalsScreen extends StatefulWidget {
  const IdentifyPlantsAnimalsScreen({super.key});

  @override
  State<IdentifyPlantsAnimalsScreen> createState() => _IdentifyPlantsAnimalsScreenState();
}

class _IdentifyPlantsAnimalsScreenState extends State<IdentifyPlantsAnimalsScreen> {
  final _picker = ImagePicker();
  final _labeler = ImageLabeler(options: ImageLabelerOptions(confidenceThreshold: 0.35));
  final _identify = IdentifyService();

  XFile? _image;
  bool _busy = false;
  String? _error;
  List<ImageLabel> _labels = const [];
  IdentifyResult? _online;
  String? _onlineError;
  IdentifyKind _kind = IdentifyKind.plant;

  @override
  void dispose() {
    _labeler.close();
    super.dispose();
  }

  Future<void> _pick(ImageSource src) async {
    setState(() {
      _error = null;
      _onlineError = null;
      _busy = true;
      _labels = const [];
      _online = null;
    });
    try {
      final file = await _picker.pickImage(source: src, maxWidth: 1600, imageQuality: 90);
      if (!mounted) return;
      if (file == null) {
        setState(() => _busy = false);
        return;
      }

      setState(() => _image = file);

      // 1) Try online exact identification first (species/common name).
      try {
        final r = await _identify.identifyFromImageFile(_kind, File(file.path));
        if (!mounted) return;
        setState(() => _online = r);
      } catch (e) {
        if (!mounted) return;
        setState(() => _onlineError = e.toString());
      }

      // 2) Fallback: on-device labeling (approximate).
      final input = InputImage.fromFilePath(file.path);
      final labels = await _labeler.processImage(input);
      if (!mounted) return;

      labels.sort((a, b) => b.confidence.compareTo(a.confidence));
      setState(() {
        _labels = labels.take(10).toList(growable: false);
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Could not identify. Try another photo.';
      });
    }
  }

  bool _looksLikePlantOrAnimal(String text) {
    final s = text.toLowerCase();
    const keys = [
      'animal',
      'mammal',
      'bird',
      'reptile',
      'amphibian',
      'fish',
      'insect',
      'butterfly',
      'bee',
      'spider',
      'cat',
      'dog',
      'cow',
      'horse',
      'goat',
      'yak',
      'deer',
      'monkey',
      'bear',
      'leopard',
      'tiger',
      'plant',
      'tree',
      'flower',
      'leaf',
      'fern',
      'herb',
      'moss',
      'bamboo',
    ];
    return keys.any(s.contains);
  }

  @override
  Widget build(BuildContext context) {
    final img = _image;
    final best = _online?.candidates.isNotEmpty == true ? _online!.candidates.first : null;
    return Scaffold(
      backgroundColor: TravelColors.canvas,
      appBar: AppBar(title: const Text('Identify plants & animals')),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Material(
              color: TravelColors.surface,
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Take or choose a photo',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: SegmentedButton<IdentifyKind>(
                            segments: const [
                              ButtonSegment(value: IdentifyKind.plant, label: Text('Plant'), icon: Icon(Icons.local_florist_rounded)),
                              ButtonSegment(value: IdentifyKind.animal, label: Text('Animal'), icon: Icon(Icons.pets_rounded)),
                            ],
                            selected: {_kind},
                            onSelectionChanged: _busy
                                ? null
                                : (s) {
                                    setState(() {
                                      _kind = s.first;
                                      _online = null;
                                      _onlineError = null;
                                      _labels = const [];
                                    });
                                  },
                            style: ButtonStyle(
                              backgroundColor: WidgetStateProperty.resolveWith(
                                (states) => states.contains(WidgetState.selected)
                                    ? TravelColors.navActive.withValues(alpha: 0.14)
                                    : Colors.transparent,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _busy ? null : () => _pick(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt_rounded),
                            label: const Text('Camera'),
                            style: FilledButton.styleFrom(backgroundColor: TravelColors.navActive),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _busy ? null : () => _pick(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library_rounded),
                            label: const Text('Gallery'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (img == null)
                      Text(
                        'Tip: keep the subject centered and well-lit.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: TravelColors.muted),
                      )
                    else
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: AspectRatio(
                          aspectRatio: 16 / 10,
                          child: Image.file(
                            File(img.path),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    if (best != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: TravelColors.navActive.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.auto_awesome_rounded, color: TravelColors.navActive),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    best.displayName(),
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    best.commonName == null ? 'Scientific: ${best.scientificName}' : best.scientificName,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: TravelColors.muted),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '${(best.score * 100).round()}%',
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: TravelColors.ink,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (best == null && _onlineError != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _onlineError!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: TravelColors.muted),
                      ),
                    ],
                    if (_busy) ...[
                      const SizedBox(height: 12),
                      const LinearProgressIndicator(color: TravelColors.navActive),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.red.shade700)),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: Material(
                color: TravelColors.surface,
                borderRadius: BorderRadius.circular(18),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Results',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: (_online?.candidates.isNotEmpty == true)
                            ? ListView.separated(
                                itemCount: _online!.candidates.length,
                                separatorBuilder: (_, __) => const Divider(height: 14),
                                itemBuilder: (context, i) {
                                  final c = _online!.candidates[i];
                                  final pct = (c.score * 100).round();
                                  return Row(
                                    children: [
                                      const Icon(Icons.biotech_rounded, color: TravelColors.navActive),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              c.displayName(),
                                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                    fontWeight: i == 0 ? FontWeight.w900 : FontWeight.w700,
                                                  ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              c.commonName == null ? c.scientificName : 'Scientific: ${c.scientificName}',
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: TravelColors.muted),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        '$pct%',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: TravelColors.muted),
                                      ),
                                    ],
                                  );
                                },
                              )
                            : _labels.isEmpty
                            ? Center(
                                child: Text(
                                  img == null ? 'Pick a photo to identify.' : 'No confident labels found.',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: TravelColors.muted),
                                ),
                              )
                            : ListView.separated(
                                itemCount: _labels.length,
                                separatorBuilder: (_, __) => const Divider(height: 14),
                                itemBuilder: (context, i) {
                                  final l = _labels[i];
                                  final pct = (l.confidence * 100).round();
                                  final highlight = _looksLikePlantOrAnimal(l.label);
                                  return Row(
                                    children: [
                                      Icon(
                                        highlight ? Icons.pets_rounded : Icons.label_rounded,
                                        color: highlight ? TravelColors.navActive : TravelColors.muted,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          l.label,
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
                                              ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        '$pct%',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: TravelColors.muted),
                                      ),
                                    ],
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        (_online?.candidates.isNotEmpty == true)
                            ? (_kind == IdentifyKind.plant)
                                ? 'Online identification uses Pl@ntNet to return plant names.'
                                : 'Online identification uses Clarifai to return animal labels.'
                            : (_onlineError != null)
                                ? 'Online ID unavailable; showing fallback labels.'
                                : 'Fallback uses on-device labeling; results may be approximate.',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: TravelColors.muted),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

