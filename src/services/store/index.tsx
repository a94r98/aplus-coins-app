import React, { createContext, useContext, useState, useEffect } from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { 
  DatabaseAPI, 
  Category, 
  Product, 
  Purchase, 
  AuditLog, 
  UserProfile, 
  UserSubscription,
  ReferralRecord, 
  ReferralSettings,
  WalletSettings,
  WalletTransaction,
  StoreWithdrawal,
  Notification,
  AdEvent,
  DailyEconomyRecord,
  SubscriptionPlan
} from '../api';
import { PurchaseEngine, PurchaseResult } from '../logic/purchase';
import { ReferralEngine, ReferralResult } from '../logic/referral';
import { WalletEngine } from '../logic/wallet';

interface AppContextType {
  userCoins: number;
  userProfile: UserProfile | null;
  categories: Category[];
  products: Product[];
  purchases: Purchase[];
  referrals: ReferralRecord[];
  referralSettings: ReferralSettings | null;
  auditLogs: AuditLog[];
  isAdmin: boolean;
  isLoading: boolean;
  pinLockoutTime: number | null;
  failedAttempts: number;

  // Wallet Engine state
  walletSettings: WalletSettings | null;
  walletTransactions: WalletTransaction[];
  storeWithdrawals: StoreWithdrawal[];
  availableBalance: number;
  pendingBalance: number;
  totalEarned: number;
  financialIntegrityStatus: 'OK' | 'WARNING' | 'CRITICAL';
  allUsers: UserProfile[];
  
  refreshData: () => Promise<void>;
  buyProduct: (productId: string) => Promise<PurchaseResult>;
  authenticateAdmin: (pin: string) => Promise<{ success: boolean; locked: boolean; remainingSec: number }>;
  logoutAdmin: () => void;
  incrementFailedAttempts: () => void;
  lockAdminMode: () => void;

  // Referral System Operations
  applyReferralCode: (code: string) => Promise<ReferralResult>;
  simulateFriendInvite: () => Promise<ReferralResult>;
  updateReferralSettings: (settings: ReferralSettings) => Promise<void>;
  resetReferrals: () => Promise<void>;

  // Wallet System Operations
  requestWithdrawal: (amount: number, method: string, address: string, idempotencyKey: string) => Promise<{ success: boolean; error?: string }>;
  approveWithdrawal: (id: string) => Promise<{ success: boolean; error?: string }>;
  rejectWithdrawal: (id: string, reason?: string) => Promise<{ success: boolean; error?: string }>;
  updateWalletSettings: (settings: WalletSettings, reason: string, beforeState: string, afterState: string) => Promise<void>;
  rebuildWalletBalance: () => Promise<void>;
  toggleUserFreeze: (userId: string, freeze: boolean) => Promise<void>;
  compensatingRollback: (userId: string, txId: string) => Promise<void>;
  resetWalletSystem: () => Promise<void>;
  updateUserProfile: (profile: UserProfile) => Promise<void>;
  setUserStatus: (userId: string, status: 'active' | 'suspended' | 'banned', reason: string) => Promise<void>;
  adjustUserBalance: (userId: string, amount: number, reason: string) => Promise<void>;
  updateUserSubscription: (userId: string, subscription: UserSubscription, reason: string) => Promise<void>;
  deleteUserAccount: () => Promise<void>;

  // Admin CRUD operations
  createCategory: (category: Omit<Category, 'id' | 'created_at'>) => Promise<void>;
  editCategory: (category: Category) => Promise<void>;
  removeCategory: (id: string) => Promise<void>;
  createProduct: (product: Omit<Product, 'id' | 'created_at'>) => Promise<void>;
  editProduct: (product: Product) => Promise<void>;
  removeProduct: (id: string) => Promise<void>;

  // Notifications
  notifications: Notification[];
  unreadNotificationsCount: number;
  sendNotification: (userId: string, details: Omit<Notification, 'id' | 'user_id' | 'read' | 'created_at'>) => Promise<void>;
  markNotificationRead: (notificationId: string) => Promise<void>;
  broadcastNotification: (details: Omit<Notification, 'id' | 'user_id' | 'read' | 'created_at'>) => Promise<void>;

  // Ad and Economy v7.0 State & Actions
  adEvents: AdEvent[];
  dailyEconomyRecords: DailyEconomyRecord[];
  claimDailyAdReward: () => Promise<{ success: boolean; error?: string; coinsEarned?: number }>;
  purchaseVIPSubscription: (plan: SubscriptionPlan) => Promise<{ success: boolean; error?: string; newBalance?: number }>;
}

const AppContext = createContext<AppContextType | undefined>(undefined);

export const AppProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [userProfile, setUserProfile] = useState<UserProfile | null>(null);
  const [userCoins, setUserCoins] = useState<number>(0);
  const [categories, setCategories] = useState<Category[]>([]);
  const [products, setProducts] = useState<Product[]>([]);
  const [purchases, setPurchases] = useState<Purchase[]>([]);
  const [referrals, setReferrals] = useState<ReferralRecord[]>([]);
  const [referralSettings, setReferralSettings] = useState<ReferralSettings | null>(null);
  const [auditLogs, setAuditLogs] = useState<AuditLog[]>([]);
  const [isAdmin, setIsAdmin] = useState<boolean>(false);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  
  // Security locks
  const [failedAttempts, setFailedAttempts] = useState<number>(0);
  const [pinLockoutTime, setPinLockoutTime] = useState<number | null>(null);

  // Wallet State
  const [walletSettings, setWalletSettings] = useState<WalletSettings | null>(null);
  const [walletTransactions, setWalletTransactions] = useState<WalletTransaction[]>([]);
  const [storeWithdrawals, setStoreWithdrawals] = useState<StoreWithdrawal[]>([]);
  const [availableBalance, setAvailableBalance] = useState<number>(0);
  const [pendingBalance, setPendingBalance] = useState<number>(0);
  const [totalEarned, setTotalEarned] = useState<number>(0);
  const [financialIntegrityStatus, setFinancialIntegrityStatus] = useState<'OK' | 'WARNING' | 'CRITICAL'>('OK');
  const [allUsers, setAllUsers] = useState<UserProfile[]>([]);

  // Notifications State
  const [notifications, setNotifications] = useState<Notification[]>([]);
  const [unreadNotificationsCount, setUnreadNotificationsCount] = useState<number>(0);

  // Ad and Economy State
  const [adEvents, setAdEvents] = useState<AdEvent[]>([]);
  const [dailyEconomyRecords, setDailyEconomyRecords] = useState<DailyEconomyRecord[]>([]);

  // Load database on mount
  useEffect(() => {
    refreshData();
    checkLockoutStatus();
  }, []);

  const checkLockoutStatus = async () => {
    try {
      const lockTime = await AsyncStorage.getItem('@pin_lockout_time');
      if (lockTime) {
        const endTime = parseInt(lockTime);
        if (Date.now() < endTime) {
          setPinLockoutTime(endTime);
        } else {
          await AsyncStorage.removeItem('@pin_lockout_time');
        }
      }
    } catch (e) {}
  };

  const refreshData = async () => {
    setIsLoading(true);
    try {
      await DatabaseAPI.init();
      const profile = await DatabaseAPI.getUserProfile();
      const cats = await DatabaseAPI.getCategories();
      const prods = await DatabaseAPI.getProducts();
      const purches = await DatabaseAPI.getPurchases();
      const refs = await DatabaseAPI.getReferrals();
      const settings = await DatabaseAPI.getReferralSettings();
      const logs = await DatabaseAPI.getAuditLogs();

      // Wallet settings & txs & withdrawals
      const wSettings = await DatabaseAPI.getWalletSettings();
      const wTxs = await DatabaseAPI.getWalletTransactions();
      const wWithdrawals = await DatabaseAPI.getStoreWithdrawals();

      // Recalculate Available and Pending balances
      const calculatedAvailable = await DatabaseAPI.getCalculatedAvailableBalance(profile.id);
      const calculatedPending = await DatabaseAPI.getCalculatedPendingBalance(profile.id);
      
      // Calculate total earned: Sum of EARN
      const earned = wTxs
        .filter(t => t.user_id === profile.id && t.type === 'EARN')
        .reduce((sum, t) => sum + Math.abs(t.coins), 0);

      setUserProfile(profile);
      setUserCoins(calculatedAvailable); // Always use recalculated available balance
      setCategories(cats);
      setProducts(prods);
      setPurchases(purches);
      setReferrals(refs);
      setReferralSettings(settings);
      setAuditLogs(logs);

      setWalletSettings(wSettings);
      setWalletTransactions(wTxs);
      setStoreWithdrawals(wWithdrawals);
      setAvailableBalance(calculatedAvailable);
      setPendingBalance(calculatedPending);
      setTotalEarned(earned);
      const users = await DatabaseAPI.getAllUsers();
      setAllUsers(users);

      // Fetch Notifications
      const notifs = await DatabaseAPI.getNotifications(profile.id);
      setNotifications(notifs);
      setUnreadNotificationsCount(notifs.filter(n => !n.read).length);

      // Fetch Ad Events and Daily Economy Records
      const ads = await DatabaseAPI.getAdEvents();
      const economy = await DatabaseAPI.getDailyEconomyRecords();
      setAdEvents(ads);
      setDailyEconomyRecords(economy);

      // Cache Integrity Validation (Auto-Healer)
      if (profile.coins !== calculatedAvailable) {
        setFinancialIntegrityStatus('WARNING');
        // Silent auto-healing in background
        const healed = await DatabaseAPI.rebuildUserBalanceFromLedger(profile.id);
        setUserCoins(healed);
        setAvailableBalance(healed);
        setFinancialIntegrityStatus('OK');
      } else {
        setFinancialIntegrityStatus('OK');
      }
    } catch (e) {
      console.error('Refresh data error:', e);
      setFinancialIntegrityStatus('CRITICAL');
    } finally {
      setIsLoading(false);
    }
  };

  const buyProduct = async (productId: string): Promise<PurchaseResult> => {
    setIsLoading(true);
    const result = await PurchaseEngine.executePurchase(productId);
    if (result.success && result.newCoinsBalance !== undefined) {
      // Refresh to fetch newly appended transaction & rebuild cache
      await refreshData();
    }
    setIsLoading(false);
    return result;
  };

  const authenticateAdmin = async (pin: string) => {
    if (pinLockoutTime && Date.now() < pinLockoutTime) {
      const remainingSec = Math.ceil((pinLockoutTime - Date.now()) / 1000);
      return { success: false, locked: true, remainingSec };
    }

    const matched = await DatabaseAPI.verifyAdminPIN(pin);
    if (matched) {
      setIsAdmin(true);
      setFailedAttempts(0);
      setPinLockoutTime(null);
      await AsyncStorage.removeItem('@pin_lockout_time');
      return { success: true, locked: false, remainingSec: 0 };
    } else {
      const newAttempts = failedAttempts + 1;
      setFailedAttempts(newAttempts);
      if (newAttempts >= 3) {
        const lockEnd = Date.now() + 300000; // 5 mins
        setPinLockoutTime(lockEnd);
        try {
          await AsyncStorage.setItem('@pin_lockout_time', lockEnd.toString());
        } catch (e) {}
        await DatabaseAPI.logAdminAction('Admin panel locked out due to 3 failed PIN attempts.');
        return { success: false, locked: true, remainingSec: 300 };
      }
      return { success: false, locked: false, remainingSec: 0 };
    }
  };

  const logoutAdmin = () => {
    setIsAdmin(false);
  };

  const incrementFailedAttempts = () => {
    setFailedAttempts(prev => prev + 1);
  };

  const lockAdminMode = () => {
    const lockEnd = Date.now() + 300000;
    setPinLockoutTime(lockEnd);
  };

  // -------------------------------------------------------------
  // REFERRAL OPERATIONS
  // -------------------------------------------------------------
  const applyReferralCode = async (code: string): Promise<ReferralResult> => {
    if (!userProfile) return { success: false, error: 'unexpected_error' };
    
    setIsLoading(true);
    const result = await ReferralEngine.processReferralCode(userProfile.id, code);
    if (result.success) {
      await refreshData();
    }
    setIsLoading(false);
    return result;
  };

  const simulateFriendInvite = async (): Promise<ReferralResult> => {
    if (!userProfile) return { success: false, error: 'unexpected_error' };
    
    setIsLoading(true);
    const result = await ReferralEngine.simulateFriendInvite(userProfile.id);
    if (result.success) {
      await refreshData();
    }
    setIsLoading(false);
    return result;
  };

  const updateReferralSettings = async (settings: ReferralSettings) => {
    setIsLoading(true);
    await DatabaseAPI.updateReferralSettings(settings);
    setReferralSettings(settings);
    const logs = await DatabaseAPI.getAuditLogs();
    setAuditLogs(logs);
    setIsLoading(false);
  };

  const resetReferrals = async () => {
    setIsLoading(true);
    await DatabaseAPI.resetReferralSystem();
    await refreshData();
    setIsLoading(false);
  };

  // -------------------------------------------------------------
  // WALLET SYSTEM OPERATIONS
  // -------------------------------------------------------------
  const requestWithdrawal = async (
    amount: number,
    method: string,
    address: string,
    idempotencyKey: string
  ) => {
    if (!userProfile) return { success: false, error: 'unexpected_error' };
    setIsLoading(true);
    const result = await WalletEngine.requestWithdrawal(
      userProfile.id,
      amount,
      method,
      address,
      idempotencyKey
    );
    await refreshData();
    setIsLoading(false);
    return result;
  };

  const approveWithdrawal = async (id: string) => {
    setIsLoading(true);
    const result = await WalletEngine.approveWithdrawal(id);
    await refreshData();
    setIsLoading(false);
    return result;
  };

  const rejectWithdrawal = async (id: string, reason?: string) => {
    setIsLoading(true);
    const result = await WalletEngine.rejectWithdrawal(id, reason);
    await refreshData();
    setIsLoading(false);
    return result;
  };

  const updateWalletSettings = async (
    settings: WalletSettings,
    reason: string,
    beforeState: string,
    afterState: string
  ) => {
    setIsLoading(true);
    await DatabaseAPI.updateWalletSettings(settings, reason, beforeState, afterState);
    await refreshData();
    setIsLoading(false);
  };

  const rebuildWalletBalance = async () => {
    if (!userProfile) return;
    setIsLoading(true);
    await DatabaseAPI.rebuildUserBalanceFromLedger(userProfile.id);
    await refreshData();
    setIsLoading(false);
  };

  const toggleUserFreeze = async (userId: string, freeze: boolean) => {
    setIsLoading(true);
    
    const allUsers = await DatabaseAPI.getAllUsers();
    const user = allUsers.find(u => u.id === userId);
    
    if (user) {
      const beforeState = JSON.stringify(user);
      const updatedUser = { ...user, withdraw_frozen: freeze };
      
      // Update u1 locally if active
      if (userId === 'u1') {
        const activeProfile = await DatabaseAPI.getUserProfile();
        await DatabaseAPI.updateUserProfile({ ...activeProfile, withdraw_frozen: freeze });
      } else {
        const usersList = await AsyncStorage.getItem('@all_users');
        let users: UserProfile[] = usersList ? JSON.parse(usersList) : [];
        users = users.map(u => u.id === userId ? { ...u, withdraw_frozen: freeze } : u);
        await AsyncStorage.setItem('@all_users', JSON.stringify(users));
      }
      
      const afterState = JSON.stringify(updatedUser);
      await DatabaseAPI.logAdminAction(
        `${freeze ? 'Froze' : 'Unfroze'} wallet for user ID: ${userId}`,
        'ADMIN_PIN',
        'User wallet freeze status updated',
        beforeState,
        afterState
      );
    }
    
    await refreshData();
    setIsLoading(false);
  };

  const compensatingRollback = async (userId: string, txId: string) => {
    setIsLoading(true);
    
    // Find transaction to rollback
    const txs = await DatabaseAPI.getWalletTransactions();
    const txToRollback = txs.find(t => t.id === txId && t.user_id === userId);
    
    if (txToRollback) {
      const beforeState = JSON.stringify(txToRollback);
      
      // Compensating rollback means we create a REFUND (if SPEND/WITHDRAW) or SPEND (if EARN/REFUND)
      const lastSeq = txs.length > 0 ? Math.max(...txs.map(t => t.sequence_number || 0)) : 0;
      const nextSeq = lastSeq + 1;
      
      let compensationType: 'EARN' | 'SPEND' | 'WITHDRAW' | 'REFUND' = 'REFUND';
      let compensationAmount = 0;
      
      if (txToRollback.type === 'SPEND' || txToRollback.type === 'WITHDRAW') {
        compensationType = 'REFUND';
        compensationAmount = Math.abs(txToRollback.coins);
      } else {
        compensationType = 'SPEND';
        compensationAmount = -Math.abs(txToRollback.coins);
      }
      
      const rate = txToRollback.usd_snapshot !== 0 ? Math.abs(txToRollback.coins / txToRollback.usd_snapshot) : 1000;
      
      const rollbackTx: WalletTransaction = {
        id: 'tx_' + Math.random().toString(36).substring(2, 11),
        user_id: userId,
        type: compensationType,
        coins: compensationAmount,
        usd_snapshot: compensationAmount / rate,
        reference_id: txId, // referenced rolled-back tx
        idempotency_key: `rollback_${txId}`,
        sequence_number: nextSeq,
        created_at: new Date().toISOString()
      };
      
      await DatabaseAPI.saveWalletTransaction(rollbackTx);
      await DatabaseAPI.rebuildUserBalanceFromLedger(userId);
      
      const afterState = JSON.stringify(rollbackTx);
      await DatabaseAPI.logAdminAction(
        `Issued compensating rollback transaction: ${rollbackTx.id} for tx: ${txId}`,
        'ADMIN_PIN',
        `Rollback of ${txToRollback.type} transaction`,
        beforeState,
        afterState
      );
    }
    
    await refreshData();
    setIsLoading(false);
  };

  const resetWalletSystem = async () => {
    setIsLoading(true);
    const beforeProfile = await DatabaseAPI.getUserProfile();
    const beforeSettings = await DatabaseAPI.getWalletSettings();
    const beforeTxs = await DatabaseAPI.getWalletTransactions();
    const beforeWithdrawals = await DatabaseAPI.getStoreWithdrawals();

    const beforeState = JSON.stringify({
      profile: beforeProfile,
      settings: beforeSettings,
      transactions: beforeTxs,
      withdrawals: beforeWithdrawals
    });

    // Reset wallet setting and seed transactions
    const defaultSettings: WalletSettings = {
      exchange_rate: 1000,
      min_withdraw: 1000,
      max_withdraw: 50000,
      withdraw_enabled: true,
      version: 1
    };

    const initialTxs: WalletTransaction[] = [
      {
        id: 'tx_seed_initial',
        user_id: 'u1',
        type: 'EARN',
        coins: 12450,
        usd_snapshot: 12.45,
        reference_id: 'initial_seed',
        idempotency_key: 'seed_init',
        sequence_number: 1,
        created_at: new Date(Date.now() - 864000000).toISOString()
      }
    ];

    await AsyncStorage.setItem('@wallet_settings', JSON.stringify(defaultSettings));
    await AsyncStorage.setItem('@wallet_transactions', JSON.stringify(initialTxs));
    await AsyncStorage.setItem('@store_withdrawals', JSON.stringify([]));
    await AsyncStorage.setItem('@wallet_locks', JSON.stringify([]));

    // Reset u1 profile freeze
    await DatabaseAPI.updateUserProfile({
      ...beforeProfile,
      withdraw_frozen: false,
      coins: 12450
    });

    const afterState = JSON.stringify({
      settings: defaultSettings,
      transactions: initialTxs,
      withdrawals: []
    });

    await DatabaseAPI.logAdminAction(
      'SYSTEM RESET: Wallet system reset completely.',
      'ADMIN_PIN',
      'Wallet System Reset',
      beforeState,
      afterState
    );

    await refreshData();
    setIsLoading(false);
  };

  const updateUserProfile = async (profile: UserProfile) => {
    setIsLoading(true);
    await DatabaseAPI.updateUserProfile(profile);
    await refreshData();
    setIsLoading(false);
  };

  const setUserStatus = async (userId: string, status: 'active' | 'suspended' | 'banned', reason: string) => {
    setIsLoading(true);
    const users = await DatabaseAPI.getAllUsers();
    const user = users.find(u => u.id === userId);
    if (user) {
      const beforeState = JSON.stringify(user);
      const updatedUser = { ...user, status };
      await DatabaseAPI.updateUserProfile(updatedUser);
      await DatabaseAPI.logAdminAction(
        `User status changed to ${status} for ${userId}`,
        'ADMIN_PIN',
        reason,
        beforeState,
        JSON.stringify(updatedUser)
      );
    }
    await refreshData();
    setIsLoading(false);
  };

  const adjustUserBalance = async (userId: string, amount: number, reason: string) => {
    setIsLoading(true);
    const walletSettings = await DatabaseAPI.getWalletSettings();
    const txs = await DatabaseAPI.getWalletTransactions();
    const nextSequence = txs.length > 0 ? Math.max(...txs.map(t => t.sequence_number)) + 1 : 1;
    const txType = amount >= 0 ? 'EARN' : 'SPEND';
    const coins = amount >= 0 ? amount : -Math.abs(amount);
    const usdSnapshot = walletSettings.exchange_rate ? Math.abs(coins) / walletSettings.exchange_rate : 0;

    const allUsers = await DatabaseAPI.getAllUsers();
    const user = allUsers.find(u => u.id === userId);
    if (user) {
      const beforeState = JSON.stringify(user);
      const adjustmentTx: WalletTransaction = {
        id: `tx_admin_adj_${Math.random().toString(36).substring(2, 10)}`,
        user_id: userId,
        type: txType,
        coins,
        usd_snapshot: usdSnapshot,
        reference_id: `admin_adjust_${Date.now()}`,
        idempotency_key: `admin_adjust_${userId}_${Date.now()}`,
        sequence_number: nextSequence,
        created_at: new Date().toISOString()
      };

      await DatabaseAPI.saveWalletTransaction(adjustmentTx);
      const rebuilt = await DatabaseAPI.rebuildUserBalanceFromLedger(userId);

      const updatedUser = { ...user, coins: rebuilt };
      await DatabaseAPI.logAdminAction(
        `Admin adjusted user balance by ${amount} coins for ${userId}`,
        'ADMIN_PIN',
        reason,
        beforeState,
        JSON.stringify(updatedUser)
      );
    }

    await refreshData();
    setIsLoading(false);
  };

  const updateUserSubscription = async (userId: string, subscription: UserSubscription, reason: string) => {
    setIsLoading(true);
    const users = await DatabaseAPI.getAllUsers();
    const user = users.find(u => u.id === userId);
    if (user) {
      const beforeState = JSON.stringify(user);
      const updatedUser = { ...user, subscription };
      await DatabaseAPI.updateUserProfile(updatedUser);
      await DatabaseAPI.logAdminAction(
        `User subscription updated for ${userId}`,
        'ADMIN_PIN',
        reason,
        beforeState,
        JSON.stringify(updatedUser)
      );
    }
    await refreshData();
    setIsLoading(false);
  };

  const deleteUserAccount = async () => {
    if (!userProfile) return;
    setIsLoading(true);
    const beforeState = JSON.stringify(userProfile);
    const users = await DatabaseAPI.getAllUsers();
    const remainingUsers = users.filter(u => u.id !== userProfile.id);
    await AsyncStorage.setItem('@all_users', JSON.stringify(remainingUsers));
    await AsyncStorage.removeItem('@user_profile');
    await DatabaseAPI.logAdminAction(
      `Deleted user account ${userProfile.id}`,
      'ADMIN_PIN',
      'User account removal',
      beforeState,
      'User removed from system'
    );
    await refreshData();
    setIsLoading(false);
  };

  // -------------------------------------------------------------
  // ADMIN CRUD OPERATIONS
  // -------------------------------------------------------------
  const createCategory = async (category: Omit<Category, 'id' | 'created_at'>) => {
    setIsLoading(true);
    await DatabaseAPI.addCategory(category);
    const cats = await DatabaseAPI.getCategories();
    const logs = await DatabaseAPI.getAuditLogs();
    setCategories(cats);
    setAuditLogs(logs);
    setIsLoading(false);
  };

  const editCategory = async (category: Category) => {
    setIsLoading(true);
    await DatabaseAPI.updateCategory(category);
    const cats = await DatabaseAPI.getCategories();
    const logs = await DatabaseAPI.getAuditLogs();
    setCategories(cats);
    setAuditLogs(logs);
    setIsLoading(false);
  };

  const removeCategory = async (id: string) => {
    setIsLoading(true);
    await DatabaseAPI.deleteCategory(id);
    const cats = await DatabaseAPI.getCategories();
    const logs = await DatabaseAPI.getAuditLogs();
    setCategories(cats);
    setAuditLogs(logs);
    setIsLoading(false);
  };

  const createProduct = async (product: Omit<Product, 'id' | 'created_at'>) => {
    setIsLoading(true);
    await DatabaseAPI.addProduct(product);
    const prods = await DatabaseAPI.getProducts();
    const logs = await DatabaseAPI.getAuditLogs();
    setProducts(prods);
    setAuditLogs(logs);
    setIsLoading(false);
  };

  const editProduct = async (product: Product) => {
    setIsLoading(true);
    await DatabaseAPI.updateProduct(product);
    const prods = await DatabaseAPI.getProducts();
    const logs = await DatabaseAPI.getAuditLogs();
    setProducts(prods);
    setAuditLogs(logs);
    setIsLoading(false);
  };

  const removeProduct = async (id: string) => {
    setIsLoading(true);
    await DatabaseAPI.deleteProduct(id);
    const prods = await DatabaseAPI.getProducts();
    const logs = await DatabaseAPI.getAuditLogs();
    setProducts(prods);
    setAuditLogs(logs);
    setIsLoading(false);
  };

  const sendNotification = async (userId: string, details: Omit<Notification, 'id' | 'user_id' | 'read' | 'created_at'>) => {
    await DatabaseAPI.sendNotification(userId, details);
    await refreshData();
  };

  const markNotificationRead = async (notificationId: string) => {
    await DatabaseAPI.markNotificationRead(notificationId);
    await refreshData();
  };

  const broadcastNotification = async (details: Omit<Notification, 'id' | 'user_id' | 'read' | 'created_at'>) => {
    await DatabaseAPI.broadcastNotification(details);
    await refreshData();
  };

  const claimDailyAdReward = async (): Promise<{ success: boolean; error?: string; coinsEarned?: number }> => {
    if (!userProfile) return { success: false, error: 'unexpected_error' };
    setIsLoading(true);
    const result = await DatabaseAPI.claimDailyAdReward(userProfile.id);
    await refreshData();
    setIsLoading(false);
    return result;
  };

  const purchaseVIPSubscription = async (plan: SubscriptionPlan): Promise<{ success: boolean; error?: string; newBalance?: number }> => {
    if (!userProfile) return { success: false, error: 'unexpected_error' };
    setIsLoading(true);
    const result = await DatabaseAPI.purchaseVIPSubscription(userProfile.id, plan);
    await refreshData();
    setIsLoading(false);
    return result;
  };

  return (
    <AppContext.Provider
      value={{
        userCoins,
        userProfile,
        categories,
        products,
        purchases,
        referrals,
        referralSettings,
        auditLogs,
        isAdmin,
        isLoading,
        pinLockoutTime,
        failedAttempts,
        walletSettings,
        walletTransactions,
        storeWithdrawals,
        availableBalance,
        pendingBalance,
        totalEarned,
        financialIntegrityStatus,
        refreshData,
        buyProduct,
        authenticateAdmin,
        logoutAdmin,
        incrementFailedAttempts,
        lockAdminMode,
        applyReferralCode,
        simulateFriendInvite,
        updateReferralSettings,
        resetReferrals,
        requestWithdrawal,
        approveWithdrawal,
        rejectWithdrawal,
        updateWalletSettings,
        rebuildWalletBalance,
        toggleUserFreeze,
        compensatingRollback,
        resetWalletSystem,
        updateUserProfile,
        setUserStatus,
        adjustUserBalance,
        updateUserSubscription,
        deleteUserAccount,
        allUsers,
        createCategory,
        editCategory,
        removeCategory,
        createProduct,
        editProduct,
        removeProduct,
        notifications,
        unreadNotificationsCount,
        sendNotification,
        markNotificationRead,
        broadcastNotification,
        adEvents,
        dailyEconomyRecords,
        claimDailyAdReward,
        purchaseVIPSubscription
      }}
    >
      {children}
    </AppContext.Provider>
  );
};

export const useApp = () => {
  const context = useContext(AppContext);
  if (context === undefined) {
    throw new Error('useApp must be used within an AppProvider');
  }
  return context;
};
