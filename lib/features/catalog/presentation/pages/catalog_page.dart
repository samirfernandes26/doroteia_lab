import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/catalog_product.dart';
import '../catalog_colors.dart';
import '../providers/catalog_provider.dart';
import '../services/catalog_quote_formatter.dart';
import '../widgets/catalog_product_card.dart';
import '../widgets/product_form_dialog.dart';

class CatalogPage extends ConsumerStatefulWidget {
  const CatalogPage({super.key});

  @override
  ConsumerState<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends ConsumerState<CatalogPage> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(catalogProvider).searchQuery,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openProductForm([CatalogProduct? product]) async {
    final result = await showProductFormDialog(context, product: product);
    if (result == null || !mounted) return;

    try {
      await ref.read(catalogProvider.notifier).saveProduct(result);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            product == null
                ? 'Produto cadastrado no catálogo.'
                : 'Produto atualizado com sucesso.',
          ),
        ),
      );
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível salvar o produto.')),
      );
    }
  }

  Future<void> _deleteProduct(CatalogProduct product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.82),
      builder: (context) => AlertDialog(
        backgroundColor: catalogSurface,
        title: const Text(
          'Excluir produto?',
          style: TextStyle(color: catalogTextPrimary),
        ),
        content: Text(
          'O produto “${product.name}” será removido do catálogo.',
          style: const TextStyle(color: catalogTextMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFC93439),
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    try {
      await ref.read(catalogProvider.notifier).deleteProduct(product.id);
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível excluir o produto.')),
      );
    }
  }

  Future<void> _shareOnWhatsApp(CatalogProduct product, int quantity) async {
    final messenger = ScaffoldMessenger.of(context);
    final uri = Uri.https('wa.me', '/', {
      'text': formatCatalogQuote(product, quantity),
    });

    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o WhatsApp.')),
        );
      }
    } on PlatformException {
      messenger.showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o WhatsApp.')),
      );
    }
  }

  Future<void> _openProject(CatalogProduct product) async {
    final messenger = ScaffoldMessenger.of(context);
    final uri = Uri.tryParse(product.projectUrl.trim());
    final isSupported =
        uri != null && (uri.scheme == 'http' || uri.scheme == 'https');

    if (!isSupported) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Link do projeto inválido.')),
      );
      return;
    }

    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o projeto 3D.')),
        );
      }
    } on PlatformException {
      messenger.showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o projeto 3D.')),
      );
    }
  }

  Future<void> _signOut() async {
    await ref.read(authControllerProvider.notifier).signOut();
    if (!mounted) return;

    final result = ref.read(authControllerProvider);
    if (result.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível sair: ${result.error}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(catalogProvider);
    final controller = ref.read(catalogProvider.notifier);
    final authAction = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: catalogBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _CatalogHeader(
              isSigningOut: authAction.isLoading,
              onAddProduct: _openProductForm,
              onBackToDashboard: () => context.go('/home'),
              onOpenCalculator: () => context.go('/calculadora'),
              onSignOut: _signOut,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 26, 20, 52),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1280),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _CatalogToolbar(
                          searchController: _searchController,
                          onSearchChanged: controller.setSearchQuery,
                        ),
                        const SizedBox(height: 28),
                        if (catalog.isLoading)
                          const Padding(
                            padding: EdgeInsets.only(top: 100),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: catalogOrange,
                              ),
                            ),
                          )
                        else if (catalog.filteredProducts.isEmpty)
                          _EmptyCatalog(
                            hasSearch: catalog.searchQuery.trim().isNotEmpty,
                            onAddProduct: _openProductForm,
                          )
                        else
                          _ProductGrid(
                            products: catalog.filteredProducts,
                            state: catalog,
                            controller: controller,
                            onEdit: _openProductForm,
                            onDelete: _deleteProduct,
                            onOpenProject: _openProject,
                            onWhatsApp: _shareOnWhatsApp,
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

class _CatalogHeader extends StatelessWidget {
  const _CatalogHeader({
    required this.isSigningOut,
    required this.onAddProduct,
    required this.onBackToDashboard,
    required this.onOpenCalculator,
    required this.onSignOut,
  });

  final bool isSigningOut;
  final VoidCallback onAddProduct;
  final VoidCallback onBackToDashboard;
  final VoidCallback onOpenCalculator;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.header,
        border: Border(bottom: BorderSide(color: catalogBorder)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 700;
                final brand = const _CatalogBrand();
                final actions = Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: onBackToDashboard,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: catalogTextPrimary,
                        side: const BorderSide(color: catalogBorder),
                      ),
                      icon: const Icon(Icons.arrow_back_rounded, size: 18),
                      label: Text(
                        compact ? 'Dashboard' : 'Voltar ao Dashboard',
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: onOpenCalculator,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: catalogTextMuted,
                        side: const BorderSide(color: catalogBorder),
                      ),
                      icon: const Icon(Icons.calculate_outlined, size: 18),
                      label: Text(
                        compact ? 'Calculadora' : 'Ir para Calculadora',
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: onAddProduct,
                      style: FilledButton.styleFrom(
                        backgroundColor: catalogOrange,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.add_rounded, size: 19),
                      label: const Text('Cadastrar Produto'),
                    ),
                    IconButton(
                      tooltip: 'Sair',
                      onPressed: isSigningOut ? null : onSignOut,
                      color: catalogTextMuted,
                      icon: isSigningOut
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(
                                color: catalogOrange,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.logout_rounded, size: 20),
                    ),
                  ],
                );

                if (compact) {
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

class _CatalogBrand extends StatelessWidget {
  const _CatalogBrand();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const details = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: 'Doroteia '),
                  TextSpan(
                    text: 'Lab',
                    style: TextStyle(color: catalogOrange),
                  ),
                ],
              ),
              style: TextStyle(
                color: catalogTextPrimary,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Catálogo & Otimizador de Impressão por Mesa (3 Pontos)',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: catalogTextMuted, fontSize: 11),
            ),
          ],
        );
        final hasBoundedWidth = constraints.hasBoundedWidth;

        return Row(
          mainAxisSize: hasBoundedWidth ? MainAxisSize.max : MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 24,
              backgroundColor: catalogOrange,
              child: Text(
                'DL',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
            if (hasBoundedWidth) Expanded(child: details) else details,
          ],
        );
      },
    );
  }
}

class _CatalogToolbar extends StatelessWidget {
  const _CatalogToolbar({
    required this.searchController,
    required this.onSearchChanged,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: catalogSurface,
        border: Border.all(color: catalogBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final search = SizedBox(
            width: constraints.maxWidth >= 760 ? 430 : double.infinity,
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              cursorColor: catalogOrange,
              style: const TextStyle(color: catalogTextPrimary, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Buscar produto no catálogo...',
                hintStyle: const TextStyle(color: catalogTextMuted),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: catalogTextMuted,
                  size: 20,
                ),
                filled: true,
                fillColor: catalogSurfaceRaised,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 13),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: catalogBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: catalogOrange),
                ),
              ),
            ),
          );
          const status = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle, color: catalogFullGreen, size: 9),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Interpolação de 3 Pontos (1 Unidade → Mesa Média → Mesa Cheia)',
                  textAlign: TextAlign.end,
                  style: TextStyle(color: catalogTextMuted, fontSize: 12),
                ),
              ),
            ],
          );

          if (constraints.maxWidth < 760) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [search, const SizedBox(height: 14), status],
            );
          }
          return Row(
            children: [
              search,
              const SizedBox(width: 24),
              Expanded(
                child: Align(alignment: Alignment.centerRight, child: status),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProductGrid extends StatelessWidget {
  const _ProductGrid({
    required this.products,
    required this.state,
    required this.controller,
    required this.onEdit,
    required this.onDelete,
    required this.onOpenProject,
    required this.onWhatsApp,
  });

  final List<CatalogProduct> products;
  final CatalogState state;
  final CatalogController controller;
  final ValueChanged<CatalogProduct> onEdit;
  final ValueChanged<CatalogProduct> onDelete;
  final ValueChanged<CatalogProduct> onOpenProject;
  final void Function(CatalogProduct, int) onWhatsApp;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1080
            ? 3
            : constraints.maxWidth >= 700
            ? 2
            : 1;
        const spacing = 24.0;
        final cardWidth =
            (constraints.maxWidth - (columns - 1) * spacing) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: products
              .map((product) {
                final quantity = state.quantityFor(product);
                return SizedBox(
                  width: cardWidth,
                  child: CatalogProductCard(
                    product: product,
                    quantity: quantity,
                    onIncrement: () => controller.incrementQuantity(product.id),
                    onDecrement: () => controller.decrementQuantity(product.id),
                    onEdit: () => onEdit(product),
                    onDelete: () => onDelete(product),
                    onOpenProject: product.projectUrl.trim().isEmpty
                        ? null
                        : () => onOpenProject(product),
                    onWhatsApp: () => onWhatsApp(product, quantity),
                  ),
                );
              })
              .toList(growable: false),
        );
      },
    );
  }
}

class _EmptyCatalog extends StatelessWidget {
  const _EmptyCatalog({required this.hasSearch, required this.onAddProduct});

  final bool hasSearch;
  final VoidCallback onAddProduct;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 72),
      decoration: BoxDecoration(
        color: catalogSurface,
        border: Border.all(color: catalogBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            color: catalogTextMuted,
            size: 44,
          ),
          const SizedBox(height: 16),
          Text(
            hasSearch
                ? 'Nenhum produto encontrado'
                : 'Seu catálogo ainda está vazio',
            style: const TextStyle(
              color: catalogTextPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            hasSearch
                ? 'Tente buscar por outro nome.'
                : 'Cadastre o primeiro produto para otimizar seus lotes.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: catalogTextMuted, fontSize: 13),
          ),
          if (!hasSearch) ...[
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: onAddProduct,
              style: FilledButton.styleFrom(backgroundColor: catalogOrange),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Cadastrar Produto'),
            ),
          ],
        ],
      ),
    );
  }
}
