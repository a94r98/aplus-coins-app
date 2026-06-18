class Endpoints {
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String verifyEmail = '/auth/verify-email';
  static const String resendVerification = '/auth/resend-verification';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String getCountries = '/auth/countries';
  
  static const String watchAd = '/ads/watch';
  static const String adHistory = '/ads/history';
  
  static const String walletDetails = '/wallet/details';
  static const String upgradeVip = '/wallet/upgrade';
  static const String withdraw = '/wallet/withdraw';
  static const String withdrawals = '/wallet/withdrawals';
  
  static const String referrals = '/referrals';
  
  static const String unclaimedRewards = '/rewards/unclaimed';
  static const String claimReward = '/rewards/claim';
  
  static const String dailyVipRewardStatus = '/vip/daily-reward';
  static const String claimDailyVipReward = '/vip/daily-reward/claim';
  
  static const String oneTimeTasks = '/rewards/one-time-tasks';
  static const String claimOneTimeTask = '/rewards/one-time-tasks/claim';
  
  static const String storeOrders = '/store/orders';
  static const String getNotifications = '/notifications';
  static const String updateProfile = '/auth/profile';
  static const String deleteAccount = '/auth/profile';
}
