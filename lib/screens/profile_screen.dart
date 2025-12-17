import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../styles.dart';
import 'face_register_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: softBackground,
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            Card(
              shape: defaultCardShape,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundImage: const NetworkImage('https://images.unsplash.com/photo-1544723795-3fb6469f5b39?auto=format&fit=crop&w=200&q=80'),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (ApiService.instance.currentUser?['name'] as String?) ?? 'User',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            (ApiService.instance.currentUser?['email'] as String?) ?? 'email belum di-set',
                            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              _Tag(text: 'ID: ${ApiService.instance.currentUser?['id'] ?? '-'}'),
                              _Tag(text: ApiService.instance.token != null ? 'Token tersimpan' : 'Token kosong'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.edit_note_rounded, color: accentPurple),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              shape: defaultCardShape,
              child: Column(
                children: [
                  const _ProfileTile(title: 'Personal Data', subtitle: 'Email, phone, address'),
                  ListTile(
                    leading: Container(
                      height: 42,
                      width: 42,
                      decoration: BoxDecoration(color: accentPurple.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.face_retouching_natural_rounded, size: 20, color: accentPurple),
                    ),
                    title: Text('Register Face', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    subtitle: Text('Ambil foto wajah untuk absensi', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade700)),
                    trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const FaceRegisterScreen()),
                      );
                    },
                  ),
                  const _ProfileTile(title: 'Attendance & Leave', subtitle: 'Quota, approvals'),
                  const _ProfileTile(title: 'Security', subtitle: 'Change password, PIN'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Card(
              shape: defaultCardShape,
              child: Column(
                children: const [
                  _ProfileTile(title: 'Notifications', subtitle: 'Push and email alerts'),
                  _ProfileTile(title: 'Language', subtitle: 'English'),
                  _ProfileTile(title: 'About', subtitle: 'Version 1.0.0'),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                },
                child: const Text('Logout'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Container(
        height: 42,
        width: 42,
        decoration: BoxDecoration(
          color: accentPurple.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.circle, size: 14, color: accentPurple),
      ),
      title: Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade700)),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
      onTap: () {},
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accentPurple.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text, style: const TextStyle(color: accentPurple, fontWeight: FontWeight.w700)),
    );
  }
}
