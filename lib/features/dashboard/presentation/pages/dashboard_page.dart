import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../catalog/presentation/providers/catalog_provider.dart';
import '../../domain/dashboard_module.dart';

const _background = AppColors.background;
const _headerBackground = AppColors.header;
const _surface = AppColors.surface;
const _surfaceRaised = AppColors.surfaceRaised;
const _border = AppColors.border;
const _brand = AppColors.brand;
const _textPrimary = AppColors.textPrimary;
const _textSecondary = AppColors.textMuted;
const _success = AppColors.success;

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(catalogProvider);
    final hasCatalogError = catalog.errorMessage != null;
    final productCount = catalog.isLoading
        ? '...'
        : hasCatalogError
        ? '—'
        : '${catalog.products.length}';

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _DashboardHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 48),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1240),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _DashboardHero(
                          productCount: productCount,
                          isCatalogLoading: catalog.isLoading,
                          hasCatalogError: hasCatalogError,
                        ),
                        const SizedBox(height: 34),
                        const _SectionHeading(),
                        const SizedBox(height: 18),
                        _DashboardModuleGrid(
                          modules: dashboardModules,
                          onOpenModule: (module) {
                            final route = module.route;
                            if (route != null) context.go(route);
                          },
                        ),
                      ],
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

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context) {
    final navigationModules = dashboardModules
        .where((module) => module.canNavigate)
        .toList(growable: false);

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: _headerBackground,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1240),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final navigation = Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _HeaderNavigationButton(
                      label: 'Dashboard',
                      icon: Icons.grid_view_rounded,
                      isActive: true,
                      onPressed: () => context.go('/home'),
                    ),
                    ...navigationModules.map(
                      (module) => _HeaderNavigationButton(
                        label: module.resolvedNavigationLabel,
                        icon: module.icon,
                        onPressed: () {
                          final route = module.route;
                          if (route != null) context.go(route);
                        },
                      ),
                    ),
                  ],
                );

                if (constraints.maxWidth < 880) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _DashboardBrand(),
                      const SizedBox(height: 14),
                      navigation,
                    ],
                  );
                }

                return Row(
                  children: [
                    const Flexible(flex: 2, child: _DashboardBrand()),
                    const SizedBox(width: 18),
                    Expanded(
                      flex: 3,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: navigation,
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

class _DashboardBrand extends StatelessWidget {
  const _DashboardBrand();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _DashboardMonogram(size: 46),
        SizedBox(width: 12),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: 'Doroteia '),
                    TextSpan(
                      text: 'Lab',
                      style: TextStyle(color: _brand),
                    ),
                  ],
                ),
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                  letterSpacing: -0.45,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Hub de Impressão 3D & Gestão de Custos',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: _textSecondary, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DashboardMonogram extends StatelessWidget {
  const _DashboardMonogram({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        color: Colors.black,
        shape: BoxShape.circle,
        border: Border.all(color: _brand, width: 2),
        boxShadow: [
          BoxShadow(color: _brand.withValues(alpha: 0.3), blurRadius: 16),
        ],
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.brandLight, _brand],
          ),
        ),
        child: Center(
          child: Text(
            'DL',
            style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.34,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderNavigationButton extends StatelessWidget {
  const _HeaderNavigationButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isActive = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: isActive ? _brand : _textSecondary,
        backgroundColor: isActive ? _brand.withValues(alpha: 0.08) : null,
        side: BorderSide(color: isActive ? _brand : Colors.transparent),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        visualDensity: VisualDensity.compact,
      ),
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _DashboardHero extends StatelessWidget {
  const _DashboardHero({
    required this.productCount,
    required this.isCatalogLoading,
    required this.hasCatalogError,
  });

  final String productCount;
  final bool isCatalogLoading;
  final bool hasCatalogError;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: _surfaceRaised,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(22),
        gradient: RadialGradient(
          center: const Alignment(1.15, -1.2),
          radius: 1.2,
          colors: [_brand.withValues(alpha: 0.15), Colors.transparent],
          stops: const [0, 0.72],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 280),
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: _brand.withValues(alpha: 0.10),
              border: Border.all(color: _brand.withValues(alpha: 0.35)),
              borderRadius: BorderRadius.circular(99),
            ),
            child: const FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.hub_outlined, color: _brand, size: 15),
                  SizedBox(width: 6),
                  Text(
                    'Painel de Controle Integrado',
                    maxLines: 1,
                    style: TextStyle(
                      color: _brand,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text.rich(
            TextSpan(
              children: [
                TextSpan(text: 'Bem-vindo ao '),
                TextSpan(
                  text: 'Doroteia Lab',
                  style: TextStyle(color: _brand),
                ),
              ],
            ),
            style: TextStyle(
              color: _textPrimary,
              fontSize: 34,
              height: 1.08,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.1,
            ),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 760),
            child: Text(
              'Gerencie custos de filamento, otimize a capacidade das peças por mesa e crie orçamentos comerciais de forma simples.',
              style: TextStyle(
                color: _textSecondary,
                fontSize: 15,
                height: 1.55,
              ),
            ),
          ),
          const SizedBox(height: 28),
          const Divider(color: _border, height: 1),
          const SizedBox(height: 22),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 520;
              final productKpi = _DashboardKpi(
                icon: Icons.inventory_2_outlined,
                label: 'Produtos no Catálogo',
                value: productCount,
                details: hasCatalogError
                    ? 'Catálogo indisponível'
                    : isCatalogLoading
                    ? 'Carregando catálogo'
                    : 'Itens salvos',
                valueKey: const ValueKey('dashboard-product-count'),
              );
              const systemKpi = _DashboardKpi(
                icon: Icons.check_circle_outline_rounded,
                iconColor: _success,
                label: 'Status do Sistema',
                value: 'Online',
                details: 'Pronto para cálculo',
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [productKpi, const SizedBox(height: 18), systemKpi],
                );
              }
              return Row(
                children: [
                  Expanded(child: productKpi),
                  const SizedBox(width: 24),
                  Expanded(child: systemKpi),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DashboardKpi extends StatelessWidget {
  const _DashboardKpi({
    required this.icon,
    required this.label,
    required this.value,
    required this.details,
    this.iconColor = _brand,
    this.valueKey,
  });

  final IconData icon;
  final String label;
  final String value;
  final String details;
  final Color iconColor;
  final Key? valueKey;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 19),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                key: valueKey,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: iconColor == _success ? _success : _textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                details,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _textSecondary, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.grid_view_rounded, color: _brand, size: 20),
            SizedBox(width: 9),
            Expanded(
              child: Text(
                'Módulos do Sistema',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.35,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 5),
        Text(
          'Selecione uma das aplicações abaixo para começar.',
          style: TextStyle(color: _textSecondary, fontSize: 13),
        ),
      ],
    );
  }
}

class _DashboardModuleGrid extends StatelessWidget {
  const _DashboardModuleGrid({
    required this.modules,
    required this.onOpenModule,
  });

  final List<DashboardModule> modules;
  final ValueChanged<DashboardModule> onOpenModule;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1024
            ? 3
            : constraints.maxWidth >= 600
            ? 2
            : 1;
        const spacing = 20.0;
        final cardWidth =
            (constraints.maxWidth - ((columns - 1) * spacing)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: modules
              .map(
                (module) => SizedBox(
                  width: cardWidth,
                  child: _DashboardModuleCard(
                    key: ValueKey('dashboard-module-${module.id}'),
                    module: module,
                    onTap: module.canNavigate
                        ? () => onOpenModule(module)
                        : null,
                  ),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class _DashboardModuleCard extends StatefulWidget {
  const _DashboardModuleCard({super.key, required this.module, this.onTap});

  final DashboardModule module;
  final VoidCallback? onTap;

  @override
  State<_DashboardModuleCard> createState() => _DashboardModuleCardState();
}

class _DashboardModuleCardState extends State<_DashboardModuleCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final module = widget.module;
    final enabled = widget.onTap != null;
    final highlighted = enabled && _isHovered;
    final borderColor = highlighted ? module.accentColor : _border;

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      height: 272,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: enabled ? _surface : _surface.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(20),
        border: enabled ? Border.all(color: borderColor) : null,
        boxShadow: highlighted
            ? [
                BoxShadow(
                  color: module.accentColor.withValues(alpha: 0.14),
                  blurRadius: 22,
                  offset: const Offset(0, 11),
                ),
              ]
            : const [],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -92,
            right: -76,
            child: IgnorePointer(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 176,
                height: 176,
                decoration: BoxDecoration(
                  color: module.accentColor.withValues(
                    alpha: highlighted ? 0.13 : 0.07,
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: module.accentColor.withValues(
                        alpha: highlighted ? 0.18 : 0.10,
                      ),
                      border: Border.all(
                        color: module.accentColor.withValues(
                          alpha: highlighted ? 0.72 : 0.45,
                        ),
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      module.icon,
                      color: module.accentColor,
                      size: highlighted ? 27 : 24,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: _ModuleBadge(module: module),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                module.title,
                style: TextStyle(
                  color: enabled ? _textPrimary : _textSecondary,
                  fontSize: 18,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.25,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Text(
                  module.description,
                  style: TextStyle(
                    color: enabled
                        ? _textSecondary
                        : _textSecondary.withValues(alpha: 0.72),
                    fontSize: 13,
                    height: 1.48,
                  ),
                ),
              ),
              const Divider(color: _border, height: 1),
              const SizedBox(height: 13),
              Row(
                children: [
                  Text(
                    enabled ? 'Abrir módulo' : 'Em preparação',
                    style: TextStyle(
                      color: enabled ? module.accentColor : _textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    enabled ? Icons.arrow_forward_rounded : Icons.lock_outline,
                    color: enabled ? module.accentColor : _textSecondary,
                    size: 18,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    return Semantics(
      button: enabled,
      enabled: enabled,
      label: '${module.title}. ${module.description}',
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: enabled ? (_) => setState(() => _isHovered = true) : null,
        onExit: enabled ? (_) => setState(() => _isHovered = false) : null,
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          offset: highlighted ? const Offset(0, -0.025) : Offset.zero,
          child: enabled
              ? Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onTap,
                    borderRadius: BorderRadius.circular(20),
                    child: card,
                  ),
                )
              : CustomPaint(
                  foregroundPainter: _DashedRoundedBorderPainter(
                    color: _border,
                  ),
                  child: card,
                ),
        ),
      ),
    );
  }
}

class _ModuleBadge extends StatelessWidget {
  const _ModuleBadge({required this.module});

  final DashboardModule module;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: module.accentColor.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        module.badge,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: module.canNavigate ? module.accentColor : _textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _DashedRoundedBorderPainter extends CustomPainter {
  const _DashedRoundedBorderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(20)),
      );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    for (final metric in path.computeMetrics()) {
      for (var distance = 0.0; distance < metric.length; distance += 10) {
        canvas.drawPath(
          metric.extractPath(distance, math.min(distance + 5, metric.length)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRoundedBorderPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
