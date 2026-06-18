import 'package:flutter/material.dart';
import '../../core/api/api_service.dart';
import '../../core/api/endpoints.dart';
import '../../core/utils/uuid.dart';

class WalletTransaction {
  final String id;
  final String type;
  final double amount;
  final String status;
  final String createdAt;
  final String? description;

  WalletTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.description,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id']?.toString() ?? '',
      type: json['transaction_type'] ?? json['type'] ?? 'unknown',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      status: json['status'] ?? 'unknown',
      createdAt: json['created_at']?.toString() ?? '',
      description: json['description'],
    );
  }
}

class WalletController extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  double _available = 0.0;
  double _pending = 0.0;
  String _country = '';
  String _countryCode = '';
  List<WalletTransaction> _transactions = [];
  List<WalletTransaction> _withdrawalHistory = [];
  bool _isLoading = false;
  bool _isWithdrawing = false;
  String? _error;
  String? _successMessage;

  double get available => _available;
  double get pending => _pending;
  String get country => _country;
  String get countryCode => _countryCode;
  List<WalletTransaction> get transactions => _transactions;
  List<WalletTransaction> get withdrawalHistory => _withdrawalHistory;
  bool get isLoading => _isLoading;
  bool get isWithdrawing => _isWithdrawing;
  String? get error => _error;
  String? get successMessage => _successMessage;

  Future<void> loadWallet() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final detailsRes = await _apiService.get(Endpoints.walletDetails);
      if (detailsRes['status'] == 'success') {
        final data = detailsRes['data'] as Map<String, dynamic>;
        _available = double.tryParse(data['available_balance']?.toString() ?? '0') ?? 0.0;
        _pending = double.tryParse(data['pending_balance']?.toString() ?? '0') ?? 0.0;
        _country = data['country'] ?? '';
        _countryCode = data['country_code'] ?? '';

        final txList = data['transactions'] as List? ?? [];
        _transactions = txList
            .cast<Map<String, dynamic>>()
            .map(WalletTransaction.fromJson)
            .toList();
      }

      final withdrawRes = await _apiService.get(Endpoints.withdrawals);
      if (withdrawRes['status'] == 'success') {
        final raw = withdrawRes['data'] as List? ?? [];
        _withdrawalHistory = raw
            .cast<Map<String, dynamic>>()
            .map(WalletTransaction.fromJson)
            .toList();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> requestWithdrawal({
    required double amount,
    required String method,
    required String destination,
  }) async {
    _isWithdrawing = true;
    _error = null;
    _successMessage = null;
    notifyListeners();

    try {
      final idempotencyKey = UuidUtils.generateV4();
      final res = await _apiService.post(Endpoints.withdraw, body: {
        'amount': amount,
        'method': method,
        'destination': destination,
      }, idempotencyKey: idempotencyKey);
      if (res['status'] == 'success') {
        _successMessage = 'تم إرسال طلب السحب بنجاح وسيتم معالجته خلال 24 ساعة';
        await loadWallet();
        return true;
      } else {
        _error = res['message'] ?? 'فشل طلب السحب';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isWithdrawing = false;
      notifyListeners();
    }
  }

  void clearMessages() {
    _error = null;
    _successMessage = null;
    notifyListeners();
  }
}
