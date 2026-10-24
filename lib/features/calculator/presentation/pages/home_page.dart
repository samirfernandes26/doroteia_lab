import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/calculator_provider.dart';
import '../widgets/share_budget_dialog.dart';

const _orange = AppColors.brand;
const _green = AppColors.success;
const _background = AppColors.background;
const _surface = AppColors.surface;
const _surfaceRaised = AppColors.surfaceRaised;
const _border = AppColors.border;
const _textPrimary = AppColors.textPrimary;
const _textMuted = AppColors.textMuted;

final _currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

class CalculatorPage extends ConsumerWidget {
  const CalculatorPage({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    await ref.read(authControllerProvider.notifier).signOut();

    if (!context.mounted) return;

    final result = ref.read(authControllerProvider);
    if (result.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível sair: ${result.error}')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calculator = ref.watch(calculatorProvider);
    final controller = ref.read(calculatorProvider.notifier);
    final authAction = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _CalculatorHeader(
              isSigningOut: authAction.isLoading,
              onBackToDashboard: () => context.go('/home'),
              onOpenCatalog: () => context.go('/catalogo'),
              onSignOut: () => _signOut(context, ref),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 30, 20, 48),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final projectCard = _ProjectDataCard(
                          state: calculator,
                          controller: controller,
                        );
                        final summaryCard = _BudgetSummaryCard(
                          state: calculator,
                          onShare: () =>
                              showShareBudgetDialog(context, calculator),
                        );

                        if (constraints.maxWidth < 900) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              projectCard,
                              const SizedBox(height: 22),
                              summaryCard,
                            ],
                          );
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 10, child: projectCard),
                            const SizedBox(width: 26),
                            Expanded(flex: 7, child: summaryCard),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalculatorHeader extends StatelessWidget {
  const _CalculatorHeader({
    required this.isSigningOut,
    required this.onBackToDashboard,
    required this.onOpenCatalog,
    required this.onSignOut,
  });

  final bool isSigningOut;
  final VoidCallback onBackToDashboard;
  final VoidCallback onOpenCatalog;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.header,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final brand = const _HeaderBrand();
                final actions = Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (constraints.maxWidth >= 520) const _PrecisionBadge(),
                    OutlinedButton.icon(
                      onPressed: onBackToDashboard,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _textPrimary,
                        side: const BorderSide(color: _border),
                      ),
                      icon: const Icon(Icons.arrow_back_rounded, size: 17),
                      label: const Text('Voltar ao Dashboard'),
                    ),
                    OutlinedButton.icon(
                      onPressed: onOpenCatalog,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _textMuted,
                        side: const BorderSide(color: _border),
                      ),
                      icon: const Icon(Icons.inventory_2_outlined, size: 17),
                      label: const Text('Catálogo'),
                    ),
                    IconButton(
                      tooltip: 'Sair',
                      onPressed: isSigningOut ? null : onSignOut,
                      color: _textMuted,
                      disabledColor: _textMuted.withValues(alpha: 0.35),
                      icon: isSigningOut
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(
                                color: _orange,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.logout_rounded, size: 20),
                    ),
                  ],
                );

                if (constraints.maxWidth < 900) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [brand, const SizedBox(height: 12), actions],
                  );
                }

                return Row(
                  children: [
                    brand,
                    const SizedBox(width: 18),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: actions,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderBrand extends StatelessWidget {
  const _HeaderBrand();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 50,
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.brandLight, _orange],
            ),
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFFFB072).withValues(alpha: 0.65),
            ),
            boxShadow: [
              BoxShadow(color: _orange.withValues(alpha: 0.28), blurRadius: 18),
            ],
          ),
          child: const Text(
            'DL',
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: 'Doroteia '),
                  TextSpan(
                    text: 'Lab',
                    style: TextStyle(color: _orange),
                  ),
                ],
              ),
              style: TextStyle(
                color: Colors.white,
                fontSize: 19,
                height: 1.1,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.35,
              ),
            ),
            SizedBox(height: 5),
            Text(
              'Calculadora de Custos de Impressão 3D',
              style: TextStyle(color: _textMuted, fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }
}

class _PrecisionBadge extends StatelessWidget {
  const _PrecisionBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: _surface,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.view_in_ar_outlined, color: _orange, size: 15),
          SizedBox(width: 7),
          Text(
            'Orçamento Rápido & Preciso',
            style: TextStyle(color: _textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _ProjectDataCard extends StatelessWidget {
  const _ProjectDataCard({required this.state, required this.controller});

  final CalculatorState state;
  final CalculatorController controller;

  @override
  Widget build(BuildContext context) {
    return _DarkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _CardHeader(
            icon: Icons.tune_rounded,
            title: 'Dados do Projeto',
            subtitle: 'Preencha os dados abaixo para calcular os custos',
          ),
          const SizedBox(height: 18),
          const Divider(color: _border, height: 1),
          const SizedBox(height: 22),
          _CostField(
            label: 'NOME DO PROJETO / PEÇA',
            initialValue: state.projectName,
            hintText: 'Ex.: Suporte de Headset',
            prefixIcon: Icons.description_outlined,
            keyboardType: TextInputType.text,
            onChanged: controller.setProjectName,
          ),
          const SizedBox(height: 20),
          _ResponsiveFieldPair(
            first: _CostField(
              label: 'PREÇO DO FILAMENTO (R\$/KG)',
              initialValue: _editableNumber(state.filamentPrice),
              prefixText: 'R\$  ',
              onChanged: controller.setFilamentPrice,
            ),
            second: _CostField(
              label: 'PESO DA PEÇA (G)',
              initialValue: _editableNumber(state.pieceWeight),
              suffixText: 'g',
              onChanged: controller.setPieceWeight,
            ),
          ),
          const SizedBox(height: 20),
          _ResponsiveFieldPair(
            first: _CostField(
              label: 'TEMPO DE IMPRESSÃO (HORAS)',
              initialValue: _editableNumber(state.printingHours),
              suffixText: 'h',
              onChanged: controller.setPrintingHours,
            ),
            second: _CostField(
              label: 'CUSTO/HORA MÁQUINA (R\$/H)',
              initialValue: _editableNumber(state.machineCostPerHour),
              prefixText: 'R\$  ',
              helperText: 'Energia + Depreciação',
              onChanged: controller.setMachineCostPerHour,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('MARGEM DE LUCRO (%)', style: _fieldLabelStyle),
              Text(
                '${state.profitMargin.toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: _orange,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: _orange,
                    inactiveTrackColor: const Color(0xFF202024),
                    thumbColor: _orange,
                    overlayColor: _orange.withValues(alpha: 0.14),
                    trackHeight: 5,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 7,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 17,
                    ),
                  ),
                  child: Slider(
                    value: state.profitMargin,
                    min: 0,
                    max: 500,
                    divisions: 500,
                    label: '${state.profitMargin.toStringAsFixed(0)}%',
                    onChanged: controller.setProfitMargin,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 82,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _surfaceRaised,
                  border: Border.all(color: _border),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: state.profitMargin.toStringAsFixed(0),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const TextSpan(
                        text: '   %',
                        style: TextStyle(color: _textMuted),
                      ),
                    ],
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BudgetSummaryCard extends StatelessWidget {
  const _BudgetSummaryCard({required this.state, required this.onShare});

  final CalculatorState state;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return _DarkCard(
      borderColor: _orange.withValues(alpha: 0.58),
      shadow: BoxShadow(
        color: _orange.withValues(alpha: 0.10),
        blurRadius: 28,
        offset: const Offset(0, 14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long_outlined, color: _orange, size: 21),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Resumo do Orçamento',
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _orange.withValues(alpha: 0.10),
                  border: Border.all(color: _orange.withValues(alpha: 0.38)),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'AO VIVO',
                  style: TextStyle(
                    color: _orange,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(color: _border, height: 1),
          const SizedBox(height: 19),
          _SummaryRow(
            label: 'Custo do Material',
            value: _currency.format(state.materialCost),
          ),
          const SizedBox(height: 16),
          _SummaryRow(
            label: 'Custo Hora Máquina',
            value: _currency.format(state.machineCost),
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFF25252A), height: 1),
          const SizedBox(height: 16),
          _SummaryRow(
            label: 'Custo Total de Produção',
            value: _currency.format(state.productionCost),
            emphasized: true,
          ),
          const SizedBox(height: 16),
          _SummaryRow(
            label: 'Valor do Lucro',
            value: '+ ${_currency.format(state.profitValue)}',
            labelColor: _green,
            valueColor: _green,
            emphasized: true,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_orange.withValues(alpha: 0.08), _surfaceRaised],
              ),
              border: Border.all(color: _orange.withValues(alpha: 0.55)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text(
                  'PREÇO DE VENDA FINAL SUGERIDO',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _orange,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 7),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _currency.format(state.finalPrice),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      height: 1.05,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Margem aplicada sobre o custo de produção',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _textMuted, fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: onShare,
              style: FilledButton.styleFrom(
                backgroundColor: _orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 3,
                shadowColor: _orange.withValues(alpha: 0.30),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              icon: const Icon(Icons.share_outlined, size: 20),
              label: const Text('Compartilhar Orçamento'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DarkCard extends StatelessWidget {
  const _DarkCard({
    required this.child,
    this.borderColor = _border,
    this.shadow,
  });

  final Widget child;
  final Color borderColor;
  final BoxShadow? shadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: _surface,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(14),
        boxShadow: shadow == null ? null : [shadow!],
      ),
      child: child,
    );
  }
}

class _CardHeader extends StatelessWidget {
  const _CardHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: _orange.withValues(alpha: 0.10),
            border: Border.all(color: _orange.withValues(alpha: 0.38)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: _orange, size: 21),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(color: _textMuted, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ResponsiveFieldPair extends StatelessWidget {
  const _ResponsiveFieldPair({required this.first, required this.second});

  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 520) {
          return Column(children: [first, const SizedBox(height: 20), second]);
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: first),
            const SizedBox(width: 18),
            Expanded(child: second),
          ],
        );
      },
    );
  }
}

class _CostField extends StatelessWidget {
  const _CostField({
    required this.label,
    required this.initialValue,
    required this.onChanged,
    this.hintText,
    this.prefixText,
    this.suffixText,
    this.helperText,
    this.prefixIcon,
    this.keyboardType = const TextInputType.numberWithOptions(decimal: true),
  });

  final String label;
  final String initialValue;
  final ValueChanged<String> onChanged;
  final String? hintText;
  final String? prefixText;
  final String? suffixText;
  final String? helperText;
  final IconData? prefixIcon;
  final TextInputType keyboardType;

  @override
  Widget build(BuildContext context) {
    final isNumeric = keyboardType != TextInputType.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: _fieldLabelStyle),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: initialValue,
          onChanged: onChanged,
          keyboardType: keyboardType,
          inputFormatters: isNumeric
              ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]'))]
              : null,
          cursorColor: _orange,
          style: const TextStyle(
            color: _textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              color: Color(0xFF686872),
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
            prefixText: prefixText,
            prefixStyle: const TextStyle(
              color: _textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: prefixIcon == null
                ? null
                : Icon(prefixIcon, color: _textMuted, size: 18),
            suffixText: suffixText,
            suffixStyle: const TextStyle(
              color: _textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            filled: true,
            fillColor: _surfaceRaised,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 15,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _orange, width: 1.4),
            ),
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 6),
          Text(
            helperText!,
            style: const TextStyle(color: _textMuted, fontSize: 10),
          ),
        ],
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.labelColor = _textMuted,
    this.valueColor = _textPrimary,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final Color labelColor;
  final Color valueColor;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: labelColor,
              fontSize: 13,
              fontWeight: emphasized ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Text(
          value,
          textAlign: TextAlign.right,
          style: TextStyle(
            color: valueColor,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

const _fieldLabelStyle = TextStyle(
  color: Color(0xFFD7D7DD),
  fontSize: 11,
  fontWeight: FontWeight.w700,
  letterSpacing: 0.2,
);

String _editableNumber(double value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value
      .toStringAsFixed(2)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}
