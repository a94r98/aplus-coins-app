import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';
import 'package:startapp_sdk/startapp.dart';

class AdManager {
  static const bool useTestMode = true; // Set to false for production release

  static bool _initialized = false;
  static StartAppSdk? _startAppSdk;

  // Initialize all ad networks at startup
  static Future<void> initialize() async {
    if (_initialized) return;

    // 1. Initialize AdMob
    try {
      await MobileAds.instance.initialize();
      debugPrint('✅ AdMob SDK initialized.');
    } catch (e) {
      debugPrint('❌ AdMob SDK initialization error: $e');
    }

    // 2. Initialize Unity Ads
    try {
      await UnityAds.init(
        gameId: '800076563', // Unity Game ID
        testMode: useTestMode, // Enable test ads if useTestMode is true
        onComplete: () {
          debugPrint('✅ Unity Ads SDK initialized.');
          // Pre-load Unity ads
          UnityAds.load(placementId: 'Rewarded_Android');
        },
        onFailed: (error, message) {
          debugPrint('❌ Unity Ads SDK initialization failed: $error - $message');
        },
      );
    } catch (e) {
      debugPrint('❌ Unity Ads initialization error: $e');
    }

    // 3. Initialize Start.io
    try {
      _startAppSdk = StartAppSdk();
      if (useTestMode) {
        _startAppSdk!.setTestAdsEnabled(true);
        debugPrint('⚠️ StartApp Test Ads mode enabled.');
      }
      debugPrint('✅ StartApp SDK initialized.');
    } catch (e) {
      debugPrint('❌ StartApp SDK initialization error: $e');
    }

    _initialized = true;
  }

  // --- Show AdMob Rewarded Ad ---
  static void showAdMobRewarded({
    required Function() onUserEarnedReward,
    required Function(String error) onAdFailed,
  }) {
    // Official Google AdMob Test Rewarded Ad Unit ID vs Production ID
    final adUnitId = useTestMode 
        ? 'ca-app-pub-3940256099942544/5224354917' 
        : 'ca-app-pub-8139134711286467/3301002637'; 

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
      onStart: (placementId) => debugPrint('Unity Video Ad Started: $placementId'),
      onClick: (placementId) => debugPrint('Unity Video Ad Clicked: $placementId'),
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
