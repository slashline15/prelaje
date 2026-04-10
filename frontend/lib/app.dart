import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/history/history_page.dart';
import 'features/history/project_store.dart';
import 'features/home/home_page.dart';
import 'features/profile/profile_page.dart';
import 'features/profile/profile_store.dart';
import 'features/wizard/wizard_page.dart';

class PrelajeApp extends StatelessWidget {
  const PrelajeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Prelaje',
      theme: AppTheme.light(),
      home: const _BootstrapGate(),
    );
  }
}

class _BootstrapGate extends StatefulWidget {
  const _BootstrapGate();

  @override
  State<_BootstrapGate> createState() => _BootstrapGateState();
}

class _BootstrapGateState extends State<_BootstrapGate> {
  late Future<UserProfile?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = ProfileStore.load();
  }

  Future<void> _refresh() async {
    setState(() {
      _profileFuture = ProfileStore.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserProfile?>(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _SplashScreen();
        }

        final profile = snapshot.data;
        if (profile == null) {
          return ProfilePage(
            onboardingMode: true,
            onSaved: _refresh,
          );
        }

        return PrelajeShell(
          profile: profile,
          onProfileChanged: _refresh,
        );
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF7F1E8), Color(0xFFE6DDCF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Carregando o canteiro...'),
            ],
          ),
        ),
      ),
    );
  }
}

class PrelajeShell extends StatefulWidget {
  const PrelajeShell({
    super.key,
    required this.profile,
    required this.onProfileChanged,
  });

  final UserProfile profile;
  final VoidCallback onProfileChanged;

  @override
  State<PrelajeShell> createState() => _PrelajeShellState();
}

class _PrelajeShellState extends State<PrelajeShell> {
  int _index = 0;

  void _goToWizard() => setState(() => _index = 1);
  void _goToHistory() => setState(() => _index = 2);
  void _goToProfile() => setState(() => _index = 3);
  void _goToHome() => setState(() => _index = 0);

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomePage(
        profile: widget.profile,
        onStartNewProject: _goToWizard,
        onOpenHistory: _goToHistory,
        onOpenProfile: _goToProfile,
      ),
      WizardPage(
        profile: widget.profile,
        onProjectSaved: () {
          _goToHistory();
          setState(() {});
        },
      ),
      HistoryPage(
        profile: widget.profile,
        onStartNewProject: _goToWizard,
      ),
      ProfilePage(
        onboardingMode: false,
        onSaved: () {
          widget.onProfileChanged();
          _goToHome();
        },
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) {
          setState(() => _index = value);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.design_services_outlined),
            selectedIcon: Icon(Icons.design_services),
            label: 'Orçar',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Histórico',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
      floatingActionButton: _index == 0
          ? FloatingActionButton.extended(
              onPressed: _goToWizard,
              icon: const Icon(Icons.add),
              label: const Text('Nova laje'),
            )
          : null,
    );
  }
}
