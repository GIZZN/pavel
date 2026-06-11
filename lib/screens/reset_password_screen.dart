import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/database_service.dart';
import '../widgets/custom_snackbar.dart';
import '../widgets/page_transition.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  const ResetPasswordScreen({super.key, required this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  static const Color bg = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF0A0A0A);
  static const Color inkSoft = Color(0xFF6B6B6B);
  static const Color line = Color(0xFFEAEAEA);

  // 6 ячеек кода
  final _codeControllers = List.generate(6, (_) => TextEditingController());
  final _codeFocus = List.generate(6, (_) => FocusNode());

  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    for (final c in _codeControllers) {
      c.addListener(() => setState(() {}));
    }
    _passwordController.addListener(() => setState(() {}));
    _confirmController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    for (final c in _codeControllers) {
      c.dispose();
    }
    for (final f in _codeFocus) {
      f.dispose();
    }
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String get _code => _codeControllers.map((c) => c.text).join();

  Future<void> _handleReset() async {
    if (_code.length != 6) {
      CustomSnackbar.error(context, 'Введите 6-значный код');
      return;
    }
    if (_passwordController.text.isEmpty || _confirmController.text.isEmpty) {
      CustomSnackbar.error(context, 'Заполните пароль');
      return;
    }
    if (_passwordController.text.length < 6) {
      CustomSnackbar.error(context, 'Пароль должен быть не менее 6 символов');
      return;
    }
    if (_passwordController.text != _confirmController.text) {
      CustomSnackbar.error(context, 'Пароли не совпадают');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final userId = await DatabaseService.instance
          .verifyPasswordResetCode(widget.email, _code);
      if (userId == null) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        CustomSnackbar.error(context, 'Неверный или истёкший код');
        return;
      }

      final ok = await DatabaseService.instance
          .resetPassword(userId, _passwordController.text);
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (ok) {
        CustomSnackbar.success(context, 'Пароль изменён');
        Navigator.pushAndRemoveUntil(
          context,
          CircleRevealPageRoute(
            page: const LoginScreen(),
            color: ink,
            icon: Icons.login_rounded,
          ),
          (_) => false,
        );
      } else {
        CustomSnackbar.error(context, 'Не удалось изменить пароль');
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      CustomSnackbar.error(context, 'Произошла ошибка');
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
              _buildLabel('Код из письма'),
              const SizedBox(height: 8),
              _buildCodeRow(),
              const SizedBox(height: 24),
              _buildLabel('Новый пароль'),
              const SizedBox(height: 8),
              _buildPasswordField(
                controller: _passwordController,
                obscure: _obscurePass,
                onToggle: () => setState(() => _obscurePass = !_obscurePass),
                hint: 'Минимум 6 символов',
              ),
              const SizedBox(height: 16),
              _buildLabel('Повторите пароль'),
              const SizedBox(height: 8),
              _buildPasswordField(
                controller: _confirmController,
                obscure: _obscureConfirm,
                onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                hint: 'Введите пароль ещё раз',
              ),
              const SizedBox(height: 28),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return GestureDetector(
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
          child: const Icon(Icons.shield_outlined, color: surface, size: 26),
        ),
        const SizedBox(height: 24),
        const Text(
          'Новый пароль',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: ink,
            height: 1.05,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 6),
        RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 14, color: inkSoft, height: 1.4),
            children: [
              const TextSpan(text: 'Код отправлен на '),
              TextSpan(
                text: widget.email,
                style: const TextStyle(color: ink, fontWeight: FontWeight.w600),
              ),
            ],
          ),
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

  Widget _buildCodeRow() {
    return Row(
      children: List.generate(6, (i) {
        final isFilled = _codeControllers[i].text.isNotEmpty;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i == 5 ? 0 : 8),
            child: AspectRatio(
              aspectRatio: 1,
              child: TextField(
                controller: _codeControllers[i],
                focusNode: _codeFocus[i],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 1,
                cursorColor: ink,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: ink,
                  letterSpacing: -0.5,
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: isFilled ? bg : surface,
                  contentPadding: EdgeInsets.zero,
                  border: _border(line),
                  enabledBorder: _border(isFilled ? ink : line),
                  focusedBorder: _border(ink, width: 1.5),
                ),
                onChanged: (v) {
                  if (v.length == 1 && i < 5) {
                    _codeFocus[i + 1].requestFocus();
                  } else if (v.isEmpty && i > 0) {
                    _codeFocus[i - 1].requestFocus();
                  }
                  setState(() {});
                },
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
    required String hint,
  }) {
    return TextField(
      controller: controller,
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
        prefixIcon: const Padding(
          padding: EdgeInsets.only(left: 16, right: 12),
          child: Icon(Icons.lock_outline_rounded, size: 18, color: inkSoft),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        suffixIcon: Padding(
          padding: const EdgeInsets.only(right: 14),
          child: GestureDetector(
            onTap: onToggle,
            child: Icon(
              obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              size: 18,
              color: inkSoft,
            ),
          ),
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
    final canSubmit = _code.length == 6 &&
        _passwordController.text.isNotEmpty &&
        _confirmController.text.isNotEmpty &&
        !_isLoading;
    return GestureDetector(
      onTap: canSubmit ? _handleReset : null,
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
                    'Сохранить пароль',
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
}
