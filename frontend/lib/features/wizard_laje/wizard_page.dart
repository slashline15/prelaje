import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../data/models/carga_uso_referencia_dto.dart';
import '../../data/models/revestimento_referencia_dto.dart';
import '../../data/models/vigota_referencia_dto.dart';
import '../../data/repositories/dimensionamento_repository.dart';
import '../profile/profile_store.dart';
import '../resultado/resultado_page.dart';
import 'wizard_controller.dart';

class WizardLajePage extends StatelessWidget {
  const WizardLajePage({
    super.key,
    required this.profile,
    required this.onProjectSaved,
  });

  final UserProfile profile;
  final VoidCallback onProjectSaved;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => WizardController(
        repository: context.read<DimensionamentoRepository>(),
      )..loadReferencias(),
      child: _WizardContent(
        profile: profile,
        onProjectSaved: onProjectSaved,
      ),
    );
  }
}

class _WizardContent extends StatefulWidget {
  const _WizardContent({
    required this.profile,
    required this.onProjectSaved,
  });

  final UserProfile profile;
  final VoidCallback onProjectSaved;

  @override
  State<_WizardContent> createState() => _WizardContentState();
}

class _WizardContentState extends State<_WizardContent> {
  final _pageController = PageController();
  final _vaoController = TextEditingController(text: '4.00');
  final _larguraController = TextEditingController(text: '4.00');
  final _capaController = TextEditingController(text: '2.5');
  int _step = 0;

  @override
  void dispose() {
    _pageController.dispose();
    _vaoController.dispose();
    _larguraController.dispose();
    _capaController.dispose();
    super.dispose();
  }

  void _goTo(int step) {
    setState(() => _step = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  void _next() {
    if (_step < 3) _goTo(_step + 1);
  }

  void _prev() {
    if (_step > 0) _goTo(_step - 1);
  }

  Future<void> _calcular(WizardController controller) async {
    final error = await controller.calcular();

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    final resultado = controller.resultado!;
    final dados = controller.selections.toDadosLaje();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResultadoPage(
          resultado: resultado,
          dados: dados,
          profile: widget.profile,
        ),
      ),
    );

    widget.onProjectSaved();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<WizardController>();
    final catalogo = controller.selections.modo == 'catalogo';

    // Estado: carregando referências
    if (controller.state == WizardLoadState.loadingRefs) {
      return Scaffold(
        appBar: AppBar(title: const Text('Nova laje')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Estado: erro ao carregar referências
    if (controller.state == WizardLoadState.error &&
        !controller.isRefsLoaded) {
      return Scaffold(
        appBar: AppBar(title: const Text('Nova laje')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off, size: 48, color: Colors.orange),
                const SizedBox(height: 16),
                Text(
                  controller.errorMessage ?? 'Erro ao conectar ao servidor.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: controller.loadReferencias,
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Nova laje')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            children: [
              _StepHeader(step: _step),
              const SizedBox(height: 16),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _DimensionStep(
                      vaoController: _vaoController,
                      larguraController: _larguraController,
                      capaController: _capaController,
                      modo: controller.selections.modo,
                      vigotaRecomendada: controller.vigotaRecomendada,
                      hCapaAutomatica: controller.hCapaRecomendada,
                      onModoChanged: controller.setModo,
                      onVaoChanged: (v) {
                        final parsed = double.tryParse(v.replaceAll(',', '.'));
                        if (parsed != null) controller.updateVao(parsed);
                      },
                      onLarguraChanged: (v) {
                        final parsed = double.tryParse(v.replaceAll(',', '.'));
                        if (parsed != null) controller.updateLargura(parsed);
                      },
                      onCapaChanged: (v) {
                        final parsed = double.tryParse(v.replaceAll(',', '.'));
                        if (parsed != null) controller.updateHCapa(parsed / 100.0);
                      },
                    ),
                    _UsoStep(
                      usos: controller.usos,
                      selected: controller.selections.uso,
                      onSelected: controller.selectUso,
                    ),
                    _RevestimentoStep(
                      revestimentos: controller.revestimentos,
                      selected: controller.selections.revestimento,
                      onSelected: controller.selectRevestimento,
                    ),
                    catalogo
                        ? _CatalogoVigotaStep(
                            recomendado: controller.vigotaRecomendada,
                            vao: controller.selections.vao,
                          )
                        : _VigotaStep(
                            vigotas: controller.vigotas,
                            selected: controller.selections.vigota,
                            modo: controller.selections.modo,
                            recomendada: controller.vigotaRecomendada,
                            onSelected: controller.selectVigota,
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Row(
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
                      onPressed: controller.isCalculating
                          ? null
                          : () => _calcular(controller),
                      child: controller.isCalculating
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Calcular'),
                    )
                  : FilledButton(
                      onPressed: _next,
                      child: const Text('Continuar'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Barra de progresso dos passos
// ---------------------------------------------------------------------------

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.35)),
      ),
      child: Row(
        children: List.generate(4, (index) {
          final active = index <= step;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: EdgeInsets.only(right: index == 3 ? 0 : 8),
              height: 8,
              decoration: BoxDecoration(
                color: active
                    ? const Color(0xFF3E5D49)
                    : const Color(0xFFE4DED3),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Passo 1 — Dimensões
// ---------------------------------------------------------------------------

class _DimensionStep extends StatelessWidget {
  const _DimensionStep({
    required this.vaoController,
    required this.larguraController,
    required this.capaController,
    required this.modo,
    required this.vigotaRecomendada,
    required this.hCapaAutomatica,
    required this.onModoChanged,
    required this.onVaoChanged,
    required this.onLarguraChanged,
    required this.onCapaChanged,
  });

  final TextEditingController vaoController;
  final TextEditingController larguraController;
  final TextEditingController capaController;
  final String modo;
  final VigotaReferenciaDto? vigotaRecomendada;
  final double hCapaAutomatica;
  final ValueChanged<String> onModoChanged;
  final ValueChanged<String> onVaoChanged;
  final ValueChanged<String> onLarguraChanged;
  final ValueChanged<String> onCapaChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Dimensões', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 6),
        const Text('Informe o que a obra já sabe. O catálogo cuida do resto.'),
        const SizedBox(height: 20),
        Text('Modo de cálculo', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ChoiceChip(
              avatar: const Icon(Icons.analytics_outlined, size: 18),
              label: const Text('Analítico'),
              selected: modo == 'analitico',
              onSelected: (_) => onModoChanged('analitico'),
            ),
            ChoiceChip(
              avatar: const Icon(Icons.view_timeline_outlined, size: 18),
              label: const Text('Catálogo'),
              selected: modo == 'catalogo',
              onSelected: (_) => onModoChanged('catalogo'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: vaoController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
          decoration: const InputDecoration(
            labelText: 'Vão (m)',
            hintText: 'Ex.: 4.20',
            helperText: 'Máximo: 10 m',
          ),
          onChanged: onVaoChanged,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: larguraController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
          decoration: const InputDecoration(
            labelText: 'Largura total (m)',
            hintText: 'Ex.: 4.00',
          ),
          onChanged: onLarguraChanged,
        ),
        const SizedBox(height: 16),
        if (modo == 'analitico') ...[
          TextFormField(
            controller: capaController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
            decoration: const InputDecoration(
              labelText: 'Capa (cm)',
              hintText: 'Ex.: 2.5',
              helperText: 'Mínimo normativo: 2.5 cm',
            ),
            onChanged: onCapaChanged,
          ),
          const SizedBox(height: 16),
        ] else ...[
          _CatalogoResumoCard(
            vigota: vigotaRecomendada,
            hCapaCm: hCapaAutomatica * 100.0,
          ),
          const SizedBox(height: 16),
        ],
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: scheme.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.primary.withOpacity(0.18)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 18, color: scheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  modo == 'catalogo'
                      ? 'No catálogo, a vigota e a capa são escolhidas automaticamente.'
                      : 'No modo analítico você pode ajustar a capa manualmente antes do cálculo.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _PanosPreview(
          vao: double.tryParse(vaoController.text.replaceAll(',', '.')) ?? 4.0,
          largura:
              double.tryParse(larguraController.text.replaceAll(',', '.')) ?? 4.0,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Passo 2 — Uso
// ---------------------------------------------------------------------------

class _UsoStep extends StatefulWidget {
  const _UsoStep({
    required this.usos,
    required this.selected,
    required this.onSelected,
  });

  final List<CargaUsoReferenciaDto> usos;
  final CargaUsoReferenciaDto? selected;
  final ValueChanged<CargaUsoReferenciaDto> onSelected;

  @override
  State<_UsoStep> createState() => _UsoStepState();
}

class _UsoStepState extends State<_UsoStep> {
  String? _expandedCarga;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final groups = <double, List<CargaUsoReferenciaDto>>{};
    for (final uso in widget.usos) {
      groups.putIfAbsent(uso.cargaKnM2, () => []).add(uso);
    }
    final sortedLoads = groups.keys.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Uso da laje', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 6),
        const Text('Escolha o uso pela carga. Os detalhes ficam agrupados.'),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.separated(
            itemCount: sortedLoads.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, index) {
              final carga = sortedLoads[index];
              final itens = groups[carga] ?? const [];
              final headerUsage = itens.isNotEmpty ? itens.first : null;
              final key = carga.toStringAsFixed(1);
              final expanded =
                  _expandedCarga == key || itens.any((uso) => widget.selected?.uso == uso.uso);
              final preview = expanded ? itens : itens.take(3).toList();
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: scheme.outlineVariant.withOpacity(0.35)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _iconForUsoCategoria(headerUsage?.usoCategoria ?? ''),
                          color: scheme.primary,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${carga.toStringAsFixed(1)} kN/m²',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _expandedCarga = expanded ? null : key;
                            });
                          },
                          icon: Icon(
                            expanded ? Icons.expand_less : Icons.expand_more,
                            size: 18,
                          ),
                          label: Text(expanded ? 'Menos' : 'Mais'),
                        ),
                        const Spacer(),
                        if (itens.length > preview.length)
                          Chip(
                            avatar: const Icon(Icons.more_horiz, size: 18),
                            label: Text('+ ${itens.length - preview.length}'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: preview.map((uso) {
                        final isSelected = widget.selected?.uso == uso.uso;
                        return FilterChip(
                          avatar: Icon(
                            _iconForUsoCategoria(uso.usoCategoria),
                            size: 18,
                          ),
                          label: Text(uso.labelWizard),
                          selected: isSelected,
                          onSelected: (_) => widget.onSelected(uso),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Passo 3 — Vigota
// ---------------------------------------------------------------------------

class _VigotaStep extends StatelessWidget {
  const _VigotaStep({
    required this.vigotas,
    required this.selected,
    required this.modo,
    required this.recomendada,
    required this.onSelected,
  });

  final List<VigotaReferenciaDto> vigotas;
  final VigotaReferenciaDto? selected;
  final String modo;
  final VigotaReferenciaDto? recomendada;
  final ValueChanged<VigotaReferenciaDto> onSelected;

  @override
  Widget build(BuildContext context) {
    if (modo == 'catalogo') {
      return _CatalogoVigotaStep(
        recomendado: recomendada,
        vao: recomendada?.vaoMaxM ?? 0,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Vigota', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 6),
        const Text('Escolha a espessura que mais se adequa à obra.'),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.separated(
            itemCount: vigotas.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, index) {
              final vigota = vigotas[index];
              final isSelected = selected?.codigo == vigota.codigo;
              // O intereixo é fixo por modelo — exibido como info, não como input.
              return _OptionCard(
                title: vigota.labelWizard,
                subtitle:
                    'Vão máximo: ${vigota.vaoMaxM.toStringAsFixed(1)} m  •  '
                    'Capa mín: ${vigota.capaMinCm.toStringAsFixed(0)} cm',
                isSelected: isSelected,
                onTap: () => onSelected(vigota),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Passo 4 — Acabamento / Revestimento
// ---------------------------------------------------------------------------

class _RevestimentoStep extends StatelessWidget {
  const _RevestimentoStep({
    required this.revestimentos,
    required this.selected,
    required this.onSelected,
  });

  final List<RevestimentoReferenciaDto> revestimentos;
  final RevestimentoReferenciaDto? selected;
  final ValueChanged<RevestimentoReferenciaDto> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Acabamento', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 6),
        const Text('Qual o revestimento previsto para a laje?'),
        const SizedBox(height: 16),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.1,
            ),
            itemCount: revestimentos.length,
            itemBuilder: (_, index) {
              final rev = revestimentos[index];
              final isSelected = selected?.id == rev.id;
              return InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => onSelected(rev),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isSelected ? scheme.primary.withOpacity(0.12) : scheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? scheme.primary
                          : scheme.outlineVariant.withOpacity(0.35),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(
                        _iconForRevestimento(rev.descricao),
                        color: isSelected ? scheme.primary : scheme.onSurfaceVariant,
                        size: 28,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rev.descricao,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${rev.gRevKnM2.toStringAsFixed(2)} kN/m²',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CatalogoVigotaStep extends StatelessWidget {
  const _CatalogoVigotaStep({
    required this.recomendado,
    required this.vao,
  });

  final VigotaReferenciaDto? recomendado;
  final double vao;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Vigota recomendada', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 6),
        const Text('No modo catálogo a vigota é sugerida automaticamente.'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: scheme.outlineVariant.withOpacity(0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_mode, color: scheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      recomendado?.labelWizard ?? 'Nenhuma vigota compatível',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                recomendado == null
                    ? 'Revise o vão informado para liberar a recomendação.'
                    : 'Recomendação automática para vão de ${vao.toStringAsFixed(2)} m. A escolha detalhada fica para o modo analítico.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CatalogoResumoCard extends StatelessWidget {
  const _CatalogoResumoCard({
    required this.vigota,
    required this.hCapaCm,
  });

  final VigotaReferenciaDto? vigota;
  final double hCapaCm;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.primary.withOpacity(0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.primary.withOpacity(0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: scheme.primary.withOpacity(0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.auto_mode, color: scheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recomendação automática',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  vigota == null
                      ? 'A vigota será sugerida assim que houver referências.'
                      : '${vigota!.labelWizard}  •  capa ${hCapaCm.toStringAsFixed(1)} cm',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Card de opção genérico (sem icon — vigotas e revestimentos não têm ícone canônico)
// ---------------------------------------------------------------------------

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? scheme.primary.withOpacity(0.12) : scheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? scheme.primary
                : scheme.outlineVariant.withOpacity(0.35),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            Radio<bool>(
              value: true,
              groupValue: isSelected,
              onChanged: (_) => onTap(),
            ),
          ],
        ),
      ),
    );
  }
}

class _PanosPreview extends StatelessWidget {
  const _PanosPreview({
    required this.vao,
    required this.largura,
  });

  final double vao;
  final double largura;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final area = vao * largura;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.view_agenda_outlined, color: scheme.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Panos do projeto',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Base preparada para L1, L2 e mais panos no futuro. Hoje o app calcula o pano principal.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text('L1: ${vao.toStringAsFixed(2)} x ${largura.toStringAsFixed(2)} m')),
              Chip(label: Text('Área: ${area.toStringAsFixed(2)} m²')),
              ActionChip(
                label: const Text('Adicionar pano'),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Base visual preparada para L1/L2 e múltiplos panos.'),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

IconData _iconForUsoCategoria(String categoria) {
  switch (categoria) {
    case 'residencial':
      return Icons.bed_outlined;
    case 'comercial':
      return Icons.work_outline;
    case 'servico':
      return Icons.settings_outlined;
    case 'educacao':
      return Icons.school_outlined;
    case 'biblioteca':
      return Icons.menu_book_outlined;
    default:
      return Icons.home_outlined;
  }
}

IconData _iconForRevestimento(String descricao) {
  final lower = descricao.toLowerCase();
  if (lower.contains('ceram')) return Icons.grid_view_outlined;
  if (lower.contains('piso')) return Icons.texture_outlined;
  if (lower.contains('massa')) return Icons.layers_outlined;
  if (lower.contains('gesso')) return Icons.drag_indicator;
  return Icons.layers_outlined;
}
