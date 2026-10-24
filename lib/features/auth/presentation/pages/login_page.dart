import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/auth_providers.dart';

const _orange = AppColors.brand;
const _ink = AppColors.lightInk;
const _muted = AppColors.lightMuted;
const _fieldBorder = AppColors.fieldBorder;
const _fieldFill = AppColors.fieldFill;

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit({required bool createAccount}) async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    final controller = ref.read(authControllerProvider.notifier);
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (createAccount) {
      await controller.signUp(email: email, password: password);
    } else {
      await controller.signIn(email: email, password: password);
    }

    if (!mounted) return;

    final result = ref.read(authControllerProvider);
    if (createAccount && !result.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conta criada com sucesso.')),
      );
    }
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Informe seu e-mail';
    if (!email.contains('@') || !email.contains('.')) {
      return 'Informe um e-mail válido';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Informe sua senha';
    if (value.length < 8) return 'A senha deve ter pelo menos 8 caracteres';
    return null;
  }

  String _readableError(Object error) {
    final message = error.toString().replaceFirst(
      RegExp(r'^Exception:\s*'),
      '',
    );
    return message.isEmpty ? 'Não foi possível concluir a operação.' : message;
  }

  void _showForgotPasswordMessage() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Entre em contato com o administrador para redefinir sua senha.',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final authAction = ref.watch(authControllerProvider);
    final isLoading = authAction.isLoading;
    final error = authAction.hasError ? authAction.error : null;

    final formPanel = _LoginFormPanel(
      formKey: _formKey,
      emailController: _emailController,
      passwordController: _passwordController,
      obscurePassword: _obscurePassword,
      isLoading: isLoading,
      errorMessage: error == null ? null : _readableError(error),
      validateEmail: _validateEmail,
      validatePassword: _validatePassword,
      onTogglePassword: () {
        setState(() => _obscurePassword = !_obscurePassword);
      },
      onForgotPassword: _showForgotPasswordMessage,
      onSignIn: () => _submit(createAccount: false),
      onSignUp: () => _submit(createAccount: true),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 800) return formPanel;

          return Row(
            children: [
              const Expanded(child: _BrandPanel()),
              Expanded(child: formPanel),
            ],
          );
        },
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF08090B),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0D0F11), Color(0xFF050607)],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(1.05, -1.0),
                radius: 1.15,
                colors: [_orange.withValues(alpha: 0.10), Colors.transparent],
                stops: const [0, 1],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-1.0, 1.0),
                radius: 1.2,
                colors: [_orange.withValues(alpha: 0.08), Colors.transparent],
                stops: const [0, 1],
              ),
            ),
          ),
          const IgnorePointer(
            child: CustomPaint(painter: _DotPatternPainter()),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 40,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _BrandLogo(),
                      const SizedBox(height: 28),
                      Text.rich(
                        const TextSpan(
                          children: [
                            TextSpan(text: 'Inovação em '),
                            TextSpan(
                              text: '3D',
                              style: TextStyle(color: _orange),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          height: 1.15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.2,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Acesse o laboratório para gerenciar seus projetos, '
                        'impressões e transformar suas ideias em realidade.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFFAEB8C8),
                          fontSize: 16,
                          height: 1.55,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandLogo extends StatelessWidget {
  const _BrandLogo();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: _orange.withValues(alpha: 0.12),
            border: Border.all(color: _orange.withValues(alpha: 0.55)),
            borderRadius: BorderRadius.circular(9),
          ),
          child: const Icon(
            Icons.view_in_ar_outlined,
            color: _orange,
            size: 21,
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'Doroteia Lab',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

class _LoginFormPanel extends StatelessWidget {
  const _LoginFormPanel({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.isLoading,
    required this.errorMessage,
    required this.validateEmail,
    required this.validatePassword,
    required this.onTogglePassword,
    required this.onForgotPassword,
    required this.onSignIn,
    required this.onSignUp,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool isLoading;
  final String? errorMessage;
  final FormFieldValidator<String> validateEmail;
  final FormFieldValidator<String> validatePassword;
  final VoidCallback onTogglePassword;
  final VoidCallback onForgotPassword;
  final VoidCallback onSignIn;
  final VoidCallback onSignUp;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            const horizontalPadding = 24.0;
            const verticalPadding = 32.0;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - (verticalPadding * 2),
                ),
                child: Center(
                  child: SizedBox(
                    width: 400,
                    child: AutofillGroup(
                      child: Form(
                        key: formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Bem-vindo de volta!',
                              style: TextStyle(
                                color: _ink,
                                fontSize: 27,
                                height: 1.2,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.6,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Insira suas credenciais para acessar o painel.',
                              style: TextStyle(
                                color: _muted,
                                fontSize: 14,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 32),
                            const _FieldLabel('E-mail'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: emailController,
                              enabled: !isLoading,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [
                                AutofillHints.username,
                                AutofillHints.email,
                              ],
                              autocorrect: false,
                              validator: validateEmail,
                              style: const TextStyle(color: _ink, fontSize: 14),
                              decoration: _fieldDecoration(
                                hintText: 'seu@email.com',
                                prefixIcon: Icons.mail_outline_rounded,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const _FieldLabel('Senha'),
                                TextButton(
                                  onPressed: isLoading
                                      ? null
                                      : onForgotPassword,
                                  style: TextButton.styleFrom(
                                    foregroundColor: _orange,
                                    disabledForegroundColor: _orange.withValues(
                                      alpha: 0.45,
                                    ),
                                    minimumSize: Size.zero,
                                    padding: EdgeInsets.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    textStyle: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  child: const Text('Esqueceu a senha?'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: passwordController,
                              enabled: !isLoading,
                              obscureText: obscurePassword,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.password],
                              validator: validatePassword,
                              onFieldSubmitted: isLoading
                                  ? null
                                  : (_) => onSignIn(),
                              style: const TextStyle(color: _ink, fontSize: 14),
                              decoration: _fieldDecoration(
                                hintText: '••••••••',
                                prefixIcon: Icons.lock_outline_rounded,
                                suffixIcon: IconButton(
                                  tooltip: obscurePassword
                                      ? 'Mostrar senha'
                                      : 'Ocultar senha',
                                  onPressed: isLoading
                                      ? null
                                      : onTogglePassword,
                                  icon: Icon(
                                    obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                            if (errorMessage != null) ...[
                              const SizedBox(height: 16),
                              _ErrorMessage(errorMessage!),
                            ],
                            const SizedBox(height: 22),
                            SizedBox(
                              height: 52,
                              child: FilledButton(
                                onPressed: isLoading ? null : onSignIn,
                                style: FilledButton.styleFrom(
                                  backgroundColor: _orange,
                                  disabledBackgroundColor: _orange.withValues(
                                    alpha: 0.55,
                                  ),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 2,
                                  shadowColor: _orange.withValues(alpha: 0.28),
                                  textStyle: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                child: isLoading
                                    ? const SizedBox.square(
                                        dimension: 21,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.4,
                                        ),
                                      )
                                    : const Text('Entrar no Sistema'),
                              ),
                            ),
                            const SizedBox(height: 28),
                            const _SectionDivider(),
                            const SizedBox(height: 20),
                            Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                const Text(
                                  'Ainda não possui acesso?',
                                  style: TextStyle(color: _muted, fontSize: 13),
                                ),
                                TextButton(
                                  onPressed: isLoading ? null : onSignUp,
                                  style: TextButton.styleFrom(
                                    foregroundColor: _orange,
                                    disabledForegroundColor: _orange.withValues(
                                      alpha: 0.45,
                                    ),
                                    minimumSize: Size.zero,
                                    padding: const EdgeInsets.only(left: 5),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    textStyle: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  child: const Text('Criar uma conta'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: _ink,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F0),
        border: Border.all(color: const Color(0xFFFFCCC7)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFB42318), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFB42318),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider(color: Color(0xFFE4E7EC), height: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'Novo por aqui?',
            style: TextStyle(color: _muted, fontSize: 12),
          ),
        ),
        Expanded(child: Divider(color: Color(0xFFE4E7EC), height: 1)),
      ],
    );
  }
}

InputDecoration _fieldDecoration({
  required String hintText,
  required IconData prefixIcon,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: const TextStyle(color: Color(0xFF98A2B3), fontSize: 14),
    prefixIcon: Icon(prefixIcon, color: const Color(0xFF98A2B3), size: 20),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: _fieldFill,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: _fieldBorder),
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFE4E7EC)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: _orange, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFD92D20)),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFD92D20), width: 1.5),
    ),
  );
}

class _DotPatternPainter extends CustomPainter {
  const _DotPatternPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.035);

    const spacing = 20.0;
    for (double x = 10; x < size.width; x += spacing) {
      for (double y = 10; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 0.75, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
