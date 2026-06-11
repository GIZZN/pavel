import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/database_service.dart';
import '../services/email_service.dart';
import '../services/notification_service.dart';
import '../widgets/custom_snackbar.dart';
import '../widgets/page_transition.dart';
import 'reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  static const Color bg = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF0A0A0A);
  static const Color inkSoft = Color(0xFF6B6B6B);
  static const Color line = Color(0xFFEAEAEA);

  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSendCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      CustomSnackbar.error(context, 'Введите email');
      return;
    }
    if (!RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$').hasMatch(email)) {
      CustomSnackbar.error(context, 'Неверный формат email');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final code = await DatabaseService.instance.createPasswordResetCode(email);
      if (code == null) {
        if (mounted) {
          setState(() => _isLoading = false);
          CustomSnackbar.error(context, 'Пользователь с таким email не найден');
        }
        return;
      }

      // Push-уведомление с кодом (silent fail).
      try {
        await NotificationService.showPasswordResetNotification(code);
      } catch (_) {}

      // Email в фоне.
      EmailService.sendPasswordResetEmail(
        toEmail: email,
        userName: 'Пользователь',
        resetCode: code,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);
      _showCodeSheet(code);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      CustomSnackbar.error(context, 'Произошла ошибка');
    }
  }

  void _showCodeSheet(String code) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: line,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Код восстановления',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: ink,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Действителен 15 минут',
                  style: TextStyle(fontSize: 13, color: inkSoft),
                ),
                const SizedBox(height: 24),
                // Цифры кода в отдельных ячейках
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(code.length, (i) {
                    return Padding(
                      padding: EdgeInsets.only(right: i == code.length - 1 ? 0 : 6),
                      child: Container(
                        width: 44,
                        height: 56,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: line, width: 1),
                        ),
                        child: Text(
                          code[i],
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: ink,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: code));
                    CustomSnackbar.success(context, 'Код скопирован');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: line),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.copy_rounded, size: 14, color: ink),
                        SizedBox(width: 6),
                        Text(
                          'Скопировать код',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      CircleRevealPageRoute(
                        page: ResetPasswordScreen(email: _emailController.text.trim()),
                        color: ink,
                        icon: Icons.lock_reset_rounded,
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: ink,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Ввести код',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: surface,
                            letterSpacing: -0.2,
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(Icons.arrow_forward_rounded, size: 16, color: surface),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: Container(
                    width: double.infinity,
                    height: 48,
                    alignment: Alignment.center,
                    child: const Text(
                      'Отмена',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: inkSoft,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
              _buildField(),
              const SizedBox(height: 28),
              _buildSubmitButton(),
              const SizedBox(height: 24),
              _buildHint(),
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
          child: const Icon(Icons.lock_reset_rounded, color: surface, size: 26),
        ),
        const SizedBox(height: 24),
        const Text(
          'Восстановление',
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
          'Введите email — пришлём код для сброса пароля',
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

  Widget _buildField() {
    return TextField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      cursorColor: ink,
      style: const TextStyle(
        fontSize: 14,
        color: ink,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.2,
      ),
      decoration: InputDecoration(
        hintText: 'name@example.com',
        hintStyle: const TextStyle(color: inkSoft, fontSize: 14, fontWeight: FontWeight.w400),
        prefixIcon: const Padding(
          padding: EdgeInsets.only(left: 16, right: 12),
          child: Icon(Icons.alternate_email_rounded, size: 18, color: inkSoft),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
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
    final canSubmit = _emailController.text.trim().isNotEmpty && !_isLoading;
    return GestureDetector(
      onTap: canSubmit ? _handleSendCode : null,
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
                    'Отправить код',
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

  Widget _buildHint() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: line),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline_rounded, size: 14, color: inkSoft),
            SizedBox(width: 6),
            Text(
              'Код придёт на email и в push',
              style: TextStyle(fontSize: 11, color: inkSoft, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
