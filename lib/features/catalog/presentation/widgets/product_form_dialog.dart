import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/catalog_product.dart';
import '../catalog_colors.dart';

Future<CatalogProduct?> showProductFormDialog(
  BuildContext context, {
  CatalogProduct? product,
}) {
  return showDialog<CatalogProduct>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.84),
    builder: (context) => ProductFormDialog(product: product),
  );
}

class ProductFormDialog extends StatefulWidget {
  const ProductFormDialog({this.product, super.key});

  final CatalogProduct? product;

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _heightController;
  late final TextEditingController _widthController;
  late final TextEditingController _lengthController;
  late final TextEditingController _capacityController;
  late final TextEditingController _singleHoursController;
  late final TextEditingController _singleMinutesController;
  late final TextEditingController _singlePriceController;
  late final TextEditingController _fullHoursController;
  late final TextEditingController _fullMinutesController;
  late final TextEditingController _fullPriceController;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    final singleTime = product?.singleUnitTimeMinutes.round();
    final fullTime = product?.fullBedTotalTimeMinutes.round();

    _nameController = TextEditingController(text: product?.name ?? '');
    _heightController = TextEditingController(
      text: _editableNumber(product?.dimensions.height),
    );
    _widthController = TextEditingController(
      text: _editableNumber(product?.dimensions.width),
    );
    _lengthController = TextEditingController(
      text: _editableNumber(product?.dimensions.length),
    );
    _capacityController = TextEditingController(
      text: product?.bedCapacity.toString() ?? '',
    );
    _singleHoursController = TextEditingController(
      text: singleTime == null ? '' : (singleTime ~/ 60).toString(),
    );
    _singleMinutesController = TextEditingController(
      text: singleTime == null ? '' : (singleTime % 60).toString(),
    );
    _singlePriceController = TextEditingController(
      text: _editableCurrency(product?.singleUnitPrice),
    );
    _fullHoursController = TextEditingController(
      text: fullTime == null ? '' : (fullTime ~/ 60).toString(),
    );
    _fullMinutesController = TextEditingController(
      text: fullTime == null ? '' : (fullTime % 60).toString(),
    );
    _fullPriceController = TextEditingController(
      text: _editableCurrency(product?.fullBedUnitPrice),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    _widthController.dispose();
    _lengthController.dispose();
    _capacityController.dispose();
    _singleHoursController.dispose();
    _singleMinutesController.dispose();
    _singlePriceController.dispose();
    _fullHoursController.dispose();
    _fullMinutesController.dispose();
    _fullPriceController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final singleTime = _durationInMinutes(
      _singleHoursController,
      _singleMinutesController,
    );
    final fullTime = _durationInMinutes(
      _fullHoursController,
      _fullMinutesController,
    );
    final singlePrice = _parseNumber(_singlePriceController.text)!;
    final fullPrice = _parseNumber(_fullPriceController.text)!;

    if (singleTime <= 0 || fullTime <= 0) {
      _showValidationMessage(
        'Os tempos de impressão devem ser maiores que zero.',
      );
      return;
    }
    if (fullPrice > singlePrice) {
      _showValidationMessage(
        'O preço unitário da mesa cheia deve ser menor ou igual ao preço base.',
      );
      return;
    }
    if (fullTime < singleTime) {
      _showValidationMessage(
        'O tempo total da mesa cheia não pode ser menor que o tempo de 1 peça.',
      );
      return;
    }

    Navigator.of(context).pop(
      CatalogProduct(
        id: widget.product?.id ?? const Uuid().v4(),
        name: _nameController.text.trim(),
        dimensions: ProductDimensions(
          height: _parseNumber(_heightController.text)!,
          width: _parseNumber(_widthController.text)!,
          length: _parseNumber(_lengthController.text)!,
        ),
        bedCapacity: int.parse(_capacityController.text),
        singleUnitPrice: singlePrice,
        singleUnitTimeMinutes: singleTime.toDouble(),
        fullBedUnitPrice: fullPrice,
        fullBedTotalTimeMinutes: fullTime.toDouble(),
      ),
    );
  }

  void _showValidationMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final viewportHeight = MediaQuery.sizeOf(context).height;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 560,
          maxHeight: viewportHeight * 0.92,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: catalogSurface,
            border: Border.all(color: catalogBorder),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 40,
                offset: Offset(0, 18),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.disabled,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _DialogHeader(isEditing: _isEditing),
                  const SizedBox(height: 24),
                  _CatalogField(
                    controller: _nameController,
                    label: 'NOME DO PRODUTO',
                    hintText: 'Ex: Suporte de Headset V2',
                    keyboardType: TextInputType.text,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Informe o nome do produto.'
                        : null,
                  ),
                  const SizedBox(height: 18),
                  const Text('DIMENSÕES DA PEÇA (CM)', style: _labelStyle),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _CatalogField(
                          controller: _heightController,
                          semanticLabel: 'Altura',
                          hintText: 'Altura',
                          validator: _validatePositiveNumber,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _CatalogField(
                          controller: _widthController,
                          semanticLabel: 'Largura',
                          hintText: 'Largura',
                          validator: _validatePositiveNumber,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _CatalogField(
                          controller: _lengthController,
                          semanticLabel: 'Comprimento',
                          hintText: 'Comprimento',
                          validator: _validatePositiveNumber,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _CatalogField(
                    controller: _capacityController,
                    label: 'CAPACIDADE MÁXIMA DA MESA (PEÇAS)',
                    hintText: 'Ex: 6',
                    decimal: false,
                    validator: (value) {
                      final parsed = int.tryParse(value ?? '');
                      return parsed == null || parsed < 1
                          ? 'Informe uma capacidade inteira maior que zero.'
                          : null;
                    },
                  ),
                  const SizedBox(height: 18),
                  _BatchSection(
                    title: '1 UNIDADE (PEÇA ÚNICA)',
                    color: catalogOrange,
                    hoursController: _singleHoursController,
                    minutesController: _singleMinutesController,
                    priceController: _singlePriceController,
                    priceLabel: 'Preço Base (R\$)',
                  ),
                  const SizedBox(height: 16),
                  _BatchSection(
                    title: 'MESA CHEIA (CAPACIDADE MÁXIMA)',
                    color: const Color(0xFF20D997),
                    hoursController: _fullHoursController,
                    minutesController: _fullMinutesController,
                    priceController: _fullPriceController,
                    priceLabel: 'Preço p/ Unid Mesa Cheia (R\$)',
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 50,
                    child: FilledButton(
                      onPressed: _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: catalogOrange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: Text(
                        _isEditing ? 'Salvar Alterações' : 'Salvar Produto',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DialogHeader extends StatelessWidget {
  const _DialogHeader({required this.isEditing});

  final bool isEditing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: catalogOrange.withValues(alpha: 0.10),
            border: Border.all(color: catalogOrange.withValues(alpha: 0.45)),
            borderRadius: BorderRadius.circular(11),
          ),
          child: const Icon(
            Icons.view_in_ar_outlined,
            color: catalogOrange,
            size: 24,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditing
                    ? 'Editar Produto do Catálogo'
                    : 'Cadastrar Produto no Catálogo',
                style: const TextStyle(
                  color: catalogTextPrimary,
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Insira as especificações para cálculo da mesa',
                style: TextStyle(color: catalogTextMuted, fontSize: 12),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Fechar',
          onPressed: () => Navigator.of(context).pop(),
          color: catalogTextMuted,
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.close, size: 21),
        ),
      ],
    );
  }
}

class _BatchSection extends StatelessWidget {
  const _BatchSection({
    required this.title,
    required this.color,
    required this.hoursController,
    required this.minutesController,
    required this.priceController,
    required this.priceLabel,
  });

  final String title;
  final Color color;
  final TextEditingController hoursController;
  final TextEditingController minutesController;
  final TextEditingController priceController;
  final String priceLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: catalogSurfaceRaised.withValues(alpha: 0.72),
        border: Border.all(color: catalogBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final duration = _DurationFields(
                hoursController: hoursController,
                minutesController: minutesController,
              );
              final price = _CatalogField(
                controller: priceController,
                label: priceLabel,
                hintText: 'R\$ 45,00',
                validator: _validatePositiveNumber,
              );

              if (constraints.maxWidth < 410) {
                return Column(
                  children: [duration, const SizedBox(height: 14), price],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: duration),
                  const SizedBox(width: 12),
                  Expanded(child: price),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DurationFields extends StatelessWidget {
  const _DurationFields({
    required this.hoursController,
    required this.minutesController,
  });

  final TextEditingController hoursController;
  final TextEditingController minutesController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Tempo de Impressão', style: _subLabelStyle),
        const SizedBox(height: 7),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _CatalogField(
                controller: hoursController,
                semanticLabel: 'Horas',
                hintText: 'Horas',
                decimal: false,
                validator: _validateDurationPart,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _CatalogField(
                controller: minutesController,
                semanticLabel: 'Minutos',
                hintText: 'Min',
                decimal: false,
                validator: (value) {
                  final parsed = int.tryParse(value ?? '');
                  if (parsed == null || parsed < 0 || parsed > 59) {
                    return '0 a 59';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CatalogField extends StatelessWidget {
  const _CatalogField({
    required this.controller,
    this.label,
    this.semanticLabel,
    this.hintText,
    this.keyboardType,
    this.decimal = true,
    this.validator,
  });

  final TextEditingController controller;
  final String? label;
  final String? semanticLabel;
  final String? hintText;
  final TextInputType? keyboardType;
  final bool decimal;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    final field = TextFormField(
      controller: controller,
      keyboardType:
          keyboardType ?? TextInputType.numberWithOptions(decimal: decimal),
      inputFormatters: keyboardType == TextInputType.text
          ? null
          : [
              FilteringTextInputFormatter.allow(
                decimal ? RegExp(r'[0-9,.]') : RegExp(r'[0-9]'),
              ),
            ],
      validator: validator,
      cursorColor: catalogOrange,
      style: const TextStyle(color: catalogTextPrimary, fontSize: 13),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Color(0xFF73737D), fontSize: 13),
        filled: true,
        fillColor: catalogSurfaceRaised,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 13,
          vertical: 14,
        ),
        errorMaxLines: 2,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: catalogBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: catalogOrange, width: 1.3),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE5484D)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE5484D), width: 1.3),
        ),
      ),
    );

    final semantics = semanticLabel == null
        ? field
        : Semantics(label: semanticLabel, textField: true, child: field);
    if (label == null) return semantics;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label!, style: _labelStyle),
        const SizedBox(height: 8),
        semantics,
      ],
    );
  }
}

const _labelStyle = TextStyle(
  color: Color(0xFFD0D0D5),
  fontSize: 11,
  fontWeight: FontWeight.w700,
  letterSpacing: 0.35,
);

const _subLabelStyle = TextStyle(color: catalogTextMuted, fontSize: 11);

String? _validatePositiveNumber(String? value) {
  final parsed = _parseNumber(value ?? '');
  return parsed == null || parsed <= 0
      ? 'Informe um valor maior que zero.'
      : null;
}

String? _validateDurationPart(String? value) {
  final parsed = int.tryParse(value ?? '');
  return parsed == null || parsed < 0 ? 'Valor inválido.' : null;
}

double? _parseNumber(String value) {
  var normalized = value.trim().replaceAll('R\$', '').replaceAll(' ', '');
  if (normalized.contains(',') && normalized.contains('.')) {
    normalized = normalized.replaceAll('.', '').replaceAll(',', '.');
  } else {
    normalized = normalized.replaceAll(',', '.');
  }
  final parsed = double.tryParse(normalized);
  return parsed != null && parsed.isFinite ? parsed : null;
}

int _durationInMinutes(
  TextEditingController hours,
  TextEditingController minutes,
) {
  return int.parse(hours.text) * 60 + int.parse(minutes.text);
}

String _editableNumber(double? value) {
  if (value == null) return '';
  return value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(2).replaceFirst('.', ',');
}

String _editableCurrency(double? value) {
  return value?.toStringAsFixed(2).replaceFirst('.', ',') ?? '';
}
