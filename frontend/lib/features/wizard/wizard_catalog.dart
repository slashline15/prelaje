import 'package:flutter/material.dart';

class WizardUseOption {
  const WizardUseOption({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.baseFactor,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final double baseFactor;
}

class WizardVigotaOption {
  const WizardVigotaOption({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.priceFactor,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final double priceFactor;
}

class WizardFinishOption {
  const WizardFinishOption({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.priceFactor,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final double priceFactor;
}

class WizardEstimateItem {
  const WizardEstimateItem({
    required this.label,
    required this.value,
  });

  final String label;
  final double value;
}

class WizardEstimate {
  const WizardEstimate({
    required this.areaM2,
    required this.minTotal,
    required this.maxTotal,
    required this.unitPrice,
    required this.statusLabel,
    required this.topItems,
  });

  final double areaM2;
  final double minTotal;
  final double maxTotal;
  final double unitPrice;
  final String statusLabel;
  final List<WizardEstimateItem> topItems;

  double get averageTotal => (minTotal + maxTotal) / 2;
}

const wizardUses = <WizardUseOption>[
  WizardUseOption(
    id: 'residencial',
    title: 'Quarto / sala',
    subtitle: 'Uso leve e comum de obra residencial.',
    icon: Icons.bed_outlined,
    baseFactor: 1.00,
  ),
  WizardUseOption(
    id: 'comercial',
    title: 'Escritório',
    subtitle: 'Ambiente com mais carga de uso.',
    icon: Icons.work_outline,
    baseFactor: 1.18,
  ),
  WizardUseOption(
    id: 'garagem',
    title: 'Garagem',
    subtitle: 'Tende a exigir acabamento mais robusto.',
    icon: Icons.directions_car_outlined,
    baseFactor: 1.12,
  ),
  WizardUseOption(
    id: 'educacao',
    title: 'Escola',
    subtitle: 'Maior fluxo de pessoas e atenção ao custo.',
    icon: Icons.school_outlined,
    baseFactor: 1.24,
  ),
];

const wizardVigotas = <WizardVigotaOption>[
  WizardVigotaOption(
    id: '8cm',
    title: 'Vigota 8 cm / 42 cm',
    subtitle: 'Mais econômica para vãos curtos.',
    icon: Icons.line_weight_outlined,
    priceFactor: 0.92,
  ),
  WizardVigotaOption(
    id: '10cm',
    title: 'Vigota 10 cm / 42 cm',
    subtitle: 'Equilíbrio entre custo e rigidez.',
    icon: Icons.line_axis_outlined,
    priceFactor: 1.00,
  ),
  WizardVigotaOption(
    id: '12cm',
    title: 'Vigota 12 cm / 42 cm',
    subtitle: 'Mais reforçada para cenários exigentes.',
    icon: Icons.straight_outlined,
    priceFactor: 1.12,
  ),
];

const wizardFinishes = <WizardFinishOption>[
  WizardFinishOption(
    id: 'simples',
    title: 'Acabamento simples',
    subtitle: 'Piso leve e revestimento básico.',
    icon: Icons.layers_outlined,
    priceFactor: 0.92,
  ),
  WizardFinishOption(
    id: 'medio',
    title: 'Acabamento médio',
    subtitle: 'Padrão equilibrado para obra comum.',
    icon: Icons.domain_outlined,
    priceFactor: 1.00,
  ),
  WizardFinishOption(
    id: 'reforcado',
    title: 'Acabamento reforçado',
    subtitle: 'Mais camadas e margem de segurança.',
    icon: Icons.construction_outlined,
    priceFactor: 1.12,
  ),
];

WizardEstimate estimateQuote({
  required double vao,
  required double largura,
  required WizardUseOption usage,
  required WizardVigotaOption vigota,
  required WizardFinishOption finish,
}) {
  final area = vao * largura;
  final basePricePerM2 = 180.0 * usage.baseFactor * vigota.priceFactor * finish.priceFactor;
  final distanceFactor = vao <= 4 ? 1.0 : 1.0 + ((vao - 4.0) * 0.04);
  final unitPrice = basePricePerM2 * distanceFactor;
  final average = area * unitPrice;
  final min = average * 0.93;
  final max = average * 1.07;

  final shares = <WizardEstimateItem>[
    WizardEstimateItem(label: 'Vigotas', value: average * 0.24),
    WizardEstimateItem(label: 'EPS', value: average * 0.16),
    WizardEstimateItem(label: 'Concreto', value: average * 0.19),
    WizardEstimateItem(label: 'Mao de obra', value: average * 0.21),
    WizardEstimateItem(label: 'Tela e reforcos', value: average * 0.11),
    WizardEstimateItem(label: 'Escoramento e extras', value: average * 0.09),
  ]..sort((a, b) => b.value.compareTo(a.value));

  return WizardEstimate(
    areaM2: area,
    minTotal: min,
    maxTotal: max,
    unitPrice: unitPrice,
    statusLabel: 'Estimativa offline pronta',
    topItems: shares.take(5).toList(),
  );
}
