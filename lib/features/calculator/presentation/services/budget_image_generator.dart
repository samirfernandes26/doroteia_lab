import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../providers/calculator_provider.dart';

class BudgetImageGenerator {
  const BudgetImageGenerator();

  static const width = 1200;
  static const height = 430;

  Future<Uint8List> generate(CalculatorState budget) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    _paintBackground(canvas);
    _paintContent(canvas, budget);

    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    picture.dispose();

    if (data == null) {
      throw StateError('Não foi possível gerar a imagem do orçamento.');
    }

    return data.buffer.asUint8List();
  }

  void _paintBackground(Canvas canvas) {
    const bounds = Rect.fromLTWH(0, 0, 1200, 430);
    final background = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(0, 0),
        const Offset(1200, 430),
        const [Color(0xFF121313), Color(0xFF090A0A)],
      );
    canvas.drawRect(bounds, background);

    final subtleGlow = Paint()
      ..shader = ui.Gradient.radial(const Offset(90, 70), 340, [
        const Color(0xFF16C7C1).withValues(alpha: 0.08),
        Colors.transparent,
      ]);
    canvas.drawRect(bounds, subtleGlow);
  }

  void _paintContent(Canvas canvas, CalculatorState budget) {
    final projectName = budget.projectName.trim().isEmpty
        ? 'Projeto sem nome'
        : budget.projectName.trim();
    final weight = _formatWeight(budget.pieceWeight);

    _drawLogoMark(canvas, const Offset(44, 28));
    _drawRichLine(
      canvas,
      offset: const Offset(92, 24),
      spans: const [
        TextSpan(
          text: 'DOROTEIA LAB — ORÇAMENTO',
          style: TextStyle(
            color: Color(0xFFF4F4F5),
            fontSize: 27,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );

    _drawInformationLine(
      canvas,
      y: 82,
      icon: Icons.inventory_2_rounded,
      iconColor: const Color(0xFFC99554),
      label: 'Projeto: ',
      value: projectName,
      valueStyle: const TextStyle(
        color: Color(0xFFE6E6E8),
        fontSize: 25,
        fontStyle: FontStyle.italic,
      ),
    );
    _drawInformationLine(
      canvas,
      y: 137,
      icon: Icons.precision_manufacturing_outlined,
      iconColor: const Color(0xFF8DB5C8),
      label: 'Especificação: ',
      value: 'Impressão 3D (~$weight)',
      valueStyle: const TextStyle(
        color: Color(0xFFE6E6E8),
        fontSize: 25,
        fontStyle: FontStyle.italic,
      ),
    );
    _drawInformationLine(
      canvas,
      y: 192,
      icon: Icons.hourglass_top_rounded,
      iconColor: const Color(0xFFE0BA55),
      label: 'Prazo de Produção: ',
      value: '2 dias úteis',
      valueStyle: const TextStyle(
        color: Color(0xFFE6E6E8),
        fontSize: 25,
        fontStyle: FontStyle.italic,
      ),
    );
    _drawInformationLine(
      canvas,
      y: 247,
      icon: Icons.monetization_on_rounded,
      iconColor: const Color(0xFFF0BE38),
      label: 'VALOR TOTAL: ',
      value: _currency.format(budget.finalPrice),
      valueStyle: const TextStyle(
        color: Color(0xFFF8F8F8),
        fontSize: 26,
        fontWeight: FontWeight.w800,
      ),
    );
    _drawInformationLine(
      canvas,
      y: 302,
      icon: Icons.credit_card_rounded,
      iconColor: const Color(0xFFE4C934),
      label: 'Formas de Pagamento: ',
      value: 'PIX / Cartão',
      valueStyle: const TextStyle(
        color: Color(0xFFE6E6E8),
        fontSize: 25,
        fontStyle: FontStyle.italic,
      ),
    );
    _drawInformationLine(
      canvas,
      y: 365,
      icon: Icons.rocket_launch_rounded,
      iconColor: const Color(0xFFA7B3B8),
      label: '',
      value: 'Aguardamos sua aprovação para iniciar a produção!',
      valueStyle: const TextStyle(
        color: Color(0xFFE6E6E8),
        fontSize: 24,
        fontFamily: 'monospace',
      ),
    );
  }

  void _drawLogoMark(Canvas canvas, Offset offset) {
    final paint = Paint()
      ..shader = ui.Gradient.linear(
        offset,
        offset + const Offset(36, 28),
        const [Color(0xFF37E0D7), Color(0xFF079F9B)],
      )
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      offset + const Offset(1, 25),
      offset + const Offset(31, 1),
      paint,
    );
    canvas.drawLine(
      offset + const Offset(10, 27),
      offset + const Offset(35, 7),
      paint..strokeWidth = 4,
    );
  }

  void _drawInformationLine(
    Canvas canvas, {
    required double y,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required TextStyle valueStyle,
  }) {
    _drawIcon(canvas, icon, Offset(45, y + 2), iconColor);
    _drawRichLine(
      canvas,
      offset: Offset(92, y),
      spans: [
        TextSpan(
          text: label,
          style: const TextStyle(
            color: Color(0xFFF3F3F4),
            fontSize: 25,
            fontWeight: FontWeight.w800,
          ),
        ),
        TextSpan(text: value, style: valueStyle),
      ],
    );
  }

  void _drawIcon(Canvas canvas, IconData icon, Offset offset, Color color) {
    final painter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          color: color,
          fontSize: 30,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  void _drawRichLine(
    Canvas canvas, {
    required Offset offset,
    required List<InlineSpan> spans,
  }) {
    final painter = TextPainter(
      text: TextSpan(children: spans),
      textDirection: ui.TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: width - offset.dx - 42);
    painter.paint(canvas, offset);
  }

  String _formatWeight(double value) {
    final formatted = value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1).replaceAll('.', ',');
    return '${formatted}g';
  }
}

final _currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

String budgetImageFileName(String projectName) {
  final normalized = projectName
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return 'orcamento-${normalized.isEmpty ? 'impressao-3d' : normalized}.png';
}
