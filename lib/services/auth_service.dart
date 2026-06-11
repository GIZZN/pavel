import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_model.dart';
import 'database_service.dart';

class AuthService extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;

  // Инициализация - проверка сохраненного пользователя
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('current_user');
      
      if (userJson != null) {
        final userMap = json.decode(userJson) as Map<String, dynamic>;
        _currentUser = UserModel.fromJson(userMap);
      }
    } catch (e) {
      print('❌ Ошибка инициализации: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Регистрация
  Future<bool> register({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = await DatabaseService.instance.registerUser(
        email: email,
        password: password,
        name: name,
        phone: phone,
      );

      if (user != null) {
        _currentUser = user;
        await _saveUser(user);

        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      print('❌ Ошибка регистрации: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Вход
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = await DatabaseService.instance.loginUser(
        email: email,
        password: password,
      );

      if (user != null) {
        _currentUser = user;
        await _saveUser(user);

        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      print('❌ Ошибка входа: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Выход
  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user');
    notifyListeners();
  }

  // Обновить профиль
  Future<bool> updateProfile({
    String? name,
    String? phone,
    String? avatarUrl,
  }) async {
    if (_currentUser == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final success = await DatabaseService.instance.updateUser(
        id: _currentUser!.id!,
        name: name,
        phone: phone,
        avatarUrl: avatarUrl,
      );

      if (success) {
        _currentUser = _currentUser!.copyWith(
          name: name,
          phone: phone,
          avatarUrl: avatarUrl,
        );
        await _saveUser(_currentUser!);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      print('❌ Ошибка обновления профиля: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Сохранить пользователя локально
  Future<void> _saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_user', json.encode(user.toJson()));
  }
}
