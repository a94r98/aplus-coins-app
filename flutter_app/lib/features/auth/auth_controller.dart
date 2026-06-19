import 'package:flutter/material.dart';
import '../../core/api/api_service.dart';
import '../../core/api/endpoints.dart';
import '../../core/utils/secure_storage.dart';

class AuthController extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  String? _error;
  bool _isEnglish = false; // RTL toggle state (default to Arabic)

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isEnglish => _isEnglish;

  void toggleLocale() {
    _isEnglish = !_isEnglish;
    notifyListeners();
  }

  Future<bool> register({
    required String username,
    required String email,
    required String password,
    String? phone,
    required String country,
    required String countryCode,
    required int age,
    String? referralCode,
    String? gender,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final fingerprint = await SecureStorage.getDeviceFingerprint();
      final payload = {
        'username': username,
        'email': email,
        'password': password,
        'phone': phone,
        'country': country,
        'countryCode': countryCode,
        'age': age,
        'deviceFingerprint': fingerprint,
      };
      if (referralCode != null && referralCode.isNotEmpty) {
        payload['referralCode'] = referralCode;
      }
      if (gender != null && gender.isNotEmpty) {
        payload['gender'] = gender;
      }

      final res = await _apiService.post(Endpoints.register, body: payload);
      if (res['status'] == 'success') {
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _apiService.post(Endpoints.login, body: {
        'email': email,
        'password': password,
      });
      if (res['status'] == 'success') {
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> verifyEmail(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _apiService.post(Endpoints.verifyEmail, body: {
        'token': token,
      });
      return res['status'] == 'success';
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> resendVerification(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _apiService.post(Endpoints.resendVerification, body: {
        'email': email,
      });
      return res['status'] == 'success';
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> forgotPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _apiService.post(Endpoints.forgotPassword, body: {
        'email': email,
      });
      return res['status'] == 'success';
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> resetPassword(String token, String newPassword) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _apiService.post(Endpoints.resetPassword, body: {
        'token': token,
        'newPassword': newPassword,
      });
      return res['status'] == 'success';
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> checkAuthStatus() async {
    final token = await SecureStorage.getToken();
    return token != null;
  }

  void setLocale(bool isEnglish) {
    if (_isEnglish != isEnglish) {
      _isEnglish = isEnglish;
      notifyListeners();
    }
  }

  Future<bool> updateProfile({
    String? username,
    String? language,
    bool? notificationsEnabled,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final Map<String, dynamic> body = {};
      if (username != null) body['username'] = username;
      if (language != null) body['language'] = language;
      if (notificationsEnabled != null) {
        body['notifications_enabled'] = notificationsEnabled;
      }

      final res = await _apiService.put(Endpoints.updateProfile, body: body);
      if (res['status'] == 'success') {
        if (language != null) {
          _isEnglish = (language == 'en');
        }
        return true;
      } else {
        _error = res['message'] ?? 'Failed to update profile';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteAccount() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _apiService.delete(Endpoints.deleteAccount);
      return res['status'] == 'success';
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await SecureStorage.deleteToken();
    notifyListeners();
  }
}
