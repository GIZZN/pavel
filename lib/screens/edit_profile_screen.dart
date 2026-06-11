import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import '../services/auth_service.dart';
import '../widgets/custom_snackbar.dart';
import '../utils/image_helper.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;

  File? _imageFile;
  String? _base64Image;
  Uint8List? _cachedAvatar;
  bool _avatarRemoved = false;
  final ImagePicker _picker = ImagePicker();

  final _phoneMask = MaskTextInputFormatter(
    mask: '+7 (###) ###-##-##',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  static const Color bg = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF0A0A0A);
  static const Color inkSoft = Color(0xFF6B6B6B);
  static const Color line = Color(0xFFEAEAEA);
  static const Color danger = Color(0xFFFF3B30);

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    final user = context.read<AuthService>().currentUser;
    _nameController = TextEditingController(text: user?.name ?? '');

    String formattedPhone = '';
    if (user?.phone != null && user!.phone!.isNotEmpty) {
      final digitsOnly = user.phone!.replaceAll(RegExp(r'\D'), '');
      if (digitsOnly.length >= 10) {
        _phoneMask.formatEditUpdate(
          const TextEditingValue(),
          TextEditingValue(text: digitsOnly.substring(digitsOnly.length - 10)),
        );
        formattedPhone = _phoneMask.getMaskedText();
      }
    }
    _phoneController = TextEditingController(text: formattedPhone);

    if (user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty) {
      _cachedAvatar = ImageHelper.safeBase64Decode(user.avatarUrl);
    }

    _nameController.addListener(_onChange);
    _phoneController.addListener(_onChange);
  }

  void _onChange() => setState(() {});

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (picked != null) {
        final bytes = await File(picked.path).readAsBytes();
        setState(() {
          _imageFile = File(picked.path);
          _base64Image = base64Encode(bytes);
          _avatarRemoved = false;
        });
      }
    } catch (e) {
      if (mounted) CustomSnackbar.error(context, 'Ошибка: $e');
    }
  }

  void _openImageSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: line,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 20, 24, 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Фото профиля',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: ink,
                      letterSpacing: -0.4,
                    ),
                  ),
                ),
              ),
              _sheetItem(Icons.photo_library_outlined, 'Выбрать из галереи', () {
                Navigator.pop(ctx);
                _pick(ImageSource.gallery);
              }),
              _sheetItem(Icons.camera_alt_outlined, 'Сделать фото', () {
                Navigator.pop(ctx);
                _pick(ImageSource.camera);
              }),
              if (_imageFile != null || _cachedAvatar != null)
                _sheetItem(
                  Icons.delete_outline_rounded,
                  'Удалить фото',
                  () {
                    Navigator.pop(ctx);
                    setState(() {
                      _imageFile = null;
                      _base64Image = '';
                      _cachedAvatar = null;
                      _avatarRemoved = true;
                    });
                  },
                  destructive: true,
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetItem(IconData icon, String label, VoidCallback onTap, {bool destructive = false}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: destructive ? danger : ink),
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: destructive ? danger : ink,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthService>();

    final phoneText = _phoneController.text.trim();
    final phoneDigits = phoneText.replaceAll(RegExp(r'\D'), '');
    final cleanPhone = phoneDigits.isEmpty ? null : phoneText;

    String? avatarPayload;
    if (_avatarRemoved) {
      avatarPayload = '';
    } else if (_base64Image != null && _base64Image!.isNotEmpty) {
      avatarPayload = _base64Image;
    }

    final ok = await auth.updateProfile(
      name: _nameController.text.trim(),
      phone: cleanPhone,
      avatarUrl: avatarPayload,
    );

    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
      CustomSnackbar.success(context, 'Профиль обновлён');
    } else {
      CustomSnackbar.error(context, 'Не удалось обновить профиль');
    }
  }

  bool get _hasChanges {
    final user = context.read<AuthService>().currentUser;
    if (user == null) return false;
    if (_nameController.text.trim() != user.name) return true;
    final origPhone = user.phone ?? '';
    if (_phoneController.text.trim() != origPhone &&
        !(origPhone.isEmpty && _phoneController.text.replaceAll(RegExp(r'\D'), '').isEmpty)) {
      return true;
    }
    if (_imageFile != null) return true;
    if (_avatarRemoved && (user.avatarUrl?.isNotEmpty ?? false)) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.currentUser;
    final email = user?.email ?? '';

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(auth),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                  children: [
                    _buildAvatar(),
                    const SizedBox(height: 32),
                    _buildLabel('Имя'),
                    const SizedBox(height: 8),
                    _buildField(
                      controller: _nameController,
                      hint: 'Ваше имя',
                      icon: Icons.person_outline_rounded,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Введите имя';
                        if (v.trim().length < 2) return 'Слишком короткое имя';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildLabel('Телефон'),
                    const SizedBox(height: 8),
                    _buildField(
                      controller: _phoneController,
                      hint: '+7 (___) ___-__-__',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      formatters: [_phoneMask],
                    ),
                    const SizedBox(height: 20),
                    _buildLabel('Email'),
                    const SizedBox(height: 8),
                    _buildEmailField(email),
                    const SizedBox(height: 32),
                    _buildSaveButton(auth),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AuthService auth) {
    final canSave = _hasChanges && !auth.isLoading;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
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
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Редактирование',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: ink,
                letterSpacing: -0.4,
              ),
            ),
          ),
          GestureDetector(
            onTap: canSave ? _save : null,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: canSave ? 1 : 0.4,
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: ink,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: auth.isLoading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          color: surface,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Сохранить',
                        style: TextStyle(fontSize: 12, color: surface, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    Widget content;
    if (_imageFile != null) {
      content = Image.file(_imageFile!, fit: BoxFit.cover, width: 112, height: 112);
    } else if (_cachedAvatar != null) {
      content = Image.memory(_cachedAvatar!, fit: BoxFit.cover, width: 112, height: 112);
    } else {
      final initials = _initials(_nameController.text);
      content = Container(
        color: bg,
        alignment: Alignment.center,
        child: Text(
          initials,
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: ink, letterSpacing: -0.5),
        ),
      );
    }

    return Center(
      child: GestureDetector(
        onTap: _openImageSheet,
        child: SizedBox(
          width: 132,
          height: 132,
          child: Stack(
            children: [
              Container(
                width: 112,
                height: 112,
                margin: const EdgeInsets.only(top: 4, left: 4),
                decoration: BoxDecoration(
                  color: surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: line, width: 1),
                ),
                child: ClipOval(child: content),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: ink,
                    shape: BoxShape.circle,
                    border: Border.all(color: bg, width: 3),
                  ),
                  child: const Icon(Icons.camera_alt_outlined, color: surface, size: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    if (name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
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
    TextInputType? keyboardType,
    List<TextInputFormatter>? formatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
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
        suffixIcon: controller.text.isNotEmpty
            ? GestureDetector(
                onTap: () {
                  controller.clear();
                  setState(() {});
                },
                child: const Icon(Icons.close_rounded, size: 18, color: inkSoft),
              )
            : null,
        suffixIconConstraints: const BoxConstraints.tightFor(width: 40, height: 40),
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: _border(line),
        enabledBorder: _border(line),
        focusedBorder: _border(ink, width: 1.5),
        errorBorder: _border(danger),
        focusedErrorBorder: _border(danger, width: 1.5),
        errorStyle: const TextStyle(fontSize: 11, color: danger, fontWeight: FontWeight.w500),
      ),
      validator: validator,
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  Widget _buildEmailField(String email) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: line, width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.alternate_email_rounded, size: 18, color: inkSoft),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              email,
              style: const TextStyle(fontSize: 14, color: ink, fontWeight: FontWeight.w500, letterSpacing: -0.2),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: line),
            ),
            child: const Text(
              'Не редактируется',
              style: TextStyle(fontSize: 10, color: inkSoft, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(AuthService auth) {
    final canSave = _hasChanges && !auth.isLoading;
    return GestureDetector(
      onTap: canSave ? _save : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: canSave ? ink : line,
          borderRadius: BorderRadius.circular(14),
        ),
        child: auth.isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(color: surface, strokeWidth: 2),
              )
            : Text(
                'Сохранить изменения',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: canSave ? surface : inkSoft,
                  letterSpacing: -0.2,
                ),
              ),
      ),
    );
  }
}
