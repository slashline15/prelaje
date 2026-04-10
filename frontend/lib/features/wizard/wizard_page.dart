import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../history/project_store.dart';
import '../profile/profile_store.dart';
import 'wizard_catalog.dart';

class WizardPage extends StatefulWidget {
  const WizardPage({
    super.key,
    required this.profile,
    required this.onProjectSaved,
  });

  final UserProfile profile;
  final VoidCallback onProjectSaved;

  @override
  State<WizardPage> createState() => _WizardPageState();
}

class _WizardPageState extends State<WizardPage> {
  final _controller = PageController();
  final _vao = TextEditingController(text: '4.00');
  final _largura = TextEditingController(text: '4.00');
  int _step = 0;
  WizardUseOption _usage = wizardUses.first;
  WizardVigotaOption _vigota = wizardVigotas[1];
  WizardFinishOption _finish = wizardFinishes[1];

  @override
  void dispose() {
    _controller.dispose();
    _vao.dispose();
    _largura.dispose();
    super.dispose();
  }

  void _next() {
    if (_step < 3) {
      setState(() => _step += 1);
      _controller.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    }
  }

  void _prev() {
    if (_step > 0) {
      setState(() => _step -= 1);
      _controller.previousPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _saveProject() async {
    final vao = double.tryParse(_vao.text.replaceAll(',', '.')) ?? 4.0;
    final largura = double.tryParse(_largura.text.replaceAll(',', '.')) ?? 4.0;
    final estimate = estimateQuote(
      vao: vao,
      largura: largura,
      usage: _usage,
      vigota: _vigota,
      finish: _finish,
    );

    final project = ProjectRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Laje ${widget.profile.displayTitle}',
      createdAt: DateTime.now(),
      areaM2: estimate.areaM2,
      estimatedMin: estimate.minTotal,
      estimatedMax: estimate.maxTotal,
      usageLabel: _usage.title,
      vigotaLabel: _vigota.title,
      finishLabel: _finish.title,
      summary: 'Custo offline: ${estimate.statusLabel}',
    );
    await ProjectStore.save(project);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Projeto salvo no histórico local.')),
    );
    widget.onProjectSaved();
  }

  @override
  Widget build(BuildContext context) {
    final estimate = estimateQuote(
      vao: double.tryParse(_vao.text.replaceAll(',', '.')) ?? 4.0,
      largura: double.tryParse(_largura.text.replaceAll(',', '.')) ?? 4.0,
      usage: _usage,
      vigota: _vigota,
      finish: _finish,
    );
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

    return Scaffold(
      appBar: AppBar(title: const Text('Nova laje')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _StepHeader(step: _step),
          const SizedBox(height: 16),
          SizedBox(
            height: 620,
            child: PageView(
              controller: _controller,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _DimensionStep(vao: _vao, largura: _largura),
                _ChoiceStep<WizardUseOption>(
                  title: 'Uso',
                  subtitle: 'Escolha a cara da obra sem termos chatos.',
                  options: wizardUses,
                  selected: _usage,
                  onSelected: (value) => setState(() => _usage = value),
                  labelBuilder: (item) => _ChoiceLabel(
                    icon: item.icon,
                    title: item.title,
                    subtitle: item.subtitle,
                  ),
                ),
                _ChoiceStep<WizardVigotaOption>(
                  title: 'Vigota',
                  subtitle: 'Escolha a espessura que mais parece a obra.',
                  options: wizardVigotas,
                  selected: _vigota,
                  onSelected: (value) => setState(() => _vigota = value),
                  labelBuilder: (item) => _ChoiceLabel(
                    icon: item.icon,
                    title: item.title,
                    subtitle: item.subtitle,
                  ),
                ),
                _ChoiceStep<WizardFinishOption>(
                  title: 'Acabamento',
                  subtitle: 'Acabamento simples, medio ou reforcado.',
                  options: wizardFinishes,
                  selected: _finish,
                  onSelected: (value) => setState(() => _finish = value),
                  labelBuilder: (item) => _ChoiceLabel(
                    icon: item.icon,
                    title: item.title,
                    subtitle: item.subtitle,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _EstimateCard(
            estimate: estimate,
            currency: currency,
            profile: widget.profile,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _step == 0 ? null : _prev,
                  child: const Text('Voltar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _step == 3
                    ? FilledButton(
                        onPressed: _saveProject,
                        child: const Text('Salvar projeto'),
                      )
                    : FilledButton(
                        onPressed: _next,
                        child: const Text('Continuar'),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: List.generate(
          4,
          (index) {
            final active = index <= step;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: EdgeInsets.only(right: index == 3 ? 0 : 8),
                height: 8,
                decoration: BoxDecoration(
                  color: active ? const Color(0xFF3E5D49) : const Color(0xFFE4DED3),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DimensionStep extends StatelessWidget {
  const _DimensionStep({
    required this.vao,
    required this.largura,
  });

  final TextEditingController vao;
  final TextEditingController largura;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Dimensoes', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 6),
        const Text('Informe o que a obra ja sabe. O resto fica para a estimativa.'),
        const SizedBox(height: 16),
        TextFormField(
          controller: vao,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Vao (m)',
            hintText: 'Ex.: 4.20',
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: largura,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Largura (m)',
            hintText: 'Ex.: 4.00',
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F1E8),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            children: [
              Icon(Icons.schema_outlined),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Dica: se o cliente so sabe dizer "laje leve" ou "reforcada", use isso para escolher a vigota e ajuste depois.',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChoiceStep<T> extends StatelessWidget {
  const _ChoiceStep({
    required this.title,
    required this.subtitle,
    required this.options,
    required this.selected,
    required this.onSelected,
    required this.labelBuilder,
  });

  final String title;
  final String subtitle;
  final List<T> options;
  final T selected;
  final ValueChanged<T> onSelected;
  final Widget Function(T item) labelBuilder;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 6),
        Text(subtitle),
        const SizedBox(height: 16),
        ...options.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () => onSelected(item),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: item == selected ? const Color(0xFFFFF4EB) : Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: item == selected
                        ? const Color(0xFFC77C52)
                        : Colors.black.withValues(alpha: 0.05),
                  ),
                ),
                child: Row(
                  children: [
                    labelBuilder(item),
                    const Spacer(),
                    Radio<T>(
                      value: item,
                      groupValue: selected,
                      onChanged: (value) {
                        if (value != null) onSelected(value);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ChoiceLabel extends StatelessWidget {
  const _ChoiceLabel({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFF1E9DE),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 2),
            SizedBox(
              width: 190,
              child: Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _EstimateCard extends StatelessWidget {
  const _EstimateCard({
    required this.estimate,
    required this.currency,
    required this.profile,
  });

  final WizardEstimate estimate;
  final NumberFormat currency;
  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Resultado rapido', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(estimate.statusLabel),
          const SizedBox(height: 12),
          Text(
            '${currency.format(estimate.minTotal)} - ${currency.format(estimate.maxTotal)}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text('~ ${currency.format(estimate.unitPrice)}/m2'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text(profile.displayTitle)),
              Chip(label: Text('${estimate.areaM2.toStringAsFixed(1)} m2')),
            ],
          ),
          const SizedBox(height: 10),
          Text('Top insumos estimados', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          ...estimate.topItems.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(child: Text(item.label)),
                  Text(currency.format(item.value)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
