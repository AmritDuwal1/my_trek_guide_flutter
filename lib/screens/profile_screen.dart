import 'package:flutter/material.dart';
import 'package:tour_mobile/auth/auth_service.dart';
import 'package:tour_mobile/profile/profile_service.dart';
import 'package:tour_mobile/profile/user_profile.dart';
import 'package:tour_mobile/screens/profile/edit_profile_screen.dart';
import 'package:tour_mobile/screens/support/help_complaints_screen.dart';
import 'package:tour_mobile/screens/support/chat_support_screen.dart';
import 'package:tour_mobile/screens/support/reviews_ratings_screen.dart';
import 'package:tour_mobile/theme/travel_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _confirmDeleteAccount(BuildContext context, AuthService auth) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete account?'),
          content: const Text(
            'This will permanently delete your account and your saved data on this device and our server. This cannot be undone.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (ok != true) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: TravelColors.navActive)),
    );
    try {
      await auth.deleteAccount();
      if (context.mounted) {
        Navigator.of(context).pop(); // progress
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account deleted.')));
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // progress
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    final profile = ProfileService();
    final user = auth.currentUser;
    return ColoredBox(
      color: TravelColors.canvas,
      child: ListView(
        padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 20, 20, 120),
        children: [
          if (user == null)
            Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: TravelColors.primary.withValues(alpha: 0.15),
                  child: const Icon(Icons.person_rounded, size: 40, color: TravelColors.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Guest traveler',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sign in to sync trips',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: TravelColors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            )
          else
            FutureBuilder<UserProfile?>(
              future: profile.get(user.uid),
              builder: (context, snapshot) {
                final p = snapshot.data;
                final name = (p?.fullName.isNotEmpty ?? false) ? p!.fullName : (user.displayName ?? 'Traveler');
                final subtitle = (p?.location.isNotEmpty ?? false) ? p!.location : (user.email ?? '');
                final photo = (p?.photoUrl.isNotEmpty ?? false) ? p!.photoUrl : (user.photoURL ?? '');
                return Row(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: TravelColors.line,
                      backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
                      child: photo.isEmpty ? const Icon(Icons.person_rounded, size: 40, color: TravelColors.muted) : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: TravelColors.muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          const SizedBox(height: 28),
          if (user != null)
            _ProfileRow(
              icon: Icons.edit_rounded,
              label: 'Edit profile',
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const EditProfileScreen()));
              },
            ),
          // _ProfileRow(icon: Icons.bookmark_outline_rounded, label: 'Saved places'),
          // _ProfileRow(icon: Icons.settings_outlined, label: 'Settings'),
          _ProfileRow(
            icon: Icons.support_agent_rounded,
            label: 'Help & Complaints',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const HelpComplaintsScreen()),
              );
            },
          ),
          _ProfileRow(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Chat support',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const ChatSupportScreen()),
              );
            },
          ),
          _ProfileRow(
            icon: Icons.star_rate_rounded,
            label: 'Reviews & Ratings',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const ReviewsRatingsScreen()),
              );
            },
          ),
          const SizedBox(height: 6),
          _ProfileRow(
            icon: Icons.logout_rounded,
            label: 'Logout',
            onTap: () async => auth.signOut(),
          ),
          if (user != null) ...[
            const SizedBox(height: 6),
            _ProfileRow(
              icon: Icons.delete_forever_rounded,
              label: 'Delete account',
              onTap: () => _confirmDeleteAccount(context, auth),
              danger: true,
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.icon, required this.label, this.onTap, this.danger = false});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: TravelColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          leading: Icon(icon, color: danger ? Colors.red.shade700 : TravelColors.primary),
          title: Text(
            label,
            style: TextStyle(fontWeight: FontWeight.w600, color: danger ? Colors.red.shade700 : null),
          ),
          trailing: const Icon(Icons.chevron_right_rounded, color: TravelColors.muted),
          onTap: onTap ?? () {},
        ),
      ),
    );
  }
}
