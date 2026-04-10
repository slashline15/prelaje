import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../data/models/dados_laje_dto.dart';
import '../../data/models/mensagem_sistema_dto.dart';
import '../../data/models/resultado_dimensionamento_dto.dart';
import '../../data/repositories/dimensionamento_repository.dart';
import '../profile/profile_store.dart';
import 'resultado_controller.dart';

class ResultadoPage extends StatefulWidget {
  const ResultadoPage({
    super.key,
    required this.resultado,
    required this.dados,
    required this.profile,
  });

  final ResultadoDimensionamentoDto resultado;
  final DadosLajeDto dados;
  final UserProfile profile;

  @override
  State<ResultadoPage> createState() => _ResultadoPageState();
}

class _ResultadoPageState extends State<ResultadoPage> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ResultadoController(
        repository: context.read<DimensionamentoRepository>(),
        resultado: widget.resultado,
        dados: widget.dados,
      ),
      child: _ResultadoPageContent(
        profile: widget.profile,
      ),
    );
  }
}

class _ResultadoPageContent extends StatelessWidget {
  const _ResultadoPageContent({
    required this.profile,
  });

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ResultadoController>();
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultado'),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 1. Status Banner
          _StatusBanner(controller: controller),
          const SizedBox(height: 20),

          // 2. Card "Estimativa de Custo"
          if (controller.totalOrcamento != null)
            _CostEstimateCard(
              controller: controller,
              currency: currency,
            ),
          const SizedBox(height: 20),

          // 3. Card "Quantitativos"
          _QuantitativosCard(
            resultado: controller.resultado,
          ),
          const SizedBox(height: 20),

          // 4. Card "Verificações" (só se houver ELU)
          if (controller.resultado.elu != null)
            _VerificacoesCard(resultado: controller.resultado),
          const SizedBox(height: 20),

          // 5. Alertas
          if (controller.resultado.alertas.isNotEmpty)
            _AlertasCard(alertas: controller.resultado.alertas),
          const SizedBox(height: 20),

          // 6. Erros
          if (controller.resultado.erros.isNotEmpty)
            _ErrosCard(erros: controller.resultado.erros),
          const SizedBox(height: 20),

          // 7. Botão "Gerar PDF"
          _PdfButton(controller: controller),
          const SizedBox(height: 12),

          // 8. Botão "Novo cálculo"
          _NovoCalculoButton(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

/// Status Banner: verde, amarelo ou vermelho
class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.controller});

  final ResultadoController controller;

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor(controller.statusColor);
    final textColor = _getStatusTextColor(controller.statusColor);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            _getStatusIcon(controller.statusColor),
            color: textColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              controller.statusLabel,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(StatusColor status) {
    switch (status) {
      case StatusColor.success:
        return const Color(0xFFE8F5E9);
      case StatusColor.warning:
        return const Color(0xFFFFF3E0);
      case StatusColor.error:
        return const Color(0xFFFFEBEE);
    }
  }

  Color _getStatusTextColor(StatusColor status) {
    switch (status) {
      case StatusColor.success:
        return const Color(0xFF2E7D32);
      case StatusColor.warning:
        return const Color(0xFFE65100);
      case StatusColor.error:
        return const Color(0xFFC62828);
    }
  }

  IconData _getStatusIcon(StatusColor status) {
    switch (status) {
      case StatusColor.success:
        return Icons.check_circle;
      case StatusColor.warning:
        return Icons.warning;
      case StatusColor.error:
        return Icons.error;
    }
  }
}

/// Card "Estimativa de Custo"
class _CostEstimateCard extends StatelessWidget {
  const _CostEstimateCard({
    required this.controller,
    required this.currency,
  });

  final ResultadoController controller;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final total = controller.totalOrcamento ?? 0.0;
    final unitario = controller.custoUnitarioM2 ?? 0.0;
    final resumo = controller.resultado.orcamento?.resumo;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estimativa de Custo',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 16),
          // Total em destaque
          Text(
            currency.format(total),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF3E5D49),
                ),
          ),
          const SizedBox(height: 12),
          // Subtotais
          if (resumo != null) ...[
            _SubtotalRow(
              label: 'Materiais',
              value: currency.format(resumo.subtotalMateriais),
            ),
            _SubtotalRow(
              label: 'Mão de obra',
              value: currency.format(resumo.subtotalMaoObra),
            ),
            _SubtotalRow(
              label: 'Custos indiretos',
              value: currency.format(resumo.subtotalIndiretos),
            ),
          ],
          const SizedBox(height: 12),
          // R$/m²
          Text(
            '${currency.format(unitario)}/m²',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}

/// Linha de subtotal
class _SubtotalRow extends StatelessWidget {
  const _SubtotalRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade700,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

/// Card "Quantitativos"
class _QuantitativosCard extends StatelessWidget {
  const _QuantitativosCard({required this.resultado});

  final ResultadoDimensionamentoDto resultado;

  @override
  Widget build(BuildContext context) {
    final q = resultado.quantitativos;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quantitativos',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 16),
          _QuantitativoItem(label: 'Vigotas', value: '${q.nVigotas} un'),
          _QuantitativoItem(label: 'Enchimentos EPS', value: '${q.nEnchimento} un'),
          _QuantitativoItem(label: 'Concreto da capa', value: '${q.volumeCapaM3.toStringAsFixed(2)} m³'),
          _QuantitativoItem(label: 'Tela soldada', value: '${q.pesoTelaKg.toStringAsFixed(2)} kg'),
        ],
      ),
    );
  }
}

/// Item de quantitativo
class _QuantitativoItem extends StatelessWidget {
  const _QuantitativoItem({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

/// Card "Verificações" (ELU + ELS)
class _VerificacoesCard extends StatelessWidget {
  const _VerificacoesCard({required this.resultado});

  final ResultadoDimensionamentoDto resultado;

  @override
  Widget build(BuildContext context) {
    final elu = resultado.elu!;
    final els = resultado.els;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Verificações',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 16),
          // Chips ELU
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _VerificacaoChip(
                label: 'Flexão',
                aprovado: elu.aprovadoFlexao,
              ),
              _VerificacaoChip(
                label: 'Cisalhamento',
                aprovado: elu.aprovadoCisalhamento,
              ),
              _VerificacaoChip(
                label: 'Armadura mínima',
                aprovado: elu.aprovadoArmaduraMinima,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // ELS: flecha total vs limite
          if (els != null) ...[
            Text(
              'Flecha: ${els.flechaTotal.toStringAsFixed(2)} cm (limite ${els.flechaLimite.toStringAsFixed(2)} cm)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: els.aprovado
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Chip de verificação
class _VerificacaoChip extends StatelessWidget {
  const _VerificacaoChip({
    required this.label,
    required this.aprovado,
  });

  final String label;
  final bool aprovado;

  @override
  Widget build(BuildContext context) {
    final bgColor = aprovado ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE);
    final fgColor = aprovado ? const Color(0xFF2E7D32) : const Color(0xFFC62828);
    final icon = aprovado ? Icons.check : Icons.close;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fgColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fgColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: fgColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Card "Alertas"
class _AlertasCard extends StatelessWidget {
  const _AlertasCard({required this.alertas});

  final List<MensagemSistemaDto> alertas;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info, color: Colors.amber.shade700),
              const SizedBox(width: 10),
              Text(
                'Alertas',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.amber.shade700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...alertas.map((alerta) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                alerta.message,
                style: TextStyle(
                  color: Colors.amber.shade900,
                  fontSize: 13,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Card "Erros"
class _ErrosCard extends StatelessWidget {
  const _ErrosCard({required this.erros});

  final List<MensagemSistemaDto> erros;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error, color: Colors.red.shade700),
              const SizedBox(width: 10),
              Text(
                'Erros',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.red.shade700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...erros.map((erro) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                erro.message,
                style: TextStyle(
                  color: Colors.red.shade900,
                  fontSize: 13,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Botão "Gerar PDF"
class _PdfButton extends StatelessWidget {
  const _PdfButton({required this.controller});

  final ResultadoController controller;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonal(
      onPressed: () => _handlePdf(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: controller.isPdfLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Gerar PDF'),
      ),
    );
  }

  Future<void> _handlePdf(BuildContext context) async {
    await controller.solicitarPdf();

    if (controller.isPdfReady && controller.pdfBytes != null) {
      try {
        await Printing.sharePdf(
          bytes: controller.pdfBytes!,
          filename: 'relatorio_laje.pdf',
        );
      } catch (e) {
        // Erro ao compartilhar
      }
    }

    if (controller.pdfError != null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(controller.pdfError!),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }
}

/// Botão "Novo cálculo"
class _NovoCalculoButton extends StatelessWidget {
  const _NovoCalculoButton();

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () {
        Navigator.pop(context);
      },
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text('Novo cálculo'),
      ),
    );
  }
}
