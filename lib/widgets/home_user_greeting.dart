import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tour_mobile/profile/profile_service.dart';
import 'package:tour_mobile/profile/user_profile.dart';
import 'package:tour_mobile/profile/user_session_store.dart';
import 'package:tour_mobile/theme/travel_theme.dart';

class HomeUserDisplay {
  const HomeUserDisplay({required this.displayName, required this.photoUrl});

  final String displayName;
  final String photoUrl;

  static HomeUserDisplay fromFirebaseOnly(User user) {
    final dn = user.displayName?.trim();
    final emailLocal = user.email?.split('@').first.trim();
    final name = (dn != null && dn.isNotEmpty)
        ? dn
        : (emailLocal != null && emailLocal.isNotEmpty)
            ? emailLocal
            : 'Traveler';
    return HomeUserDisplay(displayName: name, photoUrl: user.photoURL ?? '');
  }

  static Future<HomeUserDisplay> resolve(User user) async {
    UserProfile? profile;
    try {
      profile = await ProfileService().get(user.uid);
    } catch (_) {
      profile = null;
    }
    final cached = await UserSessionStore.readForUid(user.uid);

    String name;
    if (profile != null && profile.fullName.trim().isNotEmpty) {
      name = profile.fullName.trim();
    } else if (cached != null && cached.displayName.isNotEmpty) {
      name = cached.displayName;
    } else {
      name = fromFirebaseOnly(user).displayName;
    }

    String photo;
    if (profile != null && profile.photoUrl.trim().isNotEmpty) {
      photo = profile.photoUrl.trim();
    } else if (cached != null && cached.photoUrl.isNotEmpty) {
      photo = cached.photoUrl;
    } else {
      photo = user.photoURL ?? '';
    }

    return HomeUserDisplay(displayName: name, photoUrl: photo);
  }
}

/// Header row: "Hi {name}," + avatar (dynamic from API profile, local cache, then Firebase).
class HomeUserGreeting extends StatelessWidget {
  const HomeUserGreeting({
    super.key,
    required this.notificationSlot,
  });

  /// Trailing notification bell + badge (passed from parent that owns [NotificationStore]).
  final Widget notificationSlot;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        final user = authSnap.data;
        if (user == null) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: TravelColors.ink,
                          fontWeight: FontWeight.w400,
                          fontSize: 16,
                        ),
                    children: [
                      const TextSpan(text: 'Hi '),
                      TextSpan(
                        text: 'Traveler',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: TravelColors.ink,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                      ),
                      const TextSpan(text: ','),
                    ],
                  ),
                ),
              ),
              CircleAvatar(
                radius: 24,
                backgroundColor: TravelColors.line,
                child: Icon(Icons.person_rounded, color: TravelColors.muted.withValues(alpha: 0.85)),
              ),
              const SizedBox(width: 8),
              notificationSlot,
            ],
          );
        }

        return ValueListenableBuilder<int>(
          valueListenable: UserSessionStore.revision,
          builder: (context, rev, _) {
            return FutureBuilder<HomeUserDisplay>(
              key: ValueKey<String>('${user.uid}_$rev'),
              future: HomeUserDisplay.resolve(user),
              builder: (context, futSnap) {
            final data = futSnap.connectionState == ConnectionState.done && futSnap.hasData
                ? futSnap.data!
                : HomeUserDisplay.fromFirebaseOnly(user);

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: TravelColors.ink,
                                fontWeight: FontWeight.w400,
                                fontSize: 16,
                              ),
                          children: [
                            const TextSpan(text: 'Hi '),
                            TextSpan(
                              text: data.displayName,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: TravelColors.ink,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                            ),
                            const TextSpan(text: ','),
                          ],
                        ),
                      ),
                    ),
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: TravelColors.line,
                      backgroundImage: data.photoUrl.isNotEmpty
                          ? NetworkImage(data.photoUrl)
                          : null,
                      child: data.photoUrl.isEmpty
                          ? Icon(Icons.person_rounded,
                              color: TravelColors.muted.withValues(alpha: 0.85))
                          : null,
                    ),
                    const SizedBox(width: 8),
                    notificationSlot,
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}
