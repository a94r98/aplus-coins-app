import 'package:flutter/material.dart';
import '../../core/api/api_service.dart';
import '../../core/api/endpoints.dart';
import '../../core/utils/uuid.dart';

class DashboardModel {
  final int id;
  final String username;
  final String email;
  final String vipTier;
  final String referralCode;
  final double balance;
  final double availableBalance;
  final double pendingBalance;
  final double totalEarned;
  final double totalWithdrawn;
  final String? lastWithdrawalAt;
  final int adsWatchedToday;
  final int maxDailyAds;
  final String country;
  final String countryCode;
  final String language;
  final bool notificationsEnabled;

  DashboardModel({
    required this.id,
    required this.username,
    required this.email,
    required this.vipTier,
    required this.referralCode,
    required this.balance,
    required this.availableBalance,
    required this.pendingBalance,
    required this.totalEarned,
    required this.totalWithdrawn,
    this.lastWithdrawalAt,
    required this.adsWatchedToday,
    required this.maxDailyAds,
    required this.country,
    required this.countryCode,
    required this.language,
    required this.notificationsEnabled,
  });

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    return DashboardModel(
      id: json['id'] as int? ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      vipTier: json['vip_tier'] ?? 'FREE',
      referralCode: json['referral_code'] ?? '',
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      availableBalance: (json['available_balance'] as num?)?.toDouble() ?? 0.0,
      pendingBalance: (json['pending_balance'] as num?)?.toDouble() ?? 0.0,
      totalEarned: (json['total_earned'] as num?)?.toDouble() ?? 0.0,
      totalWithdrawn: (json['total_withdrawn'] as num?)?.toDouble() ?? 0.0,
      lastWithdrawalAt: json['last_withdrawal_at'],
      adsWatchedToday: json['ads_watched_today'] ?? 0,
      maxDailyAds: json['max_daily_ads'] ?? 5,
      country: json['country'] ?? '',
      countryCode: json['country_code'] ?? '',
      language: json['language'] ?? 'ar',
      notificationsEnabled: json['notifications_enabled'] as bool? ?? true,
    );
  }
}

class UnclaimedRewardModel {
  final int id;
  final String shareDate;
  final double poolShareAmount;
  final bool isClaimed;

  UnclaimedRewardModel({
    required this.id,
    required this.shareDate,
    required this.poolShareAmount,
    required this.isClaimed,
  });

  factory UnclaimedRewardModel.fromJson(Map<String, dynamic> json) {
    return UnclaimedRewardModel(
      id: json['id'],
      shareDate: json['share_date'] ?? '',
      poolShareAmount: double.tryParse(json['pool_share_amount']?.toString() ?? '0') ?? 0.0,
      isClaimed: json['is_claimed'] ?? false,
    );
  }
}

class BannerAdModel {
  final int id;
  final String title;
  final String description;
  final String imageUrl;
  final String actionUrl;
  final double rewardAmount;

  BannerAdModel({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.actionUrl,
    required this.rewardAmount,
  });

  factory BannerAdModel.fromJson(Map<String, dynamic> json) {
    return BannerAdModel(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['image_url'] ?? '',
      actionUrl: json['action_url'] ?? '',
      rewardAmount: double.tryParse(json['reward_amount']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class DailyTasksStatusModel {
  final bool checkInClaimed;
  final int bannerClicksCount;
  final bool shareAppClaimed;
  final int referralClicksCount;

  DailyTasksStatusModel({
    required this.checkInClaimed,
    required this.bannerClicksCount,
    required this.shareAppClaimed,
    required this.referralClicksCount,
  });

  factory DailyTasksStatusModel.fromJson(Map<String, dynamic> json) {
    return DailyTasksStatusModel(
      checkInClaimed: json['check_in_claimed'] ?? false,
      bannerClicksCount: json['banner_clicks_count'] ?? 0,
      shareAppClaimed: json['share_app_claimed'] ?? false,
      referralClicksCount: json['referral_clicks_count'] ?? 0,
    );
  }
}

class HomeController extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  DashboardModel? _dashboard;
  List<UnclaimedRewardModel> _unclaimedRewards = [];
  List<BannerAdModel> _banners = [];
  DailyTasksStatusModel? _tasksStatus;
  List<StoreProductModel> _products = [];
  List<dynamic> _storeOrders = [];
  List<dynamic> _notifications = [];
  bool _isLoading = false;
  String? _error;

  DashboardModel? get dashboard => _dashboard;
  List<UnclaimedRewardModel> get unclaimedRewards => _unclaimedRewards;
  List<BannerAdModel> get banners => _banners;
  DailyTasksStatusModel? get tasksStatus => _tasksStatus;
  List<StoreProductModel> get products => _products;
  List<dynamic> get storeOrders => _storeOrders;
  List<dynamic> get notifications => _notifications;
  bool get hasUnreadNotifications => _notifications.any((n) => n['is_read'] == false || n['is_read'] == 0 || n['is_read'] == 'false');
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> refreshDashboard() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final detailsRes = await _apiService.get(Endpoints.walletDetails);
      if (detailsRes['status'] == 'success') {
        _dashboard = DashboardModel.fromJson(detailsRes['data']);
      }
      
      final rewardsRes = await _apiService.get(Endpoints.unclaimedRewards);
      if (rewardsRes['status'] == 'success') {
        final List list = rewardsRes['data'] ?? [];
        _unclaimedRewards = list.map((item) => UnclaimedRewardModel.fromJson(item)).toList();
      }

      final bannersRes = await _apiService.get('/ads/banners');
      if (bannersRes['status'] == 'success') {
        final List list = bannersRes['data'] ?? [];
        _banners = list.map((item) => BannerAdModel.fromJson(item)).toList();
      }

      final tasksRes = await _apiService.get('/rewards/daily-tasks/status');
      if (tasksRes['status'] == 'success') {
        _tasksStatus = DailyTasksStatusModel.fromJson(tasksRes['data']);
      }

      final storeRes = await _apiService.get('/store/products');
      if (storeRes['status'] == 'success') {
        final List list = storeRes['data'] ?? [];
        _products = list.map((item) => StoreProductModel.fromJson(item)).toList();
      }
      
      // Fetch notifications in the background
      fetchNotifications();
      fetchStoreOrders();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> claimDailyReward(int shareId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _apiService.post(
        Endpoints.claimReward,
        body: {'shareId': shareId},
      );
      if (res['status'] == 'success') {
        await refreshDashboard();
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> claimCheckIn() async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await _apiService.post('/rewards/daily-tasks/check-in');
      if (res['status'] == 'success') {
        await refreshDashboard();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> claimBannerClick() async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await _apiService.post('/rewards/daily-tasks/banner-click');
      if (res['status'] == 'success') {
        await refreshDashboard();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> claimShareApp() async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await _apiService.post('/rewards/daily-tasks/share-app');
      if (res['status'] == 'success') {
        await refreshDashboard();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearState() {
    _dashboard = null;
    _unclaimedRewards = [];
    _banners = [];
    _tasksStatus = null;
    _products = [];
    _storeOrders = [];
    _notifications = [];
    _error = null;
    notifyListeners();
  }

  Future<void> fetchStoreProducts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _apiService.get('/store/products');
      if (res['status'] == 'success') {
        final List list = res['data'] ?? [];
        _products = list.map((item) => StoreProductModel.fromJson(item)).toList();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchStoreOrders() async {
    try {
      final res = await _apiService.get(Endpoints.storeOrders);
      if (res['status'] == 'success') {
        _storeOrders = res['data'] ?? [];
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching store orders: $e');
    }
  }

  Future<bool> submitStoreOrder({
    required String category,
    required String productName,
    required double coinsPrice,
    required Map<String, dynamic> details,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final idempotencyKey = UuidUtils.generateV4();
      final res = await _apiService.post(
        Endpoints.storeOrders,
        body: {
          'category': category,
          'productName': productName,
          'coinsPrice': coinsPrice,
          'details': details,
        },
        idempotencyKey: idempotencyKey,
      );
      if (res['status'] == 'success') {
        await refreshDashboard();
        await fetchStoreOrders();
        return true;
      }
      _error = res['message'] ?? 'Failed to submit store order';
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchNotifications() async {
    try {
      final res = await _apiService.get(Endpoints.getNotifications);
      if (res['status'] == 'success') {
        _notifications = res['data'] ?? [];
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    }
  }

  Future<void> markNotificationRead(int id) async {
    try {
      final res = await _apiService.post('${Endpoints.getNotifications}/$id/read');
      if (res['status'] == 'success') {
        await fetchNotifications();
      }
    } catch (e) {
      debugPrint('Error marking notification read: $e');
    }
  }
}

class StoreProductModel {
  final int id;
  final String name;
  final String description;
  final double coinsPrice;
  final String? vipTierGrant;

  StoreProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.coinsPrice,
    this.vipTierGrant,
  });

  factory StoreProductModel.fromJson(Map<String, dynamic> json) {
    return StoreProductModel(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      coinsPrice: double.tryParse(json['coins_price']?.toString() ?? '0') ?? 0.0,
      vipTierGrant: json['vip_tier_grant'],
    );
  }
}
