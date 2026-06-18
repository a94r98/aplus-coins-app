import { DatabaseAPI, UserProfile, ReferralSettings, ReferralRecord, WalletTransaction } from '../api';

export interface ReferralResult {
  success: boolean;
  error?: 
    | 'system_inactive' 
    | 'self_referral_blocked' 
    | 'already_referred' 
    | 'rate_limit_exceeded' 
    | 'invalid_code' 
    | 'duplicate_transaction'
    | 'unexpected_error';
  rewardCoins?: number;
  newCoinsBalance?: number;
}

export const ReferralEngine = {
  /**
   * Pure Stateless Rule Engine for processing a referral request.
   * Following the strict Safety pipeline. Runs inside the API/Logic layer.
   * 
   * @param referredUserId The ID of the user applying the referral code (e.g. Ahmed 'u1')
   * @param referralCode The code being entered (e.g. some friend's code)
   */
  processReferralCode: async (referredUserId: string, referralCode: string): Promise<ReferralResult> => {
    try {
      // 1. Fetch settings (Rules configuration)
      const settings = await DatabaseAPI.getReferralSettings();
      if (!settings.active) {
        return { success: false, error: 'system_inactive' };
      }

      // 2. Fetch involved users
      const allUsers = await DatabaseAPI.getAllUsers();
      
      const referredUser = allUsers.find(u => u.id === referredUserId);
      if (!referredUser) {
        return { success: false, error: 'unexpected_error' };
      }

      // Check self-referral
      if (referredUser.referral_code === referralCode) {
        // Log blocked attempt in referrals database (Audit-grade)
        await DatabaseAPI.saveReferral({
          id: Math.random().toString(36).substring(2, 11),
          referrer_id: referredUserId,
          referred_id: referredUserId,
          referred_name: referredUser.name,
          reward_coins: 0,
          timestamp: new Date().toISOString(),
          status: 'BLOCKED'
        });
        await DatabaseAPI.logAdminAction(`Referral Blocked (Self Referral): User "${referredUser.name}" tried to refer themselves.`);
        return { success: false, error: 'self_referral_blocked' };
      }

      // Find referrer user by code
      const referrerUser = allUsers.find(u => u.referral_code === referralCode);
      if (!referrerUser) {
        return { success: false, error: 'invalid_code' };
      }

      // 3. Check duplicate referral (Already referred by someone else)
      if (referredUser.referred_by !== null) {
        return { success: false, error: 'already_referred' };
      }

      // 4. Rate Limiting (Sliding Time Window - Max 3 referrals per 3600 seconds per referrer)
      const allReferrals = await DatabaseAPI.getReferrals();
      
      // Filter SUCCESS referrals in the last 1 hour (3600 seconds) for this referrer
      const oneHourAgo = Date.now() - 3600 * 1000;
      const recentReferrals = allReferrals.filter(ref => 
        ref.referrer_id === referrerUser.id && 
        ref.status === 'SUCCESS' &&
        new Date(ref.timestamp).getTime() > oneHourAgo
      );

      if (recentReferrals.length >= 3) {
        // Save audit block record
        await DatabaseAPI.saveReferral({
          id: Math.random().toString(36).substring(2, 11),
          referrer_id: referrerUser.id,
          referred_id: referredUserId,
          referred_name: referredUser.name,
          reward_coins: 0,
          timestamp: new Date().toISOString(),
          status: 'BLOCKED'
        });
        await DatabaseAPI.logAdminAction(
          `Referral Blocked (Rate Limit): Referrer "${referrerUser.name}" reached 3 refs/hour limit.`
        );
        return { success: false, error: 'rate_limit_exceeded' };
      }

      // 5. Idempotency Check (Check if a successful referral record already exists for this pair)
      const isDuplicate = allReferrals.some(ref => 
        ref.referrer_id === referrerUser.id && 
        ref.referred_id === referredUserId && 
        ref.status === 'SUCCESS'
      );
      if (isDuplicate) {
        return { success: false, error: 'duplicate_transaction' };
      }

      // -------------------------------------------------------------
      // PIPELINE SUCCESS: APPLY REWARDS
      // -------------------------------------------------------------
      const rewardCoins = settings.referred_reward; // Reward for the user entering the code
      const referrerReward = settings.referrer_reward; // Reward for the code owner
      const referralRecordId = Math.random().toString(36).substring(2, 11);

      // A. Update referred user metadata (referred_by)
      const updatedReferredUser: UserProfile = {
        ...referredUser,
        referred_by: referralCode
      };
      await DatabaseAPI.updateUserProfile(updatedReferredUser);

      // B. Update referrer user metadata (referral_count)
      const updatedReferrerUser: UserProfile = {
        ...referrerUser,
        referral_count: referrerUser.referral_count + 1
      };
      
      // Sync list in all_users
      const usersList = await DatabaseAPI.getAllUsers();
      const updatedList = usersList.map(u => {
        if (u.id === referredUserId) return { ...updatedReferredUser, coins: u.coins };
        if (u.id === referrerUser.id) return { ...updatedReferrerUser, coins: u.coins };
        return u;
      });
      await AsyncStorage.setItem('@all_users', JSON.stringify(updatedList));

      // C. Generate sequence number & wallet settings
      const walletSettings = await DatabaseAPI.getWalletSettings();
      const ledgerTxs = await DatabaseAPI.getWalletTransactions();
      const lastSeq = ledgerTxs.length > 0 ? Math.max(...ledgerTxs.map(t => t.sequence_number || 0)) : 0;

      // D. Create Ledger Transaction for referred user (Ahmed)
      const referredTx: WalletTransaction = {
        id: 'tx_' + Math.random().toString(36).substring(2, 11),
        user_id: referredUserId,
        type: 'EARN',
        coins: rewardCoins,
        usd_snapshot: rewardCoins / walletSettings.exchange_rate,
        reference_id: referralRecordId,
        idempotency_key: `referral_apply_${referredUserId}_${referralCode}`,
        sequence_number: lastSeq + 1,
        created_at: new Date().toISOString()
      };
      await DatabaseAPI.saveWalletTransaction(referredTx);

      // E. Create Ledger Transaction for referrer user
      const referrerTx: WalletTransaction = {
        id: 'tx_' + Math.random().toString(36).substring(2, 11),
        user_id: referrerUser.id,
        type: 'EARN',
        coins: referrerReward,
        usd_snapshot: referrerReward / walletSettings.exchange_rate,
        reference_id: referralRecordId,
        idempotency_key: `referral_reward_${referrerUser.id}_${referredUserId}`,
        sequence_number: lastSeq + 2,
        created_at: new Date().toISOString()
      };
      await DatabaseAPI.saveWalletTransaction(referrerTx);

      // F. Rebuild balance cache atomically
      const newCoinsBalance = await DatabaseAPI.rebuildUserBalanceFromLedger(referredUserId);
      await DatabaseAPI.rebuildUserBalanceFromLedger(referrerUser.id);

      // G. Save successful referral record (Audit-grade)
      const newReferralRecord: ReferralRecord = {
        id: referralRecordId,
        referrer_id: referrerUser.id,
        referred_id: referredUserId,
        referred_name: referredUser.name,
        reward_coins: referrerReward,
        timestamp: new Date().toISOString(),
        status: 'SUCCESS'
      };
      await DatabaseAPI.saveReferral(newReferralRecord);

      // Send notifications to both referrer and referred users
      await DatabaseAPI.sendNotification(referredUserId, {
        title_ar: 'مكافأة الإحالة',
        title_en: 'Referral Reward Earned',
        message_ar: `لقد حصلت على ${rewardCoins} عملة لاستخدام كود الإحالة الخاص بصديقك.`,
        message_en: `You received ${rewardCoins} coins for using your friend's referral code.`,
        type: 'REFERRAL'
      });

      await DatabaseAPI.sendNotification(referrerUser.id, {
        title_ar: 'مكافأة إحالة جديدة',
        title_en: 'New Referral Reward',
        message_ar: `لقد حصلت على ${referrerReward} عملة لأن صديقك ${referredUser.name} استخدم كود الإحالة الخاص بك.`,
        message_en: `You received ${referrerReward} coins because your friend ${referredUser.name} used your referral code.`,
        type: 'REFERRAL'
      });

      // H. Log audit event
      await DatabaseAPI.logAdminAction(
        `Referral Successful (Version: ${settings.version}): "${referredUser.name}" referred by "${referrerUser.name}". Ref reward: ${referrerReward}, User reward: ${rewardCoins}`
      );

      return {
        success: true,
        rewardCoins,
        newCoinsBalance: newCoinsBalance
      };

    } catch (error) {
      console.error('Referral logic execution failed:', error);
      return { success: false, error: 'unexpected_error' };
    }
  },

  /**
   * DEV Simulation Helper: Simulates a new friend registering with Ahmed's referral code.
   * Executed strictly inside the API layer. Won't appear in production builds.
   * 
   * @param referrerId The ID of the user being referred (e.g. Ahmed 'u1')
   */
  simulateFriendInvite: async (referrerId: string): Promise<ReferralResult> => {
    try {
      const settings = await DatabaseAPI.getReferralSettings();
      if (!settings.active) {
        return { success: false, error: 'system_inactive' };
      }

      // A. Fetch Referrer profile
      const allUsers = await DatabaseAPI.getAllUsers();
      const referrerUser = allUsers.find(u => u.id === referrerId);
      if (!referrerUser) {
        return { success: false, error: 'unexpected_error' };
      }

      // B. Check Rate Limiting sliding window (Max 3/hour)
      const allReferrals = await DatabaseAPI.getReferrals();
      const oneHourAgo = Date.now() - 3600 * 1000;
      const recentReferrals = allReferrals.filter(ref => 
        ref.referrer_id === referrerId && 
        ref.status === 'SUCCESS' &&
        new Date(ref.timestamp).getTime() > oneHourAgo
      );

      if (recentReferrals.length >= 3) {
        // Save audit block record
        await DatabaseAPI.saveReferral({
          id: Math.random().toString(36).substring(2, 11),
          referrer_id: referrerId,
          referred_id: 'u_sim_blocked',
          referred_name: 'Simulated User (Blocked)',
          reward_coins: 0,
          timestamp: new Date().toISOString(),
          status: 'BLOCKED'
        });
        await DatabaseAPI.logAdminAction(
          `Simulated Referral Blocked: Rate Limit reached for "${referrerUser.name}".`
        );
        return { success: false, error: 'rate_limit_exceeded' };
      }

      // C. Generate a fake user signing up with Ahmed's code
      const fakeNames = ['سارة علي', 'محمد محمود', 'فاطمة حسن', 'ياسين أحمد', 'زينب جعفر'];
      const randomName = fakeNames[Math.floor(Math.random() * fakeNames.length)];
      
      const fakeUser = await DatabaseAPI.createNewUser(randomName, referrerUser.referral_code);

      // D. Generate sequence number & wallet settings
      const walletSettings = await DatabaseAPI.getWalletSettings();
      const ledgerTxs = await DatabaseAPI.getWalletTransactions();
      const lastSeq = ledgerTxs.length > 0 ? Math.max(...ledgerTxs.map(t => t.sequence_number || 0)) : 0;
      
      const referralRecordId = Math.random().toString(36).substring(2, 11);

      // E. Update referrer metadata
      const updatedReferrer: UserProfile = {
        ...referrerUser,
        referral_count: referrerUser.referral_count + 1
      };
      await DatabaseAPI.updateUserProfile(updatedReferrer);

      // F. Create Ledger Transaction for referrer (Ahmed)
      const referrerTx: WalletTransaction = {
        id: 'tx_' + Math.random().toString(36).substring(2, 11),
        user_id: referrerId,
        type: 'EARN',
        coins: settings.referrer_reward,
        usd_snapshot: settings.referrer_reward / walletSettings.exchange_rate,
        reference_id: referralRecordId,
        idempotency_key: `referral_reward_${referrerId}_${fakeUser.id}`,
        sequence_number: lastSeq + 1,
        created_at: new Date().toISOString()
      };
      await DatabaseAPI.saveWalletTransaction(referrerTx);

      // G. Create Ledger Transaction for simulated user
      const simulatedTx: WalletTransaction = {
        id: 'tx_' + Math.random().toString(36).substring(2, 11),
        user_id: fakeUser.id,
        type: 'EARN',
        coins: settings.referred_reward,
        usd_snapshot: settings.referred_reward / walletSettings.exchange_rate,
        reference_id: referralRecordId,
        idempotency_key: `referral_apply_${fakeUser.id}_${referrerUser.referral_code}`,
        sequence_number: lastSeq + 2,
        created_at: new Date().toISOString()
      };
      await DatabaseAPI.saveWalletTransaction(simulatedTx);

      // H. Rebuild caches
      const newCoinsBalance = await DatabaseAPI.rebuildUserBalanceFromLedger(referrerId);
      await DatabaseAPI.rebuildUserBalanceFromLedger(fakeUser.id);

      // Sync user profile list in all_users
      const usersList = await DatabaseAPI.getAllUsers();
      const updatedList = usersList.map(u => {
        if (u.id === referrerId) return { ...updatedReferrer, coins: newCoinsBalance };
        if (u.id === fakeUser.id) return { ...fakeUser, coins: settings.referred_reward };
        return u;
      });
      await AsyncStorage.setItem('@all_users', JSON.stringify(updatedList));

      // I. Save referral log
      const newReferralRecord: ReferralRecord = {
        id: referralRecordId,
        referrer_id: referrerId,
        referred_id: fakeUser.id,
        referred_name: fakeUser.name,
        reward_coins: settings.referrer_reward,
        timestamp: new Date().toISOString(),
        status: 'SUCCESS'
      };
      await DatabaseAPI.saveReferral(newReferralRecord);

      // Send notifications for simulated referral
      await DatabaseAPI.sendNotification(referrerId, {
        title_ar: 'مكافأة إحالة جديدة (محاكاة)',
        title_en: 'New Referral Reward (Simulated)',
        message_ar: `لقد حصلت على ${settings.referrer_reward} عملة لأن صديقك (محاكاة) ${fakeUser.name} استخدم كود الإحالة الخاص بك.`,
        message_en: `You received ${settings.referrer_reward} coins because your friend (simulated) ${fakeUser.name} used your referral code.`,
        type: 'REFERRAL'
      });

      await DatabaseAPI.sendNotification(fakeUser.id, {
        title_ar: 'مكافأة الإحالة',
        title_en: 'Referral Reward',
        message_ar: `لقد حصلت على ${settings.referred_reward} عملة للتسجيل بكود إحالة.`,
        message_en: `You received ${settings.referred_reward} coins for signing up with a referral code.`,
        type: 'REFERRAL'
      });

      await DatabaseAPI.logAdminAction(
        `[SIMULATION DEV] New User "${fakeUser.name}" signed up using code "${referrerUser.referral_code}". Ahmed received ${settings.referrer_reward} Coins.`
      );

      return {
        success: true,
        rewardCoins: settings.referrer_reward,
        newCoinsBalance: newCoinsBalance
      };

    } catch (e) {
      console.error('Simulation invite execution failed:', e);
      return { success: false, error: 'unexpected_error' };
    }
  }
};

import AsyncStorage from '@react-native-async-storage/async-storage';
