import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/catalog_product.dart';
import '../catalog_colors.dart';
import '../services/catalog_quote_formatter.dart';

final _currency = NumberFormat.currency(
  locale: 'pt_BR',
  symbol: 'R\$',
  decimalDigits: 2,
);

class CatalogProductCard extends StatelessWidget {
  const CatalogProductCard({
    required this.product,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
    required this.onEdit,
    required this.onDelete,
    required this.onWhatsApp,
    super.key,
  });

  final CatalogProduct product;
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onWhatsApp;

  @override
  Widget build(BuildContext context) {
    final normalizedQuantity = product.normalizeQuantity(quantity);
    final isFullBed = normalizedQuantity == product.bedCapacity;
    final discount = product.discountPercentageFor(normalizedQuantity);
    final unitPrice = product.unitPriceFor(normalizedQuantity);
    final totalPrice = product.totalPriceFor(normalizedQuantity);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: catalogSurface,
        border: Border.all(
          color: isFullBed
              ? catalogOrange.withValues(alpha: 0.82)
              : catalogBorder,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: isFullBed
            ? [
                BoxShadow(
                  color: catalogOrange.withValues(alpha: 0.08),
                  blurRadius: 24,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ProductHeader(
            product: product,
            isFullBed: isFullBed,
            onEdit: onEdit,
            onDelete: onDelete,
          ),
          const SizedBox(height: 18),
          _BedOccupancy(
            capacity: product.bedCapacity,
            quantity: normalizedQuantity,
          ),
          const SizedBox(height: 16),
          _QuantitySelector(
            productId: product.id,
            quantity: normalizedQuantity,
            canDecrement: normalizedQuantity > 1,
            canIncrement: normalizedQuantity < product.bedCapacity,
            onDecrement: onDecrement,
            onIncrement: onIncrement,
          ),
          const SizedBox(height: 16),
          const Divider(color: catalogBorder, height: 1),
          const SizedBox(height: 14),
          _ValueRow(
            label: 'Preço Unitário do Lote:',
            value: _currency.format(unitPrice),
            badge: discount > 0
                ? '-${discount.toStringAsFixed(discount >= 10 ? 0 : 1)}%'
                : null,
          ),
          const SizedBox(height: 10),
          _ValueRow(
            label: 'Tempo Estimado de Impressão:',
            value: formatDuration(
              product.totalTimeMinutesFor(normalizedQuantity),
            ),
            valueIcon: Icons.schedule_rounded,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: catalogSurfaceRaised,
              border: Border.all(color: catalogBorder),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Column(
              children: [
                Text(
                  'TOTAL DO LOTE ($normalizedQuantity UN)',
                  style: const TextStyle(
                    color: catalogTextMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.25,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _currency.format(totalPrice),
                  key: ValueKey('total-${product.id}'),
                  style: const TextStyle(
                    color: catalogOrange,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 13),
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: onWhatsApp,
              style: FilledButton.styleFrom(
                backgroundColor: catalogGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
              label: const Text('Enviar Orçamento WhatsApp'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductHeader extends StatelessWidget {
  const _ProductHeader({
    required this.product,
    required this.isFullBed,
    required this.onEdit,
    required this.onDelete,
  });

  final CatalogProduct product;
  final bool isFullBed;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: catalogTextPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            _HeaderAction(
              tooltip: 'Editar produto',
              icon: Icons.edit_outlined,
              onPressed: onEdit,
            ),
            _HeaderAction(
              tooltip: 'Excluir produto',
              icon: Icons.delete_outline_rounded,
              onPressed: onDelete,
            ),
          ],
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            const Icon(
              Icons.straighten_rounded,
              color: catalogOrange,
              size: 15,
            ),
            const SizedBox(width: 5),
            Text(
              '${formatProductDimensions(product.dimensions)} cm',
              style: const TextStyle(color: catalogTextMuted, fontSize: 11),
            ),
            if (isFullBed) ...[
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: catalogOrange.withValues(alpha: 0.12),
                  border: Border.all(
                    color: catalogOrange.withValues(alpha: 0.55),
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bolt_rounded, color: catalogOrange, size: 13),
                    SizedBox(width: 3),
                    Text(
                      'Mesa Cheia!',
                      style: TextStyle(
                        color: catalogOrange,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      color: catalogTextMuted,
      iconSize: 18,
      icon: Icon(icon),
    );
  }
}

class _BedOccupancy extends StatelessWidget {
  const _BedOccupancy({required this.capacity, required this.quantity});

  final int capacity;
  final int quantity;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: catalogSurfaceRaised.withValues(alpha: 0.72),
        border: Border.all(color: catalogBorder),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.grid_view_rounded,
                color: catalogOrange,
                size: 15,
              ),
              const SizedBox(width: 6),
              const Text(
                'Ocupação da Mesa',
                style: TextStyle(color: catalogTextMuted, fontSize: 12),
              ),
              const Spacer(),
              Text(
                '$quantity / $capacity un',
                style: const TextStyle(
                  color: catalogTextPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = capacity <= 4
                  ? capacity
                  : capacity <= 12
                  ? math.min(capacity, 6)
                  : math.min(capacity, 8);
              const gap = 5.0;
              final slotWidth =
                  (constraints.maxWidth - (columns - 1) * gap) / columns;

              return Wrap(
                spacing: gap,
                runSpacing: 5,
                children: List.generate(capacity, (index) {
                  final occupied = index < quantity;
                  return AnimatedContainer(
                    key: ValueKey('bed-slot-$index'),
                    duration: const Duration(milliseconds: 160),
                    width: slotWidth,
                    height: 13,
                    decoration: BoxDecoration(
                      color: occupied ? catalogOrange : const Color(0xFF2B2B30),
                      border: Border.all(
                        color: occupied
                            ? const Color(0xFFFF8B38)
                            : const Color(0xFF3B3B42),
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _QuantitySelector extends StatelessWidget {
  const _QuantitySelector({
    required this.productId,
    required this.quantity,
    required this.canDecrement,
    required this.canIncrement,
    required this.onDecrement,
    required this.onIncrement,
  });

  final String productId;
  final int quantity;
  final bool canDecrement;
  final bool canIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: catalogSurfaceRaised.withValues(alpha: 0.72),
        border: Border.all(color: catalogBorder),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: [
          const Text(
            'Quantidade:',
            style: TextStyle(
              color: catalogTextPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          _QuantityButton(
            key: ValueKey('decrement-$productId'),
            icon: Icons.remove,
            onPressed: canDecrement ? onDecrement : null,
          ),
          SizedBox(
            width: 44,
            child: Text(
              '$quantity',
              key: ValueKey('quantity-$productId'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: catalogOrange,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _QuantityButton(
            key: ValueKey('increment-$productId'),
            icon: Icons.add,
            onPressed: canIncrement ? onIncrement : null,
          ),
        ],
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({
    required this.icon,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 34,
      child: IconButton(
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          foregroundColor: catalogTextPrimary,
          disabledForegroundColor: catalogTextMuted.withValues(alpha: 0.32),
          side: const BorderSide(color: catalogBorder),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        iconSize: 17,
        icon: Icon(icon),
      ),
    );
  }
}

class _ValueRow extends StatelessWidget {
  const _ValueRow({
    required this.label,
    required this.value,
    this.badge,
    this.valueIcon,
  });

  final String label;
  final String value;
  final String? badge;
  final IconData? valueIcon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: catalogTextMuted, fontSize: 12),
          ),
        ),
        if (badge != null) ...[
          Container(
            margin: const EdgeInsets.only(right: 7),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: catalogGreen.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              badge!,
              style: const TextStyle(
                color: Color(0xFF20D997),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
        if (valueIcon != null) ...[
          Icon(valueIcon, color: catalogOrange, size: 15),
          const SizedBox(width: 4),
        ],
        Text(
          value,
          style: const TextStyle(
            color: catalogTextPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
