import AsyncStorage from '@react-native-async-storage/async-storage';

export interface Category {
  id: string;
  name_ar: string;
  name_en: string;
  icon: string;
  color: string;
  sort_order: number;
  active: boolean;
  created_at: string;
}

export interface Product {
  id: string;
  title_ar: string;
  title_en: string;
  description_ar: string;
  description_en: string;
  image: string;
  price_coins: number;
  category_id: string;
  stock: number;
  active: boolean;
  vip_only: boolean;
  created_at: string;
}

export interface Purchase {
  id: string;
  product_id: string;
  price_coins: number;
  status: 'delivered' | 'pending';
  delivery_code: string;
  created_at: string;
}

export interface AuditLog {
  id: string;
  action: string;
  admin_id?: string;
  reason?: string;
  before_state?: string;
  after_state?: string;
  timestamp: string;
}

export type SubscriptionPlan = 'free' | 'monthly' | '90days' | 'yearly' | 'lifetime';
export type SubscriptionStatus = 'active' | 'expired' | 'suspended';

export interface UserSubscription {
  plan: SubscriptionPlan;
  started_at: string;
  expires_at: string | null;
  status: SubscriptionStatus;
  activation_code_id: string;
  share_weight: number;
  daily_earning_cap: number;
  today_coins_earned: number;
  ads_watched_today: number;
  last_ad_watch_time: string | null;
}

export interface AdEvent {
  id: string;
  user_id: string;
  reward_coins: number;
  timestamp: string;
}

export interface DailyEconomyRecord {
  date: string;
  total_pool_coins: number;
  total_shares_weight: number;
  conversion_rate: number;
  distributed_coins: number;
  created_at: string;
}


// -------------------------------------------------------------
// REFERRAL SYSTEM INTERFACES
// -------------------------------------------------------------
export interface UserProfile {
  id: string;
  name: string;
  country: string;
  gender?: 'male' | 'female' | 'other';
  referral_code: string; // unique, immutable
  referral_count: number;
  referred_by: string | null;
  coins: number; // cached balance
  withdraw_frozen?: boolean; // emergency user freeze flag
  status: 'active' | 'suspended' | 'banned';
  subscription: UserSubscription;
  theme_preference: 'light' | 'dark';
  notifications_enabled: boolean;
  created_at: string;
}

export interface ReferralSettings {
  active: boolean;
  referrer_reward: number;
  referred_reward: number;
  version: number;
  updated_at: string;
}

export interface ReferralRecord {
  id: string;
  referrer_id: string;
  referred_id: string;
  referred_name: string;
  reward_coins: number;
  timestamp: string;
  status: 'SUCCESS' | 'BLOCKED';
}

// -------------------------------------------------------------
// FINTECH WALLET CORE INTERFACES
// -------------------------------------------------------------
export interface WalletSettings {
  exchange_rate: number;      // e.g. 1000 coins = 1 USD
  min_withdraw: number;       // min coins required to withdraw
  max_withdraw: number;       // max coins allowed per withdraw
  withdraw_enabled: boolean;  // global withdraw system toggle
  version: number;            // version control for audit logging
}

export interface WalletTransaction {
  id: string;
  user_id: string;
  type: 'EARN' | 'SPEND' | 'WITHDRAW' | 'REFUND';
  coins: number;              // signed: positive for earn/refund, negative for spend/withdraw
  usd_snapshot: number;       // signed snapshot USD equivalent
  reference_id: string;       // e.g. withdrawal_id, purchase_id, referral_id
  idempotency_key: string;    // unique request key to prevent double spend
  sequence_number: number;    // strict sequential event ordering ID
  created_at: string;
}

export interface WalletLock {
  user_id: string;
  locked: boolean;
  lock_id: string;            // unique token to release specific lock
  expires_at: number;         // Unix timestamp (ms) for TTL safety
  sequence_number: number;    // tracking lock execution order
}

export interface StoreWithdrawal {
  id: string;
  user_id: string;
  coins: number;              // positive amount requested
  usd_amount: number;         // snapshot locked USD value
  exchange_rate_snapshot: number; // exchange rate locked at request
  method: string;             // e.g. "Zain Cash", "FastPay", "PayPal", "USDT"
  wallet_address: string;     // recipient wallet or phone
  status: 'pending' | 'approved' | 'rejected';
  idempotency_key: string;    // matching request idempotency
  sequence_number: number;    // sequence number at creation
  created_at: string;
}

export interface Notification {
  id: string;
  user_id: string;
  title_ar: string;
  title_en: string;
  message_ar: string;
  message_en: string;
  type: 'EARN' | 'SPEND' | 'WITHDRAW' | 'REFUND' | 'SYSTEM' | 'REFERRAL';
  read: boolean;
  created_at: string;
  scheduled_at?: string;
}



// Initial Data
const initialCategories: Category[] = [
  {
    id: '1',
    name_ar: 'بطاقات شحن',
    name_en: 'Recharge Cards',
    icon: 'card-outline',
    color: '#00A896',
    sort_order: 1,
    active: true,
    created_at: new Date().toISOString()
  },
  {
    id: '2',
    name_ar: 'ألعاب',
    name_en: 'Games',
    icon: 'game-controller-outline',
    color: '#FF5A5F',
    sort_order: 2,
    active: true,
    created_at: new Date().toISOString()
  },
  {
    id: '3',
    name_ar: 'VIP خدمات',
    name_en: 'VIP Services',
    icon: 'diamond-outline',
    color: '#BD93F9',
    sort_order: 3,
    active: true,
    created_at: new Date().toISOString()
  },
  {
    id: '4',
    name_ar: 'عروض اليوم',
    name_en: 'Daily Offers',
    icon: 'flash-outline',
    color: '#FFB86C',
    sort_order: 4,
    active: true,
    created_at: new Date().toISOString()
  }
];

const initialProducts: Product[] = [
  {
    id: 'p1',
    title_ar: 'كارت آسيا 5,000 د.ع',
    title_en: 'Asiacell 5,000 IQD',
    description_ar: 'بطاقة شحن رصيد آسيا سيل فئة 5000 دينار عراقي يتم شحنها فورياً للكود المستلم',
    description_en: 'Asiacell recharge card 5,000 IQD value, instantly loaded with the code',
    image: 'https://images.unsplash.com/photo-1601597111158-2fceff292cdc?w=150',
    price_coins: 500,
    category_id: '1',
    stock: 8,
    active: true,
    vip_only: false,
    created_at: new Date().toISOString()
  },
  {
    id: 'p2',
    title_ar: 'بطاقة غوغل بلاي $5',
    title_en: 'Google Play Gift Card $5',
    description_ar: 'بطاقة هدايا متجر غوغل بلاي فئة 5 دولار أمريكي لتعبئة حسابك وشراء التطبيقات والألعاب',
    description_en: 'Google Play Gift Card $5 for US account recharge to purchase apps and games',
    image: 'https://images.unsplash.com/photo-1576402187878-974f70c890a5?w=150',
    price_coins: 1000,
    category_id: '1',
    stock: 4,
    active: true,
    vip_only: false,
    created_at: new Date().toISOString()
  },
  {
    id: 'p3',
    title_ar: '60 شدة ببجي موبايل',
    title_en: '60 PUBG UC',
    description_ar: 'شحن فوري لـ 60 شدة (UC) في لعبة ببجي موبايل عن طريق معرف اللاعب ID',
    description_en: 'Instant recharge of 60 Unknown Cash (UC) for PUBG Mobile via player ID',
    image: 'https://images.unsplash.com/photo-1542751371-adc38448a05e?w=150',
    price_coins: 120,
    category_id: '2',
    stock: 15,
    active: true,
    vip_only: false,
    created_at: new Date().toISOString()
  },
  {
    id: 'p4',
    title_ar: 'اشتراك VIP Boost شهري',
    title_en: 'Monthly VIP Boost Subscription',
    description_ar: 'تفعيل وضع VIP لزيادة الأرباح بنسبة 200% ومضاعفة مكافآت المهام اليومية',
    description_en: 'Activate VIP status to boost your earnings by 200% and double daily rewards',
    image: 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=150',
    price_coins: 2500,
    category_id: '3',
    stock: 2,
    active: true,
    vip_only: true,
    created_at: new Date().toISOString()
  }
];

// Initial Ahmed Profile
const initialUserProfile: UserProfile = {
  id: 'u1',
  name: 'أحمد',
  country: 'Iraq',
  gender: 'male',
  referral_code: 'A7K9-3XQ', // Unique and Immutable generated once
  referral_count: 3,
  referred_by: null,
  coins: 12450,
  withdraw_frozen: false,
  status: 'active',
  subscription: {
    plan: 'free',
    started_at: new Date(Date.now() - 864000000).toISOString(),
    expires_at: null,
    status: 'active',
    activation_code_id: 'ACT-0001',
    share_weight: 1,
    daily_earning_cap: 100,
    today_coins_earned: 0,
    ads_watched_today: 0,
    last_ad_watch_time: null
  },
  theme_preference: 'light',
  notifications_enabled: true,
  created_at: new Date(Date.now() - 864000000).toISOString() // 10 days ago
};

const normalizeUserProfile = (profile: Partial<UserProfile>): UserProfile => ({
  ...initialUserProfile,
  ...profile,
  subscription: {
    ...initialUserProfile.subscription,
    plan: profile.subscription?.plan || 'free',
    started_at: profile.subscription?.started_at || new Date(Date.now() - 864000000).toISOString(),
    expires_at: profile.subscription?.expires_at !== undefined ? profile.subscription.expires_at : null,
    status: profile.subscription?.status || 'active',
    activation_code_id: profile.subscription?.activation_code_id || 'ACT-0001',
    share_weight: profile.subscription?.share_weight !== undefined ? profile.subscription.share_weight : 1,
    daily_earning_cap: profile.subscription?.daily_earning_cap !== undefined ? profile.subscription.daily_earning_cap : 100,
    today_coins_earned: profile.subscription?.today_coins_earned !== undefined ? profile.subscription.today_coins_earned : 0,
    ads_watched_today: profile.subscription?.ads_watched_today !== undefined ? profile.subscription.ads_watched_today : 0,
    last_ad_watch_time: profile.subscription?.last_ad_watch_time !== undefined ? profile.subscription.last_ad_watch_time : null
  }
});

// Initial Referral Logs for Ahmed
const initialReferrals: ReferralRecord[] = [
  {
    id: 'ref1',
    referrer_id: 'u1',
    referred_id: 'u_fake_1',
    referred_name: 'علي عمر',
    reward_coins: 100,
    timestamp: new Date(Date.now() - 172800000).toISOString(), // 2 days ago
    status: 'SUCCESS'
  },
  {
    id: 'ref2',
    referrer_id: 'u1',
    referred_id: 'u_fake_2',
    referred_name: 'سامي العراقي',
    reward_coins: 100,
    timestamp: new Date(Date.now() - 86400000).toISOString(), // 1 day ago
    status: 'SUCCESS'
  },
  {
    id: 'ref3',
    referrer_id: 'u1',
    referred_id: 'u_fake_3',
    referred_name: 'نور مصطفى',
    reward_coins: 100,
    timestamp: new Date(Date.now() - 36000000).toISOString(), // 10 hours ago
    status: 'SUCCESS'
  }
];

const initialReferralSettings: ReferralSettings = {
  active: true,
  referrer_reward: 100,
  referred_reward: 100,
  version: 1,
  updated_at: new Date().toISOString()
};

// Helper to generate a unique referral code: XXXX-XXX
function generateUniqueRefCode(): string {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  const rand = (len: number) => Array.from({ length: len }, () => chars[Math.floor(Math.random() * chars.length)]).join('');
  return `${rand(4)}-${rand(3)}`;
}

// Helper to simulate network latency
const delay = (ms = 350) => new Promise(resolve => setTimeout(resolve, ms));

export const DatabaseAPI = {
  // Initialize Database keys in AsyncStorage
  init: async () => {
    try {
      const isInitialized = await AsyncStorage.getItem('@store_initialized_v2');
      if (!isInitialized) {
        await AsyncStorage.setItem('@categories', JSON.stringify(initialCategories));
        await AsyncStorage.setItem('@products', JSON.stringify(initialProducts));
        await AsyncStorage.setItem('@purchases', JSON.stringify([]));
        await AsyncStorage.setItem('@audit_logs', JSON.stringify([{ 
          id: '1', 
          action: 'System DB Initialized with dynamic Referrals', 
          admin_id: 'SYSTEM',
          reason: 'Initial setup',
          before_state: 'N/A',
          after_state: 'Initial DB',
          timestamp: new Date().toISOString() 
        }]));
        
        // Referral Database Tables
        await AsyncStorage.setItem('@user_profile', JSON.stringify(initialUserProfile));
        await AsyncStorage.setItem('@referrals', JSON.stringify(initialReferrals));
        await AsyncStorage.setItem('@referral_settings', JSON.stringify(initialReferralSettings));
        await AsyncStorage.setItem('@all_users', JSON.stringify([initialUserProfile])); // holds all simulated users in the system

        await AsyncStorage.setItem('@admin_pin', '1234');
        await AsyncStorage.setItem('@store_initialized_v2', 'true');
      }

      // Seed wallet if not done yet
      const isWalletInit = await AsyncStorage.getItem('@wallet_initialized_v3');
      if (!isWalletInit) {
        const initialWalletSettings: WalletSettings = {
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

        await AsyncStorage.setItem('@wallet_settings', JSON.stringify(initialWalletSettings));
        await AsyncStorage.setItem('@wallet_transactions', JSON.stringify(initialTxs));
        await AsyncStorage.setItem('@store_withdrawals', JSON.stringify([]));
        await AsyncStorage.setItem('@wallet_locks', JSON.stringify([]));
        await AsyncStorage.setItem('@wallet_initialized_v3', 'true');
      }

      // Seed notifications if not done yet
      const isNotificationsInit = await AsyncStorage.getItem('@notifications_initialized');
      if (!isNotificationsInit) {
        await AsyncStorage.setItem('@notifications', JSON.stringify([]));
        await AsyncStorage.setItem('@notifications_initialized', 'true');
      }

      // Seed ad events if not done yet
      const isAdEventsInit = await AsyncStorage.getItem('@ad_events_initialized');
      if (!isAdEventsInit) {
        await AsyncStorage.setItem('@ad_events', JSON.stringify([]));
        await AsyncStorage.setItem('@ad_events_initialized', 'true');
      }

      // Seed daily economy records if not done yet
      const isDailyEconomyInit = await AsyncStorage.getItem('@daily_economy_initialized');
      if (!isDailyEconomyInit) {
        await AsyncStorage.setItem('@daily_economy_records', JSON.stringify([]));
        await AsyncStorage.setItem('@daily_economy_initialized', 'true');
      }
    } catch (e) {
      console.error('Database initialization failed', e);
    }
  },

  // -------------------------------------------------------------
  // USER PROFILE & COINS
  // -------------------------------------------------------------
  getUserProfile: async (): Promise<UserProfile> => {
    await DatabaseAPI.init();
    await delay(100);
    const data = await AsyncStorage.getItem('@user_profile');
    if (!data) return initialUserProfile;
    const rawProfile = JSON.parse(data) as Partial<UserProfile>;
    const profile = normalizeUserProfile(rawProfile);

    // Dynamic recalculation of coins balance from ledger (Hybrid Balance Model)
    const calculatedBalance = await DatabaseAPI.getCalculatedAvailableBalance(profile.id);
    profile.coins = calculatedBalance;
    return profile;
  },

  updateUserProfile: async (profile: UserProfile): Promise<void> => {
    await delay(150);
    const normalized = normalizeUserProfile(profile);
    await AsyncStorage.setItem('@user_profile', JSON.stringify(normalized));

    const data = await AsyncStorage.getItem('@all_users');
    let users: UserProfile[] = data ? JSON.parse(data) : [];
    const exists = users.some(u => u.id === normalized.id);
    if (exists) {
      users = users.map(u => u.id === normalized.id ? normalized : u);
    } else {
      users.push(normalized);
    }
    await AsyncStorage.setItem('@all_users', JSON.stringify(users));
  },

  getUserCoins: async (): Promise<number> => {
    const profile = await DatabaseAPI.getUserProfile();
    return profile.coins;
  },

  updateUserCoins: async (coins: number): Promise<void> => {
    const profile = await DatabaseAPI.getUserProfile();
    profile.coins = coins; // update cache
    await DatabaseAPI.updateUserProfile(profile);
  },

  // -------------------------------------------------------------
  // ALL REGISTERED USERS (FOR SEARCHING CODES)
  // -------------------------------------------------------------
  getAllUsers: async (): Promise<UserProfile[]> => {
    await DatabaseAPI.init();
    const data = await AsyncStorage.getItem('@all_users');
    const users: UserProfile[] = data ? JSON.parse(data) : [];
    
    const txsData = await AsyncStorage.getItem('@wallet_transactions');
    const txs: WalletTransaction[] = txsData ? JSON.parse(txsData) : [];
    
    return users.map(u => {
      const userTxs = txs.filter(t => t.user_id === u.id);
      let sum = 0;
      for (const t of userTxs) {
        if (t.type === 'EARN' || t.type === 'REFUND') {
          sum += Math.abs(t.coins);
        } else if (t.type === 'SPEND' || t.type === 'WITHDRAW') {
          sum -= Math.abs(t.coins);
        }
      }
      return normalizeUserProfile({ ...u, coins: sum });
    });
  },

  createNewUser: async (name: string, referredByCode: string | null): Promise<UserProfile> => {
    const data = await AsyncStorage.getItem('@all_users');
    const users: UserProfile[] = data ? JSON.parse(data) : [];

    const newUser: UserProfile = {
      id: 'u_' + Math.random().toString(36).substring(2, 11),
      name,
      country: 'Unknown',
      gender: 'other',
      referral_code: generateUniqueRefCode(), // Generated ONLY ONCE at creation
      referral_count: 0,
      referred_by: referredByCode,
      coins: 0, // start with 0 (will get referred_reward if referredByCode is valid)
      withdraw_frozen: false,
      status: 'active',
      subscription: {
        plan: 'free',
        started_at: new Date().toISOString(),
        expires_at: null,
        status: 'active',
        activation_code_id: `FREE-${Math.random().toString(36).substring(2, 8).toUpperCase()}`,
        share_weight: 1,
        daily_earning_cap: 100,
        today_coins_earned: 0,
        ads_watched_today: 0,
        last_ad_watch_time: null
      },
      theme_preference: 'light',
      notifications_enabled: true,
      created_at: new Date().toISOString()
    };

    users.push(newUser);
    await AsyncStorage.setItem('@all_users', JSON.stringify(users));
    return newUser;
  },

  // -------------------------------------------------------------
  // REFERRAL SETTINGS
  // -------------------------------------------------------------
  getReferralSettings: async (): Promise<ReferralSettings> => {
    await DatabaseAPI.init();
    await delay(150);
    const data = await AsyncStorage.getItem('@referral_settings');
    return data ? JSON.parse(data) : initialReferralSettings;
  },

  updateReferralSettings: async (settings: ReferralSettings): Promise<void> => {
    await delay(200);
    const beforeState = await AsyncStorage.getItem('@referral_settings');
    await AsyncStorage.setItem('@referral_settings', JSON.stringify(settings));
    await DatabaseAPI.logAdminAction(
      `Referral Settings Updated (Version: ${settings.version}): Active=${settings.active}, Ref Reward=${settings.referrer_reward}, New User Reward=${settings.referred_reward}`,
      'ADMIN_PIN',
      'Update referral rules config',
      beforeState || 'N/A',
      JSON.stringify(settings)
    );
  },

  // -------------------------------------------------------------
  // REFERRAL LOGS
  // -------------------------------------------------------------
  getReferrals: async (): Promise<ReferralRecord[]> => {
    await DatabaseAPI.init();
    await delay(200);
    const data = await AsyncStorage.getItem('@referrals');
    return data ? JSON.parse(data) : [];
  },

  saveReferral: async (record: ReferralRecord): Promise<void> => {
    const data = await AsyncStorage.getItem('@referrals');
    const records: ReferralRecord[] = data ? JSON.parse(data) : [];
    records.unshift(record);
    await AsyncStorage.setItem('@referrals', JSON.stringify(records));
  },

  resetReferralSystem: async (): Promise<void> => {
    await delay(500);
    const beforeProfile = await DatabaseAPI.getUserProfile();
    
    // Reset user count
    await DatabaseAPI.updateUserProfile({
      ...beforeProfile,
      referral_count: 0
    });

    // Reset tables
    await AsyncStorage.setItem('@referrals', JSON.stringify([]));
    await AsyncStorage.setItem('@all_users', JSON.stringify([{ ...beforeProfile, referral_count: 0 }]));
    
    await DatabaseAPI.logAdminAction(
      'SYSTEM RESET: Referral count and logs reset completely.',
      'ADMIN_PIN',
      'System Reset Action',
      JSON.stringify(beforeProfile),
      'Referrals reset'
    );
  },

  // -------------------------------------------------------------
  // CATEGORIES & PRODUCTS (STORE)
  // -------------------------------------------------------------
  getCategories: async (): Promise<Category[]> => {
    await DatabaseAPI.init();
    await delay(150);
    const data = await AsyncStorage.getItem('@categories');
    const categories: Category[] = data ? JSON.parse(data) : [];
    return categories.sort((a, b) => a.sort_order - b.sort_order);
  },

  addCategory: async (category: Omit<Category, 'id' | 'created_at'>): Promise<Category> => {
    await delay(200);
    const beforeState = await AsyncStorage.getItem('@categories');
    const categories: Category[] = beforeState ? JSON.parse(beforeState) : [];
    
    const newCategory: Category = {
      ...category,
      id: Math.random().toString(36).substring(2, 11),
      created_at: new Date().toISOString()
    };

    categories.push(newCategory);
    await AsyncStorage.setItem('@categories', JSON.stringify(categories));
    await DatabaseAPI.logAdminAction(
      `Added Category: ${category.name_ar}`,
      'ADMIN_PIN',
      'Add store category',
      beforeState || '[]',
      JSON.stringify(categories)
    );
    return newCategory;
  },

  updateCategory: async (updated: Category): Promise<Category> => {
    await delay(200);
    const beforeState = await AsyncStorage.getItem('@categories');
    let categories: Category[] = JSON.parse(beforeState || '[]');
    
    categories = categories.map(c => c.id === updated.id ? updated : c);
    await AsyncStorage.setItem('@categories', JSON.stringify(categories));
    await DatabaseAPI.logAdminAction(
      `Updated Category (ID: ${updated.id}): ${updated.name_ar}`,
      'ADMIN_PIN',
      'Update store category',
      beforeState || '[]',
      JSON.stringify(categories)
    );
    return updated;
  },

  deleteCategory: async (id: string): Promise<void> => {
    await delay(200);
    const beforeState = await AsyncStorage.getItem('@categories');
    let categories: Category[] = JSON.parse(beforeState || '[]');
    
    categories = categories.filter(c => c.id !== id);
    await AsyncStorage.setItem('@categories', JSON.stringify(categories));
    await DatabaseAPI.logAdminAction(
      `Deleted Category (ID: ${id})`,
      'ADMIN_PIN',
      'Delete store category',
      beforeState || '[]',
      JSON.stringify(categories)
    );
  },

  getProducts: async (): Promise<Product[]> => {
    await DatabaseAPI.init();
    await delay(200);
    const data = await AsyncStorage.getItem('@products');
    return data ? JSON.parse(data) : [];
  },

  addProduct: async (product: Omit<Product, 'id' | 'created_at'>): Promise<Product> => {
    await delay(200);
    const beforeState = await AsyncStorage.getItem('@products');
    const products: Product[] = JSON.parse(beforeState || '[]');

    const newProduct: Product = {
      ...product,
      id: Math.random().toString(36).substring(2, 11),
      created_at: new Date().toISOString()
    };

    products.push(newProduct);
    await AsyncStorage.setItem('@products', JSON.stringify(products));
    await DatabaseAPI.logAdminAction(
      `Added Product: ${product.title_ar}`,
      'ADMIN_PIN',
      'Add store product',
      beforeState || '[]',
      JSON.stringify(products)
    );
    return newProduct;
  },

  updateProduct: async (updated: Product): Promise<Product> => {
    await delay(250);
    const beforeState = await AsyncStorage.getItem('@products');
    let products: Product[] = JSON.parse(beforeState || '[]');

    products = products.map(p => p.id === updated.id ? updated : p);
    await AsyncStorage.setItem('@products', JSON.stringify(products));
    await DatabaseAPI.logAdminAction(
      `Updated Product (ID: ${updated.id}): ${updated.title_ar}`,
      'ADMIN_PIN',
      'Update store product',
      beforeState || '[]',
      JSON.stringify(products)
    );
    return updated;
  },

  deleteProduct: async (id: string): Promise<void> => {
    await delay(250);
    const beforeState = await AsyncStorage.getItem('@products');
    let products: Product[] = JSON.parse(beforeState || '[]');

    products = products.filter(p => p.id !== id);
    await AsyncStorage.setItem('@products', JSON.stringify(products));
    await DatabaseAPI.logAdminAction(
      `Deleted Product (ID: ${id})`,
      'ADMIN_PIN',
      'Delete store product',
      beforeState || '[]',
      JSON.stringify(products)
    );
  },

  getPurchases: async (): Promise<Purchase[]> => {
    await DatabaseAPI.init();
    await delay(150);
    const data = await AsyncStorage.getItem('@purchases');
    return data ? JSON.parse(data) : [];
  },

  savePurchase: async (purchase: Purchase): Promise<void> => {
    const data = await AsyncStorage.getItem('@purchases');
    const purchases: Purchase[] = data ? JSON.parse(data) : [];
    purchases.unshift(purchase);
    await AsyncStorage.setItem('@purchases', JSON.stringify(purchases));
  },

  // -------------------------------------------------------------
  // FINTECH WALLET API OPERATIONS
  // -------------------------------------------------------------
  getWalletSettings: async (): Promise<WalletSettings> => {
    await DatabaseAPI.init();
    const data = await AsyncStorage.getItem('@wallet_settings');
    if (!data) {
      const defaultSettings: WalletSettings = {
        exchange_rate: 1000,
        min_withdraw: 1000,
        max_withdraw: 50000,
        withdraw_enabled: true,
        version: 1
      };
      await AsyncStorage.setItem('@wallet_settings', JSON.stringify(defaultSettings));
      return defaultSettings;
    }
    return JSON.parse(data);
  },

  updateWalletSettings: async (settings: WalletSettings, reason: string, beforeState: string, afterState: string): Promise<void> => {
    await delay(200);
    await AsyncStorage.setItem('@wallet_settings', JSON.stringify(settings));
    await DatabaseAPI.logAdminAction(
      `Wallet Settings Updated (v${settings.version}): rate=${settings.exchange_rate}, min=${settings.min_withdraw}, max=${settings.max_withdraw}, active=${settings.withdraw_enabled}`,
      'ADMIN_PIN',
      reason,
      beforeState,
      afterState
    );
  },

  getWalletTransactions: async (): Promise<WalletTransaction[]> => {
    await DatabaseAPI.init();
    const data = await AsyncStorage.getItem('@wallet_transactions');
    return data ? JSON.parse(data) : [];
  },

  saveWalletTransaction: async (tx: WalletTransaction): Promise<void> => {
    const data = await AsyncStorage.getItem('@wallet_transactions');
    const txs: WalletTransaction[] = data ? JSON.parse(data) : [];
    
    // Programmatic uniqueness check on (user_id, idempotency_key) to prevent double spends
    const isDuplicate = txs.some(t => t.user_id === tx.user_id && t.idempotency_key === tx.idempotency_key);
    if (isDuplicate) {
      throw new Error(`Duplicate transaction detected for idempotency key: ${tx.idempotency_key}`);
    }

    txs.unshift(tx);
    await AsyncStorage.setItem('@wallet_transactions', JSON.stringify(txs));
  },

  getStoreWithdrawals: async (): Promise<StoreWithdrawal[]> => {
    await DatabaseAPI.init();
    const data = await AsyncStorage.getItem('@store_withdrawals');
    return data ? JSON.parse(data) : [];
  },

  saveStoreWithdrawal: async (withdrawal: StoreWithdrawal): Promise<void> => {
    const data = await AsyncStorage.getItem('@store_withdrawals');
    const withdrawals: StoreWithdrawal[] = data ? JSON.parse(data) : [];
    withdrawals.unshift(withdrawal);
    await AsyncStorage.setItem('@store_withdrawals', JSON.stringify(withdrawals));
  },

  updateStoreWithdrawalStatus: async (id: string, status: 'approved' | 'rejected'): Promise<void> => {
    const data = await AsyncStorage.getItem('@store_withdrawals');
    let withdrawals: StoreWithdrawal[] = data ? JSON.parse(data) : [];
    withdrawals = withdrawals.map(w => w.id === id ? { ...w, status } : w);
    await AsyncStorage.setItem('@store_withdrawals', JSON.stringify(withdrawals));
  },

  getCalculatedAvailableBalance: async (userId: string): Promise<number> => {
    const data = await AsyncStorage.getItem('@wallet_transactions');
    if (!data) return 0;
    const txs: WalletTransaction[] = JSON.parse(data);
    const userTxs = txs.filter(t => t.user_id === userId);
    
    let sum = 0;
    for (const t of userTxs) {
      if (t.type === 'EARN' || t.type === 'REFUND') {
        sum += Math.abs(t.coins);
      } else if (t.type === 'SPEND' || t.type === 'WITHDRAW') {
        sum -= Math.abs(t.coins);
      }
    }
    return sum;
  },

  getCalculatedPendingBalance: async (userId: string): Promise<number> => {
    const data = await AsyncStorage.getItem('@store_withdrawals');
    if (!data) return 0;
    const withdrawals: StoreWithdrawal[] = JSON.parse(data);
    const userPending = withdrawals.filter(w => w.user_id === userId && w.status === 'pending');
    return userPending.reduce((acc, w) => acc + Math.abs(w.coins), 0);
  },

  rebuildUserBalanceFromLedger: async (userId: string): Promise<number> => {
    const calculatedBalance = await DatabaseAPI.getCalculatedAvailableBalance(userId);
    const data = await AsyncStorage.getItem('@user_profile');
    if (data) {
      const profile: UserProfile = JSON.parse(data);
      if (profile.id === userId) {
        profile.coins = calculatedBalance;
        await AsyncStorage.setItem('@user_profile', JSON.stringify(profile));
        
        // Sync in all_users
        const allUsersData = await AsyncStorage.getItem('@all_users');
        if (allUsersData) {
          let users: UserProfile[] = JSON.parse(allUsersData);
          users = users.map(u => u.id === userId ? { ...u, coins: calculatedBalance } : u);
          await AsyncStorage.setItem('@all_users', JSON.stringify(users));
        }
      }
    }
    return calculatedBalance;
  },

  // -------------------------------------------------------------
  // CONCURRENCY LOCKING OPERATIONS (Distributed-like Redis TTL Lock)
  // -------------------------------------------------------------
  acquireLock: async (userId: string): Promise<string> => {
    const data = await AsyncStorage.getItem('@wallet_locks');
    const locks: WalletLock[] = data ? JSON.parse(data) : [];
    
    const now = Date.now();
    const existingLockIndex = locks.findIndex(l => l.user_id === userId);
    
    if (existingLockIndex !== -1) {
      const existingLock = locks[existingLockIndex];
      // TTL safe auto-release: if lock is active but expired, force unlock
      if (existingLock.locked && now < existingLock.expires_at) {
        throw new Error('Wallet is locked by another concurrent transaction.');
      }
    }

    const lock_id = Math.random().toString(36).substring(2, 11);
    const expires_at = now + 8000; // 8 seconds TTL
    const newLock: WalletLock = {
      user_id: userId,
      locked: true,
      lock_id,
      expires_at,
      sequence_number: now
    };

    if (existingLockIndex !== -1) {
      locks[existingLockIndex] = newLock;
    } else {
      locks.push(newLock);
    }

    await AsyncStorage.setItem('@wallet_locks', JSON.stringify(locks));
    return lock_id;
  },

  releaseLock: async (userId: string, lockId: string): Promise<void> => {
    const data = await AsyncStorage.getItem('@wallet_locks');
    if (!data) return;
    let locks: WalletLock[] = JSON.parse(data);
    
    locks = locks.map(l => {
      if (l.user_id === userId && l.lock_id === lockId) {
        return { ...l, locked: false };
      }
      return l;
    });

    await AsyncStorage.setItem('@wallet_locks', JSON.stringify(locks));
  },

  // -------------------------------------------------------------
  // SECURITY & AUDIT
  // -------------------------------------------------------------
  verifyAdminPIN: async (pin: string): Promise<boolean> => {
    await DatabaseAPI.init();
    await delay(500);
    const adminPin = await AsyncStorage.getItem('@admin_pin');
    const isMatched = adminPin === pin;
    await DatabaseAPI.logAdminAction(`Admin Access Attempt: ${isMatched ? 'SUCCESS' : 'FAILED'}`);
    return isMatched;
  },

  getAuditLogs: async (): Promise<AuditLog[]> => {
    await DatabaseAPI.init();
    const data = await AsyncStorage.getItem('@audit_logs');
    return data ? JSON.parse(data) : [];
  },

  logAdminAction: async (
    action: string, 
    adminId = 'ADMIN_PIN', 
    reason = 'N/A', 
    beforeState = 'N/A', 
    afterState = 'N/A'
  ): Promise<void> => {
    const data = await AsyncStorage.getItem('@audit_logs');
    const logs: any[] = data ? JSON.parse(data) : [];
    logs.unshift({
      id: Math.random().toString(36).substring(2, 11),
      action,
      admin_id: adminId,
      reason,
      before_state: beforeState,
      after_state: afterState,
      timestamp: new Date().toISOString()
    });
    await AsyncStorage.setItem('@audit_logs', JSON.stringify(logs));
  },

  // -------------------------------------------------------------
  // NOTIFICATIONS SYSTEM API
  // -------------------------------------------------------------
  getNotifications: async (userId: string): Promise<Notification[]> => {
    await DatabaseAPI.init();
    const data = await AsyncStorage.getItem('@notifications');
    const allNotifs: Notification[] = data ? JSON.parse(data) : [];
    const now = Date.now();
    return allNotifs
      .filter(n => 
        (n.user_id === userId || n.user_id === 'all') &&
        (!n.scheduled_at || new Date(n.scheduled_at).getTime() <= now)
      )
      .sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime());
  },

  saveNotification: async (notification: Notification): Promise<void> => {
    const data = await AsyncStorage.getItem('@notifications');
    const allNotifs: Notification[] = data ? JSON.parse(data) : [];
    allNotifs.push(notification);
    await AsyncStorage.setItem('@notifications', JSON.stringify(allNotifs));
  },

  markNotificationRead: async (notificationId: string): Promise<void> => {
    const data = await AsyncStorage.getItem('@notifications');
    let allNotifs: Notification[] = data ? JSON.parse(data) : [];
    allNotifs = allNotifs.map(n => n.id === notificationId ? { ...n, read: true } : n);
    await AsyncStorage.setItem('@notifications', JSON.stringify(allNotifs));
  },

  sendNotification: async (
    userId: string, 
    details: Omit<Notification, 'id' | 'user_id' | 'read' | 'created_at'>
  ): Promise<Notification> => {
    const newNotif: Notification = {
      ...details,
      id: 'notif_' + Math.random().toString(36).substring(2, 11),
      user_id: userId,
      read: false,
      created_at: new Date().toISOString()
    };
    await DatabaseAPI.saveNotification(newNotif);
    await DatabaseAPI.logAdminAction(
      `Notification sent to user ${userId}: ${details.title_en} - ${details.message_en}`,
      'SYSTEM',
      'Automatic Notification trigger',
      'N/A',
      JSON.stringify(newNotif)
    );
    return newNotif;
  },

  broadcastNotification: async (
    details: Omit<Notification, 'id' | 'user_id' | 'read' | 'created_at'>
  ): Promise<Notification> => {
    const newNotif: Notification = {
      ...details,
      id: 'notif_' + Math.random().toString(36).substring(2, 11),
      user_id: 'all',
      read: false,
      created_at: new Date().toISOString()
    };
    await DatabaseAPI.saveNotification(newNotif);
    await DatabaseAPI.logAdminAction(
      `Broadcast notification sent: ${details.title_en} - ${details.message_en}`,
      'SYSTEM',
      'Notification Broadcast',
      'N/A',
      JSON.stringify(newNotif)
    );
    return newNotif;
  },

  scheduleNotification: async (
    userId: string,
    details: Omit<Notification, 'id' | 'user_id' | 'read' | 'created_at'>,
    delayMs: number
  ): Promise<Notification> => {
    const newNotif: Notification = {
      ...details,
      id: 'notif_' + Math.random().toString(36).substring(2, 11),
      user_id: userId,
      read: false,
      created_at: new Date().toISOString(),
      scheduled_at: new Date(Date.now() + delayMs).toISOString()
    };
    await DatabaseAPI.saveNotification(newNotif);
    await DatabaseAPI.logAdminAction(
      `Notification scheduled for user ${userId} in ${delayMs}ms: ${details.title_en}`,
      'SYSTEM',
      'Notification Schedule',
      'N/A',
      JSON.stringify(newNotif)
    );
    return newNotif;
  },

  getAdEvents: async (): Promise<AdEvent[]> => {
    await DatabaseAPI.init();
    const data = await AsyncStorage.getItem('@ad_events');
    return data ? JSON.parse(data) : [];
  },

  getDailyEconomyRecords: async (): Promise<DailyEconomyRecord[]> => {
    await DatabaseAPI.init();
    const data = await AsyncStorage.getItem('@daily_economy_records');
    return data ? JSON.parse(data) : [];
  },

  claimDailyAdReward: async (userId: string): Promise<{ success: boolean; error?: string; coinsEarned?: number }> => {
    await DatabaseAPI.init();
    
    // Acquire lock
    let lockId: string | null = null;
    try {
      lockId = await DatabaseAPI.acquireLock(userId);
    } catch (lockError) {
      return { success: false, error: 'concurrency_lock_active' };
    }

    try {
      // Fetch user profile
      const user = await DatabaseAPI.getUserProfile();
      if (user.status !== 'active') {
        return { success: false, error: 'user_not_active' };
      }

      const sub = user.subscription;
      const now = Date.now();

      // Check cooldown (60 seconds)
      if (sub.last_ad_watch_time) {
        const lastWatch = new Date(sub.last_ad_watch_time).getTime();
        if (now - lastWatch < 60000) {
          return { success: false, error: 'cooldown_active' };
        }
      }

      // Check daily cap
      const today_coins_earned = sub.today_coins_earned || 0;
      const daily_earning_cap = sub.daily_earning_cap || 100;
      if (today_coins_earned >= daily_earning_cap) {
        return { success: false, error: 'daily_cap_reached' };
      }

      // Base total reward value of watching an ad is 200 coins
      const totalRewardValue = 200;
      // Fixed 50/15/35 distribution split calculations:
      const userShare = totalRewardValue * 0.50;      // 100 coins
      const referrerShare = totalRewardValue * 0.15;  // 30 coins
      const poolShare = totalRewardValue * 0.35;      // 70 coins

      // User reward capped by daily limit
      const remainingCap = daily_earning_cap - today_coins_earned;
      const actualUserReward = Math.min(userShare, remainingCap);
      if (actualUserReward <= 0) {
        return { success: false, error: 'daily_cap_reached' };
      }

      // 1. Save Ad Event
      const adEventId = 'ad_' + Math.random().toString(36).substring(2, 11);
      const adEvent: AdEvent = {
        id: adEventId,
        user_id: userId,
        reward_coins: actualUserReward,
        timestamp: new Date().toISOString()
      };
      const rawAdEvents = await AsyncStorage.getItem('@ad_events');
      const adEvents: AdEvent[] = rawAdEvents ? JSON.parse(rawAdEvents) : [];
      adEvents.unshift(adEvent);
      await AsyncStorage.setItem('@ad_events', JSON.stringify(adEvents));

      // 2. Generate sequence number & wallet settings
      const walletSettings = await DatabaseAPI.getWalletSettings();
      const ledgerTxs = await DatabaseAPI.getWalletTransactions();
      const lastSeq = ledgerTxs.length > 0 ? Math.max(...ledgerTxs.map(t => t.sequence_number || 0)) : 0;
      let currentSeq = lastSeq + 1;

      // 3. User reward transaction (50% Split)
      const userTx: WalletTransaction = {
        id: 'tx_' + Math.random().toString(36).substring(2, 11),
        user_id: userId,
        type: 'EARN',
        coins: actualUserReward,
        usd_snapshot: actualUserReward / walletSettings.exchange_rate,
        reference_id: adEventId,
        idempotency_key: `ad_reward_user_${adEventId}`,
        sequence_number: currentSeq,
        created_at: new Date().toISOString()
      };
      await DatabaseAPI.saveWalletTransaction(userTx);
      currentSeq++;

      // 4. Referrer reward transaction (15% Split)
      if (user.referred_by) {
        const allUsers = await DatabaseAPI.getAllUsers();
        const referrer = allUsers.find(u => u.referral_code === user.referred_by);
        if (referrer) {
          const referrerTx: WalletTransaction = {
            id: 'tx_' + Math.random().toString(36).substring(2, 11),
            user_id: referrer.id,
            type: 'EARN',
            coins: referrerShare,
            usd_snapshot: referrerShare / walletSettings.exchange_rate,
            reference_id: adEventId,
            idempotency_key: `ad_reward_ref_${adEventId}`,
            sequence_number: currentSeq,
            created_at: new Date().toISOString()
          };
          await DatabaseAPI.saveWalletTransaction(referrerTx);
          await DatabaseAPI.rebuildUserBalanceFromLedger(referrer.id);
          currentSeq++;

          await DatabaseAPI.sendNotification(referrer.id, {
            title_ar: 'عمولة مشاهدة إعلان',
            title_en: 'Ad View Commission',
            message_ar: `لقد حصلت على ${referrerShare} عملة لأن صديقك ${user.name} شاهد إعلاناً.`,
            message_en: `You received ${referrerShare} coins because your friend ${user.name} watched an ad.`,
            type: 'REFERRAL'
          });
        }
      }

      // 5. Update user subscription state
      user.subscription = {
        ...user.subscription,
        today_coins_earned: today_coins_earned + actualUserReward,
        ads_watched_today: (sub.ads_watched_today || 0) + 1,
        last_ad_watch_time: new Date().toISOString()
      };
      await DatabaseAPI.updateUserProfile(user);
      await DatabaseAPI.rebuildUserBalanceFromLedger(userId);

      // 6. Global Daily Pool (35% Split) & Daily Economy Record
      const todayDate = new Date().toISOString().split('T')[0];
      const rawRecords = await AsyncStorage.getItem('@daily_economy_records');
      const records: DailyEconomyRecord[] = rawRecords ? JSON.parse(rawRecords) : [];
      let todayRecord = records.find(r => r.date === todayDate);

      // Calculate total shares weight dynamically
      const activeUsers = await DatabaseAPI.getAllUsers();
      const totalSharesWeight = activeUsers
        .filter(u => u.status === 'active')
        .reduce((sum, u) => sum + (u.subscription.share_weight || 1), 0);

      if (todayRecord) {
        todayRecord.total_pool_coins += poolShare;
        todayRecord.total_shares_weight = totalSharesWeight;
        todayRecord.conversion_rate = todayRecord.total_pool_coins / (totalSharesWeight || 1);
        todayRecord.distributed_coins += actualUserReward;
      } else {
        todayRecord = {
          date: todayDate,
          total_pool_coins: poolShare,
          total_shares_weight: totalSharesWeight,
          conversion_rate: poolShare / (totalSharesWeight || 1),
          distributed_coins: actualUserReward,
          created_at: new Date().toISOString()
        };
        records.unshift(todayRecord);
      }
      await AsyncStorage.setItem('@daily_economy_records', JSON.stringify(records));

      // Dynamic ConversionRate logic - update exchange rate of the wallet dynamically!
      const newExchangeRate = Math.max(100, Math.min(10000, Math.round(1000 / (todayRecord.conversion_rate || 1))));
      await DatabaseAPI.updateWalletSettings(
        {
          ...walletSettings,
          exchange_rate: newExchangeRate
        },
        'Dynamic conversion rate update from daily ad pool activity',
        JSON.stringify(walletSettings),
        JSON.stringify({ ...walletSettings, exchange_rate: newExchangeRate })
      );

      // Send notification
      await DatabaseAPI.sendNotification(userId, {
        title_ar: 'مكافأة إعلان يومي',
        title_en: 'Daily Ad Reward',
        message_ar: `لقد حصلت على ${actualUserReward} عملة لمشاهدة الإعلان.`,
        message_en: `You received ${actualUserReward} coins for watching the ad.`,
        type: 'EARN'
      });

      return { success: true, coinsEarned: actualUserReward };

    } catch (e) {
      console.error('claimDailyAdReward failed:', e);
      return { success: false, error: 'unexpected_error' };
    } finally {
      if (lockId) {
        await DatabaseAPI.releaseLock(userId, lockId);
      }
    }
  },

  purchaseVIPSubscription: async (userId: string, plan: SubscriptionPlan): Promise<{ success: boolean; error?: string; newBalance?: number }> => {
    await DatabaseAPI.init();
    
    // Acquire lock
    let lockId: string | null = null;
    try {
      lockId = await DatabaseAPI.acquireLock(userId);
    } catch (lockError) {
      return { success: false, error: 'concurrency_lock_active' };
    }

    try {
      if (plan === 'free') {
        return { success: false, error: 'cannot_purchase_free' };
      }

      // Define plan prices & parameters
      let price = 0;
      let shareWeight = 1;
      let dailyEarningCap = 100;
      let durationDays = 0;

      switch (plan) {
        case 'monthly':
          price = 2500;
          shareWeight = 3;
          dailyEarningCap = 500;
          durationDays = 30;
          break;
        case '90days':
          price = 6000;
          shareWeight = 4;
          dailyEarningCap = 750;
          durationDays = 90;
          break;
        case 'yearly':
          price = 20000;
          shareWeight = 5;
          dailyEarningCap = 1000;
          durationDays = 365;
          break;
        case 'lifetime':
          price = 50000;
          shareWeight = 10;
          dailyEarningCap = 5000;
          durationDays = -1; // no expiry
          break;
        default:
          return { success: false, error: 'invalid_plan' };
      }

      // Fetch user profile
      const user = await DatabaseAPI.getUserProfile();
      if (user.coins < price) {
        return { success: false, error: 'insufficient_coins' };
      }

      // Deduct coins via SPEND transaction
      const walletSettings = await DatabaseAPI.getWalletSettings();
      const ledgerTxs = await DatabaseAPI.getWalletTransactions();
      const lastSeq = ledgerTxs.length > 0 ? Math.max(...ledgerTxs.map(t => t.sequence_number || 0)) : 0;

      const purchaseId = 'sub_' + Math.random().toString(36).substring(2, 11);
      const spendTx: WalletTransaction = {
        id: 'tx_' + Math.random().toString(36).substring(2, 11),
        user_id: userId,
        type: 'SPEND',
        coins: -price,
        usd_snapshot: -price / walletSettings.exchange_rate,
        reference_id: purchaseId,
        idempotency_key: `purchase_sub_${userId}_${plan}_${Date.now()}`,
        sequence_number: lastSeq + 1,
        created_at: new Date().toISOString()
      };

      await DatabaseAPI.saveWalletTransaction(spendTx);

      // Update user subscription details
      const startedAt = new Date().toISOString();
      const expiresAt = durationDays > 0 ? new Date(Date.now() + durationDays * 24 * 60 * 60 * 1000).toISOString() : null;

      user.subscription = {
        plan,
        started_at: startedAt,
        expires_at: expiresAt,
        status: 'active',
        activation_code_id: `VIP-${plan.toUpperCase()}-${Math.random().toString(36).substring(2, 8).toUpperCase()}`,
        share_weight: shareWeight,
        daily_earning_cap: dailyEarningCap,
        today_coins_earned: 0,
        ads_watched_today: 0,
        last_ad_watch_time: null
      };

      await DatabaseAPI.updateUserProfile(user);
      const newBalance = await DatabaseAPI.rebuildUserBalanceFromLedger(userId);

      // Send notification
      await DatabaseAPI.sendNotification(userId, {
        title_ar: 'اشتراك VIP ناجح',
        title_en: 'VIP Subscription Successful',
        message_ar: `لقد قمت بشراء اشتراك VIP (${plan}) بنجاح.`,
        message_en: `You have successfully purchased a VIP Subscription (${plan}).`,
        type: 'SPEND'
      });

      await DatabaseAPI.logAdminAction(
        `User ${userId} purchased VIP subscription: ${plan} for ${price} coins.`
      );

      return { success: true, newBalance };

    } catch (e) {
      console.error('purchaseVIPSubscription failed:', e);
      return { success: false, error: 'unexpected_error' };
    } finally {
      if (lockId) {
        await DatabaseAPI.releaseLock(userId, lockId);
      }
    }
  }
};

