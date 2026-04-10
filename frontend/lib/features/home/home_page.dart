import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../history/project_store.dart';
import '../profile/profile_store.dart';

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.profile,
    required this.onStartNewProject,
    required this.onOpenHistory,
    required this.onOpenProfile,
  });

  final UserProfile profile;
  final VoidCallback onStartNewProject;
  final VoidCallback onOpenHistory;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prelaje'),
        actions: [
          IconButton(
            onPressed: onOpenProfile,
            icon: const Icon(Icons.person_outline),
          ),
        ],
      ),
      body: FutureBuilder<List<ProjectRecord>>(
        future: ProjectStore.loadAll(),
        builder: (context, snapshot) {
          final projects = snapshot.data ?? const [];
          final recent = projects.take(3).toList();
          final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _HeroCard(
                profile: profile,
                onStartNewProject: onStartNewProject,
                onOpenHistory: onOpenHistory,
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Text('Resumo rapido', style: Theme.of(context).textTheme.titleLarge),
                  const Spacer(),
                  TextButton(
                    onPressed: onOpenHistory,
                    child: const Text('Ver historico'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Projetos',
                      value: projects.length.toString(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Atalho do dia',
                      value: 'Nova laje',
                      accent: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text('Recentes', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              if (recent.isEmpty)
                _EmptyState(onStartNewProject: onStartNewProject)
              else
                ...recent.map(
                  (project) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(project.name,
                                    style: Theme.of(context).textTheme.titleMedium),
                                const SizedBox(height: 4),
                                Text(
                                  '${project.usageLabel} | ${project.vigotaLabel}',
                                ),
                              ],
                            ),
                          ),
                          Text(
                            currency.format(project.estimatedMax),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.profile,
    required this.onStartNewProject,
    required this.onOpenHistory,
  });

  final UserProfile profile;
  final VoidCallback onStartNewProject;
  final VoidCallback onOpenHistory;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3E5D49), Color(0xFFC77C52)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Oi, ${profile.name.split(' ').first}',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vamos fechar uma laje sem depender de servidor.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton(
                onPressed: onStartNewProject,
                style: FilledButton.styleFrom(backgroundColor: Colors.white),
                child: const Text('Nova laje'),
              ),
              OutlinedButton(
                onPressed: onOpenHistory,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                ),
                child: const Text('Histórico'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    this.accent = false,
  });

  final String label;
  final String value;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent ? const Color(0xFFFCF0E8) : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onStartNewProject});

  final VoidCallback onStartNewProject;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Sem projetos ainda.'),
          const SizedBox(height: 8),
          const Text('Toque em Nova laje e comece com o que ja sabe da obra.'),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: onStartNewProject,
            child: const Text('Criar primeiro projeto'),
          ),
        ],
      ),
    );
  }
}
