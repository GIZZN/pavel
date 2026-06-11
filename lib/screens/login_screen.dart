import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../widgets/custom_snackbar.dart';
import '../widgets/page_transition.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const Color bg = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF0A0A0A);
  static const Color inkSoft = Color(0xFF6B6B6B);
  static const Color line = Color(0xFFEAEAEA);

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(() => setState(() {}));
    _passwordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final pass = _passwordController.text;
    if (email.isEmpty || pass.isEmpty) {
      CustomSnackbar.error(context, 'Заполните все поля');
      return;
    }
    if (!RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$').hasMatch(email)) {
      CustomSnackbar.error(context, 'Неверный формат email');
      return;
    }

    setState(() => _isLoading = true);
    final auth = context.read<AuthService>();
    final ok = await auth.login(email: email, password: pass);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (ok) {
      CustomSnackbar.success(context, 'Добро пожаловать');
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
      CustomSnackbar.error(context, 'Неверный email или пароль');
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
              const SizedBox(height: 32),
              _buildHero(),
              const SizedBox(height: 32),
              _buildLabel('Email'),
              const SizedBox(height: 8),
              _buildField(
                controller: _emailController,
                hint: 'name@example.com',
                icon: Icons.alternate_email_rounded,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildLabel('Пароль'),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      CircleRevealPageRoute(
                        page: const ForgotPasswordScreen(),
                        color: ink,
                        icon: Icons.lock_reset_rounded,
                      ),
                    ),
                    child: const Text(
                      'Забыли пароль?',
                      style: TextStyle(
                        fontSize: 12,
                        color: ink,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                        decorationThickness: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildField(
                controller: _passwordController,
                hint: 'Минимум 6 символов',
                icon: Icons.lock_outline_rounded,
                obscure: _obscurePassword,
                suffix: GestureDetector(
                  onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                  child: Icon(
                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: 18,
                    color: inkSoft,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              _buildSubmitButton(),
              const SizedBox(height: 16),
              _buildOrDivider(),
              const SizedBox(height: 16),
              _buildRegisterButton(),
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
          'С возвращением',
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
          'Войдите, чтобы продолжить покупки',
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

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
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

  Widget _buildSubmitButton() {
    final canSubmit = _emailController.text.trim().isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        !_isLoading;
    return GestureDetector(
      onTap: canSubmit ? _handleLogin : null,
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
                    'Войти',
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

  Widget _buildRegisterButton() {
    return GestureDetector(
      onTap: () => Navigator.pushReplacement(
        context,
        CircleRevealPageRoute(
          page: const RegisterScreen(),
          color: ink,
          icon: Icons.person_add_outlined,
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
              'Создать аккаунт',
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
