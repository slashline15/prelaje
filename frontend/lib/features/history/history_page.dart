import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'project_store.dart';
import '../profile/profile_store.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({
    super.key,
    required this.profile,
    required this.onStartNewProject,
  });

  final UserProfile profile;
  final VoidCallback onStartNewProject;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historico')),
      body: FutureBuilder<List<ProjectRecord>>(
        future: ProjectStore.loadAll(),
        builder: (context, snapshot) {
          final projects = snapshot.data ?? const [];

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _SummaryCard(profile: profile, projectCount: projects.length),
              const SizedBox(height: 18),
              Row(
                children: [
                  Text('Projetos recentes', style: Theme.of(context).textTheme.titleLarge),
                  const Spacer(),
                  TextButton(
                    onPressed: onStartNewProject,
                    child: const Text('Nova laje'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (projects.isEmpty)
                _EmptyHistory(onStartNewProject: onStartNewProject)
              else
                ...projects.map((project) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ProjectTile(project: project),
                    )),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.profile,
    required this.projectCount,
  });

  final UserProfile profile;
  final int projectCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3E5D49), Color(0xFF6E8A64)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            profile.displayTitle,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Você tem $projectCount projeto(s) salvo(s) neste aparelho.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
          ),
        ],
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({required this.onStartNewProject});

  final VoidCallback onStartNewProject;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nada por aqui ainda', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text('Assim que você salvar uma laje, ela aparece aqui com o custo resumido.'),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onStartNewProject,
            child: const Text('Fazer primeira laje'),
          ),
        ],
      ),
    );
  }
}

class _ProjectTile extends StatelessWidget {
  const _ProjectTile({required this.project});

  final ProjectRecord project;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final date = DateFormat('dd/MM/yyyy').format(project.createdAt);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  project.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Text(date, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 8),
          Text(project.summary),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Tag(label: '${project.areaM2.toStringAsFixed(1)} m2'),
              _Tag(label: project.usageLabel),
              _Tag(label: project.vigotaLabel),
              _Tag(label: project.finishLabel),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${currency.format(project.estimatedMin)} - ${currency.format(project.estimatedMax)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );
  }
}
