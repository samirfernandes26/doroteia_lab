import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/calculator_provider.dart';
import '../services/budget_image_exporter.dart';
import '../services/budget_image_generator.dart';

const _orange = Color(0xFFFF6B00);
const _green = Color(0xFF25D991);
const _surface = Color(0xFF131316);
const _surfaceRaised = Color(0xFF19191D);
const _border = Color(0xFF303036);
const _muted = Color(0xFF94949E);

final _currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

Future<void> showShareBudgetDialog(
  BuildContext context,
  CalculatorState budget,
) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.82),
    builder: (context) => ShareBudgetDialog(budget: budget),
  );
}

class ShareBudgetDialog extends StatefulWidget {
  const ShareBudgetDialog({required this.budget, super.key});

  final CalculatorState budget;

  @override
  State<ShareBudgetDialog> createState() => _ShareBudgetDialogState();
}

class _ShareBudgetDialogState extends State<ShareBudgetDialog> {
  bool _isGeneratingImage = false;

  Future<void> _copySummary(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(
      ClipboardData(text: formatBudgetSummary(widget.budget)),
    );

    if (!context.mounted) return;
    Navigator.of(context).pop();
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Resumo copiado para a área de transferência.'),
      ),
    );
  }

  Future<void> _openWhatsApp(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final uri = Uri.https('wa.me', '/', {
      'text': formatBudgetSummary(widget.budget),
    });

    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!context.mounted) return;

      if (!opened) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o WhatsApp.')),
        );
        return;
      }

      Navigator.of(context).pop();
    } on PlatformException {
      messenger.showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o WhatsApp.')),
      );
    }
  }

  Future<void> _printBudget(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      await Printing.layoutPdf(
        name: _pdfFileName(widget.budget.projectName),
        onLayout: (format) => _buildBudgetPdf(format, widget.budget),
      );

      if (context.mounted) Navigator.of(context).pop();
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Não foi possível preparar o PDF do orçamento.'),
        ),
      );
    }
  }

  Future<void> _shareAsImage(BuildContext context) async {
    if (_isGeneratingImage) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isGeneratingImage = true);

    try {
      final pngBytes = await const BudgetImageGenerator().generate(
        widget.budget,
      );
      await exportBudgetImage(
        pngBytes,
        budgetImageFileName(widget.budget.projectName),
      );

      if (context.mounted) Navigator.of(context).pop();
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Não foi possível gerar a imagem do orçamento.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isGeneratingImage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: _surface,
            border: Border.all(color: _border),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 40,
                offset: Offset(0, 18),
              ),
            ],
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: _orange.withValues(alpha: 0.09),
                        border: Border.all(
                          color: _orange.withValues(alpha: 0.5),
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.share_outlined,
                        color: _orange,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Compartilhar Orçamento',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Escolha como deseja enviar este orçamento',
                            style: TextStyle(
                              color: _muted,
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Fechar',
                      onPressed: () => Navigator.of(context).pop(),
                      visualDensity: VisualDensity.compact,
                      color: _muted,
                      icon: const Icon(Icons.close, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _ShareOption(
                  icon: Icons.copy_all_outlined,
                  iconColor: _orange,
                  title: 'Copiar Resumo Formatado',
                  subtitle: 'Copia o texto detalhado para colar onde quiser',
                  onTap: () => _copySummary(context),
                ),
                const SizedBox(height: 10),
                _ShareOption(
                  icon: Icons.chat_bubble_outline_rounded,
                  iconColor: _green,
                  title: 'Enviar Direto pelo WhatsApp',
                  titleColor: _green,
                  subtitle: 'Abre o WhatsApp com a mensagem formatada',
                  onTap: () => _openWhatsApp(context),
                ),
                const SizedBox(height: 10),
                _ShareOption(
                  icon: Icons.image_outlined,
                  iconColor: _orange,
                  title: 'Compartilhar como Imagem',
                  subtitle: 'Gera um card visual pronto para compartilhar',
                  onTap: _isGeneratingImage
                      ? null
                      : () => _shareAsImage(context),
                  trailing: _isGeneratingImage
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            color: _orange,
                            strokeWidth: 2,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 10),
                _ShareOption(
                  icon: Icons.print_outlined,
                  iconColor: _orange,
                  title: 'Imprimir / Salvar em PDF',
                  subtitle: 'Gera um documento pronto para impressão',
                  onTap: () => _printBudget(context),
                ),
                const SizedBox(height: 22),
                const Divider(color: _border, height: 1),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: _muted,
                    minimumSize: const Size.fromHeight(44),
                  ),
                  child: const Text('Cancelar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShareOption extends StatelessWidget {
  const _ShareOption({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.titleColor = Colors.white,
    this.trailing,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Color titleColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _surfaceRaised,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: _border),
        borderRadius: BorderRadius.circular(11),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(color: _muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              trailing ??
                  const Icon(Icons.chevron_right, color: _muted, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

String formatBudgetSummary(CalculatorState budget) {
  final name = budget.projectName.trim().isEmpty
      ? 'Projeto sem nome'
      : budget.projectName.trim();

  return '''
DOROTEIA LAB - ORÇAMENTO DE IMPRESSÃO 3D

Projeto / Peça: $name

Custo do Material: ${_currency.format(budget.materialCost)}
Custo Hora Máquina: ${_currency.format(budget.machineCost)}
Custo Total de Produção: ${_currency.format(budget.productionCost)}
Margem de Lucro: ${budget.profitMargin.toStringAsFixed(0)}%
Valor do Lucro: ${_currency.format(budget.profitValue)}

PREÇO DE VENDA FINAL: ${_currency.format(budget.finalPrice)}
'''
      .trim();
}

Future<Uint8List> _buildBudgetPdf(
  PdfPageFormat format,
  CalculatorState budget,
) async {
  final document = pw.Document(
    title: 'Orçamento - ${budget.projectName}',
    author: 'Doroteia Lab',
  );
  final orange = PdfColor.fromHex('#FF6B00');
  final green = PdfColor.fromHex('#159B68');
  final dark = PdfColor.fromHex('#17171A');
  final gray = PdfColor.fromHex('#667085');

  document.addPage(
    pw.Page(
      pageFormat: format,
      margin: const pw.EdgeInsets.all(42),
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Row(
              children: [
                pw.Container(
                  width: 42,
                  height: 42,
                  alignment: pw.Alignment.center,
                  decoration: pw.BoxDecoration(
                    color: orange,
                    borderRadius: pw.BorderRadius.circular(21),
                  ),
                  child: pw.Text(
                    'DL',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Doroteia Lab',
                      style: pw.TextStyle(
                        color: dark,
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Orçamento de Impressão 3D',
                      style: pw.TextStyle(color: gray, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 30),
            pw.Text(
              budget.projectName.trim().isEmpty
                  ? 'Projeto sem nome'
                  : budget.projectName.trim(),
              style: pw.TextStyle(
                color: dark,
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Divider(color: PdfColor.fromHex('#E4E7EC')),
            pw.SizedBox(height: 18),
            _pdfCostRow('Custo do Material', budget.materialCost, dark, gray),
            _pdfCostRow('Custo Hora Máquina', budget.machineCost, dark, gray),
            _pdfCostRow(
              'Custo Total de Produção',
              budget.productionCost,
              dark,
              gray,
              bold: true,
            ),
            _pdfCostRow(
              'Valor do Lucro (${budget.profitMargin.toStringAsFixed(0)}%)',
              budget.profitValue,
              green,
              gray,
              bold: true,
            ),
            pw.SizedBox(height: 24),
            pw.Container(
              padding: const pw.EdgeInsets.all(22),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#FFF4EC'),
                border: pw.Border.all(color: orange),
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Column(
                children: [
                  pw.Text(
                    'PREÇO DE VENDA FINAL SUGERIDO',
                    style: pw.TextStyle(
                      color: orange,
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    _currency.format(budget.finalPrice),
                    style: pw.TextStyle(
                      color: dark,
                      fontSize: 34,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            pw.Spacer(),
            pw.Text(
              'Orçamento gerado pela Calculadora de Custos Doroteia Lab.',
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(color: gray, fontSize: 9),
            ),
          ],
        );
      },
    ),
  );

  return document.save();
}

pw.Widget _pdfCostRow(
  String label,
  double value,
  PdfColor valueColor,
  PdfColor labelColor, {
  bool bold = false,
}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 8),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: pw.TextStyle(color: labelColor, fontSize: 11)),
        pw.Text(
          _currency.format(value),
          style: pw.TextStyle(
            color: valueColor,
            fontSize: 12,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ],
    ),
  );
}

String _pdfFileName(String projectName) {
  final normalized = projectName
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return 'orcamento-${normalized.isEmpty ? 'impressao-3d' : normalized}.pdf';
}
