import 'package:flutter/material.dart';
import '../../core/api/api_service.dart';
import '../../core/api/endpoints.dart';
import '../../core/utils/secure_storage.dart';
import '../../core/services/ad_manager.dart';

enum AdWatchState { idle, watching, cooldown, success, error }

class AdsController extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  AdWatchState _state = AdWatchState.idle;
  String? _errorMessage;
  int _cooldownSeconds = 0;
  List<Map<String, dynamic>> _history = [];
  bool _historyLoading = false;

  AdWatchState get state => _state;
  String? get errorMessage => _errorMessage;
  int get cooldownSeconds => _cooldownSeconds;
  List<Map<String, dynamic>> get history => _history;
  bool get historyLoading => _historyLoading;
  bool get canWatch => _state == AdWatchState.idle || _state == AdWatchState.success;

  // Watch an ad — plays ad via selected provider then logs /api/ads/watch on backend
  Future<bool> watchAd({
    required String provider,
    required VoidCallback onBalanceRefreshNeeded,
  }) async {
    if (!canWatch) return false;

    _state = AdWatchState.watching;
    _errorMessage = null;
    notifyListeners();

    final fingerprint = await SecureStorage.getDeviceFingerprint();

    // Helper to log reward securely on backend after user watched successfully
    Future<bool> logWatchOnBackend() async {
      try {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final payload = {
          'adId': '${provider}_rewarded',
          'clientTimestamp': timestamp,
          'deviceFingerprint': fingerprint,
        };

        final res = await _apiService.post(Endpoints.watchAd, body: payload);
        if (res['status'] == 'success') {
          _state = AdWatchState.success;
          notifyListeners();
          onBalanceRefreshNeeded();
          _startCooldown(30);
          return true;
        } else {
          _state = AdWatchState.error;
          _errorMessage = res['message'] ?? 'فشل توثيق مشاهدة الإعلان';
          notifyListeners();
          return false;
        }
      } catch (e) {
        _state = AdWatchState.error;
        _errorMessage = e.toString();
        notifyListeners();
        return false;
      }
    }

    try {
      if (provider == 'admob' || provider == 'meta') {
        // Meta (Facebook) works via AdMob mediation
        AdManager.showAdMobRewarded(
          onUserEarnedReward: () async {
            await logWatchOnBackend();
          },
          onAdFailed: (error) {
            _state = AdWatchState.error;
            _errorMessage = 'AdMob Error: $error';
            notifyListeners();
          },
        );
      } else if (provider == 'unity') {
        AdManager.showUnityRewarded(
          onUserEarnedReward: () async {
            await logWatchOnBackend();
          },
          onAdFailed: (error) {
            _state = AdWatchState.error;
            _errorMessage = 'Unity Error: $error';
            notifyListeners();
          },
        );
      } else if (provider == 'startio') {
        AdManager.showStartIoRewarded(
          onUserEarnedReward: () async {
            await logWatchOnBackend();
          },
          onAdFailed: (error) {
            _state = AdWatchState.error;
            _errorMessage = 'Start.io Error: $error';
            notifyListeners();
          },
        );
      } else {
        throw Exception('Unknown ad provider');
      }
      return true;
    } catch (e) {
      _state = AdWatchState.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void _startCooldown(int seconds) {
    _cooldownSeconds = seconds;
    _state = AdWatchState.cooldown;
    notifyListeners();

    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (_cooldownSeconds <= 1) {
        _cooldownSeconds = 0;
        _state = AdWatchState.idle;
        notifyListeners();
        return false;
      }
      _cooldownSeconds--;
      notifyListeners();
      return true;
    });
  }

  Future<void> loadHistory() async {
    _historyLoading = true;
    notifyListeners();
    try {
      final res = await _apiService.get(Endpoints.adHistory);
      if (res['status'] == 'success') {
        final List raw = res['data'] ?? [];
        _history = raw.cast<Map<String, dynamic>>();
      }
    } catch (_) {
      // Silently fail; show empty list
    } finally {
      _historyLoading = false;
      notifyListeners();
    }
  }

  void resetError() {
    if (_state == AdWatchState.error) {
      _state = AdWatchState.idle;
      _errorMessage = null;
      notifyListeners();
    }
  }
}
