import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../profile/profile_store.dart';

/// Página de visualização de PDF gerado pelo backend.
///
/// Recebe os bytes do PDF e permite compartilhamento.
/// Não contém lógica de negócio — apenas exibição e share.
class PdfPreviewPage extends StatelessWidget {
  const PdfPreviewPage({
    super.key,
    required this.pdfBytes,
    required this.profile,
    required this.nomeArquivo,
  });

  final List<int> pdfBytes;
  final UserProfile profile;
  final String nomeArquivo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatório Preliminar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _sharePdf(context),
            tooltip: 'Compartilhar',
          ),
        ],
      ),
      body: PdfPreview(
        build: (_) => Uint8List.fromList(pdfBytes),
        allowPrinting: false,
        allowSharing: true,
        canChangePageFormat: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.close),
        label: const Text('Fechar'),
      ),
    );
  }

  Future<void> _sharePdf(BuildContext context) async {
    await Printing.sharePdf(
      bytes: Uint8List.fromList(pdfBytes),
      filename: nomeArquivo,
    );
  }
}