import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

@immutable
class DashboardModule {
  const DashboardModule({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.badge,
    required this.accentColor,
    this.navigationLabel,
    this.route,
    this.isAvailable = true,
  }) : assert(
         !isAvailable || route != null,
         'Módulos disponíveis precisam declarar uma rota.',
       );

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final String badge;
  final Color accentColor;
  final String? navigationLabel;
  final String? route;
  final bool isAvailable;

  bool get canNavigate => isAvailable && route != null;

  String get resolvedNavigationLabel => navigationLabel ?? title;
}

/// Fonte única para os módulos exibidos no Dashboard.
///
/// Para adicionar uma ferramenta, inclua uma nova instância nesta lista com a
/// rota correspondente. O grid ajusta automaticamente a quantidade de cards.
const dashboardModules = <DashboardModule>[
  DashboardModule(
    id: 'calculadora',
    title: 'Calculadora de Custos',
    description:
        'Precifique peças 3D considerando filamento, tempo de impressão, depreciação e margem de lucro.',
    icon: Icons.calculate_outlined,
    badge: 'Essencial',
    accentColor: AppColors.brand,
    navigationLabel: 'Calculadora',
    route: '/calculadora',
  ),
  DashboardModule(
    id: 'catalogo',
    title: 'Catálogo de Produtos',
    description:
        'Gerencie produtos com cálculo de mesa cheia, otimização de lotes e exportação de orçamentos.',
    icon: Icons.view_in_ar_outlined,
    badge: 'Otimizado',
    accentColor: AppColors.catalogSuccess,
    navigationLabel: 'Catálogo & Mesa',
    route: '/catalogo',
  ),
  DashboardModule(
    id: 'conta',
    title: 'Acesso & Conta',
    description:
        'Consulte seu perfil do laboratório, preferências da conta e o status da sua sessão.',
    icon: Icons.manage_accounts_outlined,
    badge: 'Configuração',
    accentColor: AppColors.brandLight,
    navigationLabel: 'Perfil / Acesso',
    route: '/perfil',
  ),
  DashboardModule(
    id: 'novo-modulo',
    title: 'Novo Módulo Em Breve',
    description:
        'Estrutura pronta para Filamentos, Orçamentos Salvos e Relatórios de Vendas.',
    icon: Icons.add_rounded,
    badge: 'Em breve',
    accentColor: AppColors.textMuted,
    isAvailable: false,
  ),
];
