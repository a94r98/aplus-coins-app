import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';
import 'package:startapp_sdk/startapp.dart';

class AdManager {
  static bool _initialized = false;
  static StartAppSdk? _startAppSdk;

  // Initialize all ad networks at startup
  static Future<void> initialize() async {
    if (_initialized) return;

    // 1. Initialize AdMob
    try {
      await MobileAds.instance.initialize();
      print('✅ AdMob SDK initialized.');
    } catch (e) {
      print('❌ AdMob SDK initialization error: $e');
    }

    // 2. Initialize Unity Ads
    try {
      await UnityAds.init(
        gameId: '800076563', // Unity Game ID
        testMode: false, // Set to false for production
        onComplete: () {
          print('✅ Unity Ads SDK initialized.');
          // Pre-load Unity ads
          UnityAds.load(placementId: 'Rewarded_Android');
        },
        onFailed: (error, message) {
          print('❌ Unity Ads SDK initialization failed: $error - $message');
        },
      );
    } catch (e) {
      print('❌ Unity Ads initialization error: $e');
    }

    // 3. Initialize Start.io
    try {
      _startAppSdk = StartAppSdk();
      print('✅ StartApp SDK initialized.');
    } catch (e) {
      print('❌ StartApp SDK initialization error: $e');
    }

    _initialized = true;
  }

  // --- Show AdMob Rewarded Ad ---
  static void showAdMobRewarded({
    required Function() onUserEarnedReward,
    required Function(String error) onAdFailed,
  }) {
    // Production AdMob Rewarded unit ID
    final adUnitId = 'ca-app-pub-8139134711286467/3301002637'; 

    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (RewardedAd ad) {
              ad.dispose();
            },
            onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
              ad.dispose();
              onAdFailed(error.message);
            },
          );

          ad.show(
            onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
              onUserEarnedReward();
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          onAdFailed(error.message);
        },
      ),
    );
  }

  // --- Show Unity Rewarded Ad ---
  static void showUnityRewarded({
    required Function() onUserEarnedReward,
    required Function(String error) onAdFailed,
  }) {
    UnityAds.showVideoAd(
      placementId: 'Rewarded_Android',
      onComplete: (placementId) {
        onUserEarnedReward();
        // Load the next ad for caching
        UnityAds.load(placementId: 'Rewarded_Android');
      },
      onFailed: (placementId, error, message) {
        onAdFailed('$error: $message');
        // Retry loading
        UnityAds.load(placementId: 'Rewarded_Android');
      },
      onStart: (placementId) => print('Unity Video Ad Started: $placementId'),
      onClick: (placementId) => print('Unity Video Ad Clicked: $placementId'),
    );
  }

  // --- Show Start.io (StartApp) Rewarded Ad ---
  static void showStartIoRewarded({
    required Function() onUserEarnedReward,
    required Function(String error) onAdFailed,
  }) {
    if (_startAppSdk == null) {
      onAdFailed('StartApp SDK not initialized');
      return;
    }

    _startAppSdk!.loadRewardedVideoAd(
      onAdNotDisplayed: () {
        onAdFailed('Start.io Video Ad not displayed');
      },
      onAdHidden: () {
        // Closed by user
      },
      onVideoCompleted: () {
        onUserEarnedReward();
      },
    ).then((ad) {
      ad.show().onError((error, stackTrace) {
        onAdFailed('Failed to show Start.io Ad: $error');
        return false;
      });
    }).catchError((err) {
      onAdFailed(err?.toString() ?? 'Failed to load Start.io Video Ad');
    });
  }
}
