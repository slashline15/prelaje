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
  int _step = 0;

  @override
  void dispose() {
    _pageController.dispose();
    _vaoController.dispose();
    _larguraController.dispose();
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

    // Salvar no histórico após voltar da tela de resultado
    widget.onProjectSaved();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<WizardController>();

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
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _StepHeader(step: _step),
          const SizedBox(height: 16),
          SizedBox(
            height: 560,
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _DimensionStep(
                  vaoController: _vaoController,
                  larguraController: _larguraController,
                  onVaoChanged: (v) {
                    final parsed = double.tryParse(v.replaceAll(',', '.'));
                    if (parsed != null) controller.updateVao(parsed);
                  },
                  onLarguraChanged: (v) {
                    final parsed = double.tryParse(v.replaceAll(',', '.'));
                    if (parsed != null) controller.updateLargura(parsed);
                  },
                ),
                _UsoStep(
                  usos: controller.usos,
                  selected: controller.selections.uso,
                  onSelected: controller.selectUso,
                ),
                _VigotaStep(
                  vigotas: controller.vigotas,
                  selected: controller.selections.vigota,
                  onSelected: controller.selectVigota,
                ),
                _RevestimentoStep(
                  revestimentos: controller.revestimentos,
                  selected: controller.selections.revestimento,
                  onSelected: controller.selectRevestimento,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
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
        ],
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
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
    required this.onVaoChanged,
    required this.onLarguraChanged,
  });

  final TextEditingController vaoController;
  final TextEditingController larguraController;
  final ValueChanged<String> onVaoChanged;
  final ValueChanged<String> onLarguraChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Dimensões', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 6),
        const Text('Informe o que a obra já sabe. O resto fica para a estimativa.'),
        const SizedBox(height: 20),
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
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F1E8),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Dica: se o cliente só sabe dizer "laje leve" ou "reforçada", '
                  'escolha a vigota pela espessura e ajuste depois.',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Passo 2 — Uso
// ---------------------------------------------------------------------------

class _UsoStep extends StatelessWidget {
  const _UsoStep({
    required this.usos,
    required this.selected,
    required this.onSelected,
  });

  final List<CargaUsoReferenciaDto> usos;
  final CargaUsoReferenciaDto? selected;
  final ValueChanged<CargaUsoReferenciaDto> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Uso da laje', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 6),
        const Text('Como vai ser usada essa laje?'),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.separated(
            itemCount: usos.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, index) {
              final uso = usos[index];
              final isSelected = selected?.uso == uso.uso;
              return _OptionCard(
                title: uso.labelWizard,
                subtitle:
                    '${uso.cargaKnM2.toStringAsFixed(1)} kN/m² de sobrecarga',
                isSelected: isSelected,
                onTap: () => onSelected(uso),
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
    required this.onSelected,
  });

  final List<VigotaReferenciaDto> vigotas;
  final VigotaReferenciaDto? selected;
  final ValueChanged<VigotaReferenciaDto> onSelected;

  @override
  Widget build(BuildContext context) {
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Acabamento', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 6),
        const Text('Qual o revestimento previsto para a laje?'),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.separated(
            itemCount: revestimentos.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, index) {
              final rev = revestimentos[index];
              final isSelected = selected?.id == rev.id;
              return _OptionCard(
                title: rev.descricao,
                subtitle:
                    '${rev.gRevKnM2.toStringAsFixed(2)} kN/m²',
                isSelected: isSelected,
                onTap: () => onSelected(rev),
              );
            },
          ),
        ),
      ],
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
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF4EB) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFC77C52)
                : Colors.black.withValues(alpha: 0.06),
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
                          color: Colors.grey.shade600,
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
