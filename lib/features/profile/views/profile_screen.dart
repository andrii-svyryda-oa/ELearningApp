import 'package:cached_network_image/cached_network_image.dart';
import 'package:e_learning_app/core/theme/theme_provider.dart';
import 'package:e_learning_app/core/utils/locale_provider.dart';
import 'package:e_learning_app/features/auth/controllers/auth_controller.dart';
import 'package:e_learning_app/features/profile/controllers/profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isLoading = false;
  Map<String, dynamic> _userStats = {
    'completedCourses': 0,
    'inProgressCourses': 0,
    'completedTests': 0,
    'averageScore': 0.0,
  };

  @override
  void initState() {
    super.initState();
    _loadUserStats();
  }

  Future<void> _loadUserStats() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final stats = await ref.read(profileControllerProvider).getUserStats();
      setState(() {
        _userStats = stats;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading stats: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await ref.read(authControllerProvider.notifier).signOut();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final userAsync = ref.watch(authControllerProvider);
    final themeMode = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profile)),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(l10n.notLoggedIn),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to login screen
                    },
                    child: Text(l10n.loginButton),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadUserStats,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                            backgroundImage:
                                user.photoUrl != null
                                    ? CachedNetworkImageProvider(user.photoUrl!)
                                    : null,
                            child:
                                user.photoUrl == null
                                    ? Text(
                                      user.displayName?.isNotEmpty == true
                                          ? user.displayName![0].toUpperCase()
                                          : user.email[0].toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 40,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                    : null,
                          ).animate().scale(duration: 400.ms),
                          const SizedBox(height: 16),
                          Text(
                            user.displayName ?? user.email,
                            style: Theme.of(context).textTheme.titleLarge,
                          ).animate().fadeIn(delay: 200.ms),
                          const SizedBox(height: 4),
                          Text(
                            user.email,
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                          ).animate().fadeIn(delay: 300.ms),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              // Navigate to edit profile screen
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Theme.of(context).colorScheme.primary,
                              elevation: 0,
                              side: BorderSide(color: Theme.of(context).colorScheme.primary),
                            ),
                            child: Text(l10n.editProfile),
                          ).animate().fadeIn(delay: 400.ms),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      l10n.statistics,
                      style: Theme.of(context).textTheme.titleLarge,
                    ).animate().fadeIn(delay: 500.ms),
                    const SizedBox(height: 16),
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _buildStatsGrid(),
                    const SizedBox(height: 32),
                    Text(
                      l10n.settings,
                      style: Theme.of(context).textTheme.titleLarge,
                    ).animate().fadeIn(delay: 700.ms),
                    const SizedBox(height: 16),
                    _buildSettingsSection(l10n, themeMode, locale),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _signOut,
                        icon: const Icon(Icons.logout),
                        label: Text(l10n.logout),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ).animate().fadeIn(delay: 900.ms),
                  ],
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Error: ${error.toString()}')),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _buildStatCard(
          Icons.book,
          _userStats['completedCourses'].toString(),
          AppLocalizations.of(context)!.completedCourses,
          Colors.green,
          0,
        ),
        _buildStatCard(
          Icons.play_circle,
          _userStats['inProgressCourses'].toString(),
          AppLocalizations.of(context)!.inProgressCourses,
          Colors.blue,
          1,
        ),
        _buildStatCard(
          Icons.assignment,
          _userStats['completedTests'].toString(),
          AppLocalizations.of(context)!.completedTests,
          Colors.purple,
          2,
        ),
        _buildStatCard(
          Icons.score,
          '${_userStats['averageScore'].toStringAsFixed(1)}%',
          AppLocalizations.of(context)!.averageScore,
          Colors.orange,
          3,
        ),
      ],
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label, Color color, int index) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 600 + (index * 100)));
  }

  Widget _buildSettingsSection(AppLocalizations l10n, ThemeMode themeMode, Locale locale) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              title: Text(l10n.theme),
              trailing: DropdownButton<ThemeMode>(
                value: themeMode,
                onChanged: (ThemeMode? newValue) {
                  if (newValue != null) {
                    ref.read(themeProvider.notifier).setTheme(newValue);
                  }
                },
                items: [
                  DropdownMenuItem(value: ThemeMode.system, child: Text(l10n.systemTheme)),
                  DropdownMenuItem(value: ThemeMode.light, child: Text(l10n.lightTheme)),
                  DropdownMenuItem(value: ThemeMode.dark, child: Text(l10n.darkTheme)),
                ],
              ),
            ),
            const Divider(),
            ListTile(
              title: Text(l10n.language),
              trailing: DropdownButton<Locale>(
                value: locale,
                onChanged: (Locale? newValue) {
                  if (newValue != null) {
                    ref.read(localeProvider.notifier).setLocale(newValue);
                  }
                },
                items: const [
                  DropdownMenuItem(value: Locale('en'), child: Text('English')),
                  DropdownMenuItem(value: Locale('uk'), child: Text('Українська')),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 800.ms);
  }
}
