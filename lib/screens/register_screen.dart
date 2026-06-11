import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../services/auth_service.dart';
import '../widgets/custom_snackbar.dart';
import '../widgets/page_transition.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const Color bg = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF0A0A0A);
  static const Color inkSoft = Color(0xFF6B6B6B);
  static const Color line = Color(0xFFEAEAEA);

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _termsAccepted = false;

  final _phoneMask = MaskTextInputFormatter(
    mask: '+7 (###) ###-##-##',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  @override
  void initState() {
    super.initState();
    for (final c in [
      _nameController,
      _emailController,
      _phoneController,
      _passwordController,
      _confirmPasswordController,
    ]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  double get _passwordStrength {
    final p = _passwordController.text;
    if (p.isEmpty) return 0;
    int score = 0;
    if (p.length >= 6) score++;
    if (p.length >= 10) score++;
    if (RegExp(r'[A-Z]').hasMatch(p)) score++;
    if (RegExp(r'[0-9]').hasMatch(p)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(p)) score++;
    return (score / 5).clamp(0.0, 1.0);
  }

  String get _passwordLabel {
    final s = _passwordStrength;
    if (s == 0) return '';
    if (s < 0.4) return 'Слабый';
    if (s < 0.7) return 'Средний';
    return 'Надёжный';
  }

  Color get _passwordColor {
    final s = _passwordStrength;
    if (s < 0.4) return const Color(0xFFFF3B30);
    if (s < 0.7) return const Color(0xFFFFAA00);
    return const Color(0xFF00B26A);
  }

  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final pass = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (name.isEmpty || email.isEmpty || pass.isEmpty || confirm.isEmpty) {
      CustomSnackbar.error(context, 'Заполните все обязательные поля');
      return;
    }
    if (name.length < 2) {
      CustomSnackbar.error(context, 'Слишком короткое имя');
      return;
    }
    if (!RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$').hasMatch(email)) {
      CustomSnackbar.error(context, 'Неверный формат email');
      return;
    }
    if (pass.length < 6) {
      CustomSnackbar.error(context, 'Пароль должен быть не менее 6 символов');
      return;
    }
    if (pass != confirm) {
      CustomSnackbar.error(context, 'Пароли не совпадают');
      return;
    }
    if (!_termsAccepted) {
      CustomSnackbar.error(context, 'Подтвердите согласие с условиями');
      return;
    }

    setState(() => _isLoading = true);
    final auth = context.read<AuthService>();
    final ok = await auth.register(
      email: email,
      password: pass,
      name: name,
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (ok) {
      CustomSnackbar.success(context, 'Аккаунт создан');
      Navigator.pushAndRemoveUntil(
        context,
        CircleRevealPageRoute(
          page: const HomeScreen(),
          color: ink,
          icon: Icons.home_rounded,
        ),
        (_) => false,
      );
    } else {
      CustomSnackbar.error(context, 'Этот email уже зарегистрирован');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 28),
              _buildHero(),
              const SizedBox(height: 28),
              _buildLabel('Имя'),
              const SizedBox(height: 8),
              _buildField(
                controller: _nameController,
                hint: 'Как к вам обращаться',
                icon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: 16),
              _buildLabel('Email'),
              const SizedBox(height: 8),
              _buildField(
                controller: _emailController,
                hint: 'name@example.com',
                icon: Icons.alternate_email_rounded,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              _buildLabelRow('Телефон', 'необязательно'),
              const SizedBox(height: 8),
              _buildField(
                controller: _phoneController,
                hint: '+7 (___) ___-__-__',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                formatters: [_phoneMask],
              ),
              const SizedBox(height: 16),
              _buildLabel('Пароль'),
              const SizedBox(height: 8),
              _buildField(
                controller: _passwordController,
                hint: 'Минимум 6 символов',
                icon: Icons.lock_outline_rounded,
                obscure: _obscurePassword,
                suffix: GestureDetector(
                  onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                  child: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 18,
                    color: inkSoft,
                  ),
                ),
              ),
              if (_passwordController.text.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildPasswordStrength(),
              ],
              const SizedBox(height: 16),
              _buildLabel('Повторите пароль'),
              const SizedBox(height: 8),
              _buildField(
                controller: _confirmPasswordController,
                hint: 'Введите пароль ещё раз',
                icon: Icons.shield_outlined,
                obscure: _obscureConfirmPassword,
                suffix: GestureDetector(
                  onTap: () =>
                      setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  child: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 18,
                    color: inkSoft,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildTermsCheckbox(),
              const SizedBox(height: 24),
              _buildSubmitButton(),
              const SizedBox(height: 16),
              _buildOrDivider(),
              const SizedBox(height: 16),
              _buildLoginButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.maybePop(context),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: surface,
              shape: BoxShape.circle,
              border: Border.all(color: line, width: 1),
            ),
            child: const Icon(Icons.arrow_back_rounded, size: 20, color: ink),
          ),
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildHero() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: ink,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.bolt_rounded, color: surface, size: 28),
        ),
        const SizedBox(height: 24),
        const Text(
          'Создать аккаунт',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: ink,
            height: 1.05,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Несколько шагов до первого заказа',
          style: TextStyle(fontSize: 14, color: inkSoft, height: 1.4),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: inkSoft,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildLabelRow(String text, String sub) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildLabel(text),
        const SizedBox(width: 8),
        Text(
          sub,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: inkSoft,
          ),
        ),
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboardType,
    List<TextInputFormatter>? formatters,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      inputFormatters: formatters,
      cursorColor: ink,
      style: const TextStyle(
        fontSize: 14,
        color: ink,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.2,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: inkSoft, fontSize: 14, fontWeight: FontWeight.w400),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 16, right: 12),
          child: Icon(icon, size: 18, color: inkSoft),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        suffixIcon: suffix == null
            ? null
            : Padding(
                padding: const EdgeInsets.only(right: 14),
                child: suffix,
              ),
        suffixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 24),
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: _border(line),
        enabledBorder: _border(line),
        focusedBorder: _border(ink, width: 1.5),
      ),
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  Widget _buildPasswordStrength() {
    final strength = _passwordStrength;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: Stack(
            children: [
              Container(height: 4, color: line),
              FractionallySizedBox(
                widthFactor: strength,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: _passwordColor,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _passwordLabel,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _passwordColor,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildTermsCheckbox() {
    return GestureDetector(
      onTap: () => setState(() => _termsAccepted = !_termsAccepted),
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 20,
            height: 20,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(
              color: _termsAccepted ? ink : surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _termsAccepted ? ink : line,
                width: 1.4,
              ),
            ),
            child: _termsAccepted
                ? const Icon(Icons.check_rounded, size: 14, color: surface)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 12, color: inkSoft, height: 1.4),
                children: [
                  TextSpan(text: 'Регистрируясь, вы соглашаетесь с '),
                  TextSpan(
                    text: 'Условиями использования',
                    style: TextStyle(
                      color: ink,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      decorationThickness: 1.4,
                    ),
                  ),
                  TextSpan(text: ' и '),
                  TextSpan(
                    text: 'Политикой',
                    style: TextStyle(
                      color: ink,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      decorationThickness: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    final canSubmit = _nameController.text.trim().isNotEmpty &&
        _emailController.text.trim().isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        _confirmPasswordController.text.isNotEmpty &&
        _termsAccepted &&
        !_isLoading;
    return GestureDetector(
      onTap: canSubmit ? _handleRegister : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: canSubmit ? ink : line,
          borderRadius: BorderRadius.circular(16),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(color: surface, strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Создать аккаунт',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: canSubmit ? surface : inkSoft,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.arrow_forward_rounded,
                      size: 16, color: canSubmit ? surface : inkSoft),
                ],
              ),
      ),
    );
  }

  Widget _buildOrDivider() {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: line)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'или',
            style: TextStyle(fontSize: 11, color: inkSoft, fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(child: Container(height: 1, color: line)),
      ],
    );
  }

  Widget _buildLoginButton() {
    return GestureDetector(
      onTap: () => Navigator.pushReplacement(
        context,
        CircleRevealPageRoute(
          page: const LoginScreen(),
          color: ink,
          icon: Icons.login_rounded,
        ),
      ),
      child: Container(
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: line, width: 1),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Войти в существующий',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: ink,
                letterSpacing: -0.2,
              ),
            ),
            SizedBox(width: 6),
            Icon(Icons.arrow_outward_rounded, size: 16, color: ink),
          ],
        ),
      ),
    );
  }
}
