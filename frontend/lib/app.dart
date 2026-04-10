import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'data/repositories/dimensionamento_repository.dart';
import 'features/history/history_page.dart';
import 'features/history/project_store.dart';
import 'features/home/home_page.dart';
import 'features/profile/profile_page.dart';
import 'features/profile/profile_store.dart';
import 'features/wizard_laje/wizard_page.dart';

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
  BackendStatus _backendStatus = BackendStatus.unknown;

  @override
  void initState() {
    super.initState();
    _profileFuture = ProfileStore.load();
    // Verifica conectividade antes do primeiro frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBackendHealth();
    });
  }

  Future<void> _checkBackendHealth() async {
    final repo = context.read<DimensionamentoRepository>();
    final status = await repo.checkHealth();
    if (mounted) {
      setState(() {
        _backendStatus = status;
      });
    }
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
          backendStatus: _backendStatus,
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
    this.backendStatus = BackendStatus.unknown,
  });

  final UserProfile profile;
  final VoidCallback onProfileChanged;
  final BackendStatus backendStatus;

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
      WizardLajePage(
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
      body: Column(
        children: [
          if (widget.backendStatus == BackendStatus.offline)
            _OfflineBanner(),
          Expanded(
            child: IndexedStack(index: _index, children: pages),
          ),
        ],
      ),
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

/// Banner discreto exibido quando o backend está offline.
class _OfflineBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.orange.shade100,
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Modo offline — cálculos rápidos disponíveis localmente'),
              duration: Duration(seconds: 3),
            ),
          );
        },
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.cloud_off, size: 18, color: Colors.orange),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Modo offline — cálculos rápidos',
                  style: TextStyle(fontSize: 13),
                ),
              ),
              Icon(Icons.chevron_right, size: 18, color: Colors.orange),
            ],
          ),
        ),
      ),
    );
  }
}
