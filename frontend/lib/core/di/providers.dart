import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../../data/repositories/dimensionamento_repository.dart';

/// Lista de providers registrados no topo da árvore de widgets.
final List<SingleChildWidget> appProviders = [
  // DimensionamentoRepository não é ChangeNotifier — usa Provider simples
  // com dispose para fechar o HttpClient corretamente.
  Provider<DimensionamentoRepository>(
    create: (_) => DimensionamentoRepository(),
    dispose: (_, repo) => repo.dispose(),
  ),
];