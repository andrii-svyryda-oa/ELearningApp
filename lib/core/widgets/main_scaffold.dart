import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_animate/flutter_animate.dart';

class MainScaffold extends StatefulWidget {
  final Widget child;

  const MainScaffold({
    super.key,
    required this.child,
  });

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
          
          switch (index) {
            case 0:
              context.go('/courses');
              break;
            case 1:
              context.go('/tests');
              break;
            case 2:
              context.go('/profile');
              break;
          }
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.book),
            label: l10n.courses,
          ),
          NavigationDestination(
            icon: const Icon(Icons.quiz),
            label: l10n.tests,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person),
            label: l10n.profile,
          ),
        ],
      ).animate().slideY(begin: 1, end: 0, duration: 300.ms),
    );
  }
}
