// ═══════════════════════════════════════════════════════════════════════════
// PDF DE LOTE VETORIAL — uma página por crachá, texto vetorial.
//
// SUBSTITUI o caminho anterior (`MultiBadgeImagePdfGenerator`), que montava
// cada `BadgeView` num `Overlay` invisível e capturava com `toImage()`.
//
// POR QUE MUDAR
//
// O `toImage()` depende de a árvore estar rasterizada. Com o `BadgeView`
// novo, a imagem do fundo e da foto chegam por `FutureBuilder` (decodificação
// assíncrona), então "esperar 3 frames" deixou de ser suficiente: em
// numeração alta o capture rodava antes do primeiro `Future` resolver e a
// página saía em branco.
//
// A captura também era um beco sem saída de測 — `toImage` trava no runner
// headless, então esse caminho nunca teve teste automatizado possível.
//
// A solução: o lote usa EXATAMENTE o mesmo gerador do individual
// ([CrachaVectorPdfService]). Sem widget montado, sem `Overlay`, sem
// `toImage`, sem espera de frame. Cada crachá vira uma página e o layout vem
// do [CrachaLayout] medido com o Skia — o mesmo do preview.
//
// Custo: o PNG de fundo+foto é regerado por crachá. Num lote de 200 são 200
// encodes de 1273×2004. Isso é CPU, não memória — as imagens de origem vêm
// do cache de `badge_assets.dart`.
// ═══════════════════════════════════════════════════════════════════════════
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/badge_data.dart';
import '../views/badge_assets.dart';
import '../views/badge_geometry.dart';
import 'cracha_vector_pdf_service.dart';
import 'pdf_reference_page.dart';

abstract final class MultiBadgeVectorPdfGenerator {
  MultiBadgeVectorPdfGenerator._();

  /// Gera um PDF com uma página por crachá + a folha de referência.
  ///
  /// Devolve os bytes sem compartilhar — quem chama decide o que fazer.
  /// Isso mantém o gerador testável sem `Printing.sharePdf` (que abre
  /// diálogo nativo e não roda em teste).
  static Future<Uint8List> buildBytes(List<BadgeData> badges) async {
    if (badges.isEmpty) {
      throw StateError('Nenhum crachá para exportar.');
    }

    // O fundo é o mesmo para todos: decodifica uma vez.
    final fundo = await fundoDoCracha();
    final doc = pw.Document();

    for (final badge in badges) {
      await CrachaVectorPdfService.addPage(
        doc,
        dados: _dadosDe(badge),
        ajuste: const FotoAjuste(),
        fondo: fundo,
        foto: await fotoDoBadge(badge) ?? await fotoPadrao(),
      );
    }

    await appendReferencePage(doc);
    return doc.save();
  }

  /// Converte o modelo do app no modelo do layout, aplicando os mesmos
  /// placeholders do preview (`BadgeView._dados`).
  static CrachaDados _dadosDe(BadgeData badge) {
    final nome = badge.name.trim();
    final cargo = badge.role.trim();
    final dept = badge.department.trim();
    return CrachaDados(
      nome: nome.isEmpty ? 'NOME DO SERVIDOR' : nome,
      cargo: cargo.isEmpty ? 'CARGO DO SERVIDOR' : cargo,
      secretaria: dept.isEmpty ? 'SECRETARIA' : dept,
      maiusculas: true,
    );
  }
}

/// Atalho que abre o diálogo de progresso e compartilha o PDF.
abstract final class MultiBadgeVectorPdfShare {
  MultiBadgeVectorPdfShare._();

  static Future<void> share(List<BadgeData> badges, BuildContext context) async {
    if (badges.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum crachá selecionado.')),
      );
      return;
    }

    final progresso = ValueNotifier<double>(0);
    final texto = ValueNotifier<String>('Preparando os crachás...');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          content: ValueListenableBuilder<String>(
            valueListenable: texto,
            builder: (context, t, _) =>
                ValueListenableBuilder<double>(
              valueListenable: progresso,
              builder: (context, p, _) => SizedBox(
                height: 120,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 60,
                            height: 60,
                            child: CircularProgressIndicator(
                              value: p,
                              strokeWidth: 4,
                              backgroundColor: Colors.grey[200],
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF2E7D32),
                              ),
                            ),
                          ),
                          Text(
                            '${(p * 100).toInt()}%',
                            style: const TextStyle(
                              fontFamily: 'Rawline',
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      t,
                      style: const TextStyle(
                        fontFamily: 'Rawline',
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    try {
      progresso.value = 0.4;
      texto.value = 'Gerando ${badges.length} crachá(s)...';

      final bytes = await MultiBadgeVectorPdfGenerator.buildBytes(badges);

      progresso.value = 1.0;
      texto.value = 'PDF gerado!';
      await Future.delayed(const Duration(milliseconds: 400));

      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      await Printing.sharePdf(
        bytes: bytes,
        filename: 'crachás_${badges.length}.pdf',
      );
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      if (!context.mounted) return;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(width: 10),
              Text('Erro'),
            ],
          ),
          content: Text('Não foi possível gerar o PDF: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      progresso.dispose();
      texto.dispose();
    }
  }
}