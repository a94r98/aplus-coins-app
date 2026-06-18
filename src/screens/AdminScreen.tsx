import React, { useState, useEffect } from 'react';
import {
  StyleSheet,
  Text,
  View,
  ScrollView,
  TextInput,
  TouchableOpacity,
  Switch,
  Image,
  Dimensions,
  Alert,
  Modal,
  ViewStyle,
  TextStyle
} from 'react-native';
import { useTranslation } from 'react-i18next';
import { Ionicons, Feather } from '@expo/vector-icons';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { useApp } from '../services/store';
import {
  Category,
  Product,
  Purchase,
  ReferralRecord,
  ReferralSettings,
  WalletSettings,
  StoreWithdrawal,
  WalletTransaction,
  Notification,
  DatabaseAPI
} from '../services/api';

const { width } = Dimensions.get('window');

export default function AdminScreen() {
  const { t, i18n } = useTranslation();
  const isRTL = i18n.language === 'ar';
  
  const {
    categories,
    products,
    purchases,
    referrals,
    referralSettings,
    auditLogs,
    walletSettings,
    walletTransactions,
    storeWithdrawals,
    availableBalance,
    pendingBalance,
    totalEarned,
    financialIntegrityStatus,
    allUsers,
    approveWithdrawal,
    rejectWithdrawal,
    updateWalletSettings,
    rebuildWalletBalance,
    toggleUserFreeze,
    compensatingRollback,
    resetWalletSystem,
    createCategory,
    editCategory,
    removeCategory,
    createProduct,
    editProduct,
    removeProduct,
    updateReferralSettings,
    resetReferrals,
    logoutAdmin,
    refreshData,
    dailyEconomyRecords
  } = useApp();

  const totalReserves = dailyEconomyRecords.reduce((sum, r) => sum + r.total_pool_coins, 0);
  const totalLiabilities = allUsers.reduce((sum, u) => sum + (u.coins || 0), 0);
  const rpi = totalLiabilities > 0 ? (totalReserves / totalLiabilities) : 1.0;

  let solvencyColor = '#10B981'; // Green
  let solvencyStatus = t('solvency_safe', 'Safe');
  if (rpi < 0.2) {
    solvencyColor = '#EF4444'; // Red
    solvencyStatus = t('solvency_critical', 'Critical');
  } else if (rpi < 0.5) {
    solvencyColor = '#F59E0B'; // Yellow
    solvencyStatus = t('solvency_warning', 'Warning');
  }

  // Active Admin Screen Tab: 'categories' | 'products' | 'sales' | 'referrals' | 'wallet' | 'notifications'
  const [activeTab, setActiveTab] = useState<'categories' | 'products' | 'sales' | 'referrals' | 'wallet' | 'notifications'>('products');

  // Helper styles for dynamic RTL/LTR support
  const rowStyle: ViewStyle = { flexDirection: isRTL ? 'row-reverse' : 'row' };
  const textAlignStyle: TextStyle = { textAlign: isRTL ? 'right' : 'left' };
  const marginStartStyle = (val: number) => isRTL ? { marginRight: val } : { marginLeft: val };
  const marginEndStyle = (val: number) => isRTL ? { marginLeft: val } : { marginRight: val };

  // -------------------------------------------------------------
  // STATE FOR CATEGORY FORM
  // -------------------------------------------------------------
  const [catNameAr, setCatNameAr] = useState('');
  const [catNameEn, setCatNameEn] = useState('');
  const [catIcon, setCatIcon] = useState('card-outline');
  const [catColor, setCatColor] = useState('#00A896');
  const [catSort, setCatSort] = useState('1');
  const [catActive, setCatActive] = useState(true);
  const [editingCategory, setEditingCategory] = useState<Category | null>(null);

  // -------------------------------------------------------------
  // STATE FOR PRODUCT FORM
  // -------------------------------------------------------------
  const [prodTitleAr, setProdTitleAr] = useState('');
  const [prodTitleEn, setProdTitleEn] = useState('');
  const [prodDescAr, setProdDescAr] = useState('');
  const [prodDescEn, setProdDescEn] = useState('');
  const [prodImage, setProdImage] = useState('https://images.unsplash.com/photo-1579546929518-9e396f3cc809?w=150');
  const [prodPrice, setProdPrice] = useState('');
  const [prodStock, setProdStock] = useState('');
  const [prodCatId, setProdCatId] = useState('');
  const [prodActive, setProdActive] = useState(true);
  const [prodVip, setProdVip] = useState(false);
  const [editingProduct, setEditingProduct] = useState<Product | null>(null);
  
  // Custom picker modal state
  const [pickerVisible, setPickerVisible] = useState(false);

  // -------------------------------------------------------------
  // STATE FOR REFERRAL CONTROL
  // -------------------------------------------------------------
  const [refActive, setRefActive] = useState(referralSettings?.active ?? true);
  const [refReferrerReward, setRefReferrerReward] = useState(referralSettings?.referrer_reward.toString() ?? '100');
  const [refReferredReward, setRefReferredReward] = useState(referralSettings?.referred_reward.toString() ?? '100');
  const [refVersion, setRefVersion] = useState(referralSettings?.version.toString() ?? '1');

  // -------------------------------------------------------------
  // STATE FOR WALLET MANAGEMENT
  // -------------------------------------------------------------
  const [walletExchangeRate, setWalletExchangeRate] = useState(walletSettings?.exchange_rate.toString() ?? '1000');
  const [walletMinWithdraw, setWalletMinWithdraw] = useState(walletSettings?.min_withdraw.toString() ?? '1000');
  const [walletMaxWithdraw, setWalletMaxWithdraw] = useState(walletSettings?.max_withdraw.toString() ?? '50000');
  const [walletWithdrawEnabled, setWalletWithdrawEnabled] = useState(walletSettings?.withdraw_enabled ?? true);
  const [walletSettingsReason, setWalletSettingsReason] = useState('Update wallet settings');
  const [txSearch, setTxSearch] = useState('');
  const [filteredTransactions, setFilteredTransactions] = useState<WalletTransaction[]>(walletTransactions);

  useEffect(() => {
    const filtered = walletTransactions.filter(tx => {
      if (!txSearch) return true;
      const term = txSearch.toLowerCase();
      return (
        tx.user_id.toLowerCase().includes(term) ||
        tx.reference_id.toLowerCase().includes(term) ||
        tx.type.toLowerCase().includes(term) ||
        tx.sequence_number.toString().includes(term)
      );
    });
    setFilteredTransactions(filtered);
  }, [txSearch, walletTransactions]);

  useEffect(() => {
    if (walletSettings) {
      setWalletExchangeRate(walletSettings.exchange_rate.toString());
      setWalletMinWithdraw(walletSettings.min_withdraw.toString());
      setWalletMaxWithdraw(walletSettings.max_withdraw.toString());
      setWalletWithdrawEnabled(walletSettings.withdraw_enabled);
    }
  }, [walletSettings]);

  // Reset confirmation states (4-step secure pipeline)
  const [resetConfirmVisible, setResetConfirmVisible] = useState(false);
  const [resetStep, setResetStep] = useState<1 | 2 | 3>(1);
  const [resetPinInput, setResetPinInput] = useState('');
  const [resetPinError, setResetPinError] = useState('');

  // -------------------------------------------------------------
  // STATE & LOGIC FOR NOTIFICATION BROADCASTER & SCHEDULER
  // -------------------------------------------------------------
  const [notifTitleAr, setNotifTitleAr] = useState('');
  const [notifTitleEn, setNotifTitleEn] = useState('');
  const [notifMessageAr, setNotifMessageAr] = useState('');
  const [notifMessageEn, setNotifMessageEn] = useState('');
  const [notifType, setNotifType] = useState<Notification['type']>('SYSTEM');
  const [notifTarget, setNotifTarget] = useState<'all' | 'vip' | 'active' | 'inactive' | 'specific'>('all');
  const [specificUserId, setSpecificUserId] = useState('');
  const [notifDelayMin, setNotifDelayMin] = useState('0');
  const [scheduledNotifs, setScheduledNotifs] = useState<Notification[]>([]);

  const fetchScheduledNotifs = async () => {
    try {
      const data = await AsyncStorage.getItem('@notifications');
      const allNotifs: Notification[] = data ? JSON.parse(data) : [];
      const now = Date.now();
      const scheduled = allNotifs.filter(n => n.scheduled_at && new Date(n.scheduled_at).getTime() > now);
      setScheduledNotifs(scheduled);
    } catch (e) {
      console.error(e);
    }
  };

  useEffect(() => {
    if (activeTab === 'notifications') {
      fetchScheduledNotifs();
    }
  }, [activeTab]);

  const handleBroadcast = async () => {
    if (!notifTitleAr || !notifTitleEn || !notifMessageAr || !notifMessageEn) {
      Alert.alert(t('error', 'Error'), t('fill_required', 'Please fill all fields.'));
      return;
    }

    const delayMs = (parseInt(notifDelayMin) || 0) * 60 * 1000;
    const isScheduled = delayMs > 0;
    const scheduledAt = isScheduled ? new Date(Date.now() + delayMs).toISOString() : undefined;

    const notifDetails = {
      title_ar: notifTitleAr,
      title_en: notifTitleEn,
      message_ar: notifMessageAr,
      message_en: notifMessageEn,
      type: notifType,
      scheduled_at: scheduledAt
    };

    try {
      if (notifTarget === 'all') {
        const newNotif: Notification = {
          ...notifDetails,
          id: 'notif_' + Math.random().toString(36).substring(2, 11),
          user_id: 'all',
          read: false,
          created_at: new Date().toISOString()
        };
        await DatabaseAPI.saveNotification(newNotif);
        await DatabaseAPI.logAdminAction(
          `Admin Broadcast notification: ${notifDetails.title_en}`,
          'ADMIN_PIN',
          'Notification Broadcast',
          'N/A',
          JSON.stringify(newNotif)
        );
      } else {
        let targets: string[] = [];
        if (notifTarget === 'vip') {
          targets = allUsers.filter(u => u.subscription.plan !== 'free').map(u => u.id);
        } else if (notifTarget === 'active') {
          targets = allUsers.filter(u => u.status === 'active').map(u => u.id);
        } else if (notifTarget === 'inactive') {
          targets = allUsers.filter(u => u.status !== 'active').map(u => u.id);
        } else if (notifTarget === 'specific') {
          if (!specificUserId) {
            Alert.alert(t('error'), t('fill_required'));
            return;
          }
          targets = [specificUserId];
        }

        if (targets.length === 0) {
          Alert.alert(t('error'), 'No matching users found for target.');
          return;
        }

        for (const userId of targets) {
          const newNotif: Notification = {
            ...notifDetails,
            id: 'notif_' + Math.random().toString(36).substring(2, 11),
            user_id: userId,
            read: false,
            created_at: new Date().toISOString()
          };
          await DatabaseAPI.saveNotification(newNotif);
        }

        await DatabaseAPI.logAdminAction(
          `Admin targeted notification to ${notifTarget}: ${notifDetails.title_en} for ${targets.length} users`,
          'ADMIN_PIN',
          'Targeted Notification',
          'N/A',
          JSON.stringify({ notifDetails, targetCount: targets.length })
        );
      }

      Alert.alert(
        t('success'),
        isScheduled ? t('scheduled_success', 'Notification scheduled successfully!') : t('broadcast_success', 'Notification broadcast sent successfully!')
      );

      setNotifTitleAr('');
      setNotifTitleEn('');
      setNotifMessageAr('');
      setNotifMessageEn('');
      setNotifDelayMin('0');
      setSpecificUserId('');

      fetchScheduledNotifs();
      refreshData();
    } catch (e) {
      Alert.alert(t('error'), t('operation_failed'));
    }
  };

  const cancelScheduledNotification = async (id: string) => {
    try {
      const data = await AsyncStorage.getItem('@notifications');
      let allNotifs: Notification[] = data ? JSON.parse(data) : [];
      allNotifs = allNotifs.filter(n => n.id !== id);
      await AsyncStorage.setItem('@notifications', JSON.stringify(allNotifs));
      Alert.alert(t('success'), t('cancel_success'));
      fetchScheduledNotifs();
      refreshData();
    } catch (e) {
      Alert.alert(t('error'), t('operation_failed'));
    }
  };

  // -------------------------------------------------------------
  // CATEGORIES CRUD LOGIC
  // -------------------------------------------------------------
  const handleSaveCategory = async () => {
    if (!catNameAr || !catNameEn) {
      Alert.alert(t('error', 'Error'), t('fill_required', 'Please fill required fields.'));
      return;
    }

    try {
      if (editingCategory) {
        await editCategory({
          ...editingCategory,
          name_ar: catNameAr,
          name_en: catNameEn,
          icon: catIcon,
          color: catColor,
          sort_order: parseInt(catSort) || 1,
          active: catActive
        });
        setEditingCategory(null);
        Alert.alert(t('success', 'Success'), t('cat_updated_success', 'Category updated successfully!'));
      } else {
        await createCategory({
          name_ar: catNameAr,
          name_en: catNameEn,
          icon: catIcon,
          color: catColor,
          sort_order: parseInt(catSort) || 1,
          active: catActive
        });
        Alert.alert(t('success', 'Success'), t('cat_created_success', 'Category created successfully!'));
      }
      
      setCatNameAr('');
      setCatNameEn('');
      setCatIcon('card-outline');
      setCatColor('#00A896');
      setCatSort('1');
      setCatActive(true);
    } catch (e) {
      Alert.alert(t('error', 'Error'), t('operation_failed', 'Operation failed.'));
    }
  };

  const handleEditCategoryInit = (cat: Category) => {
    setEditingCategory(cat);
    setCatNameAr(cat.name_ar);
    setCatNameEn(cat.name_en);
    setCatIcon(cat.icon);
    setCatColor(cat.color);
    setCatSort(cat.sort_order.toString());
    setCatActive(cat.active);
  };

  const handleDeleteCategory = (id: string) => {
    Alert.alert(
      t('confirm_delete', 'Confirm Delete'),
      t('confirm_delete_cat_desc', 'Are you sure you want to delete this category?'),
      [
        { text: t('cancel', 'Cancel'), style: 'cancel' },
        { text: t('delete', 'Delete'), style: 'destructive', onPress: () => removeCategory(id) }
      ]
    );
  };

  // -------------------------------------------------------------
  // PRODUCTS CRUD LOGIC
  // -------------------------------------------------------------
  const handleSaveProduct = async () => {
    if (!prodTitleAr || !prodTitleEn || !prodPrice || !prodStock || !prodCatId) {
      Alert.alert(t('error', 'Error'), t('fill_required', 'Please fill required fields.'));
      return;
    }

    try {
      if (editingProduct) {
        await editProduct({
          ...editingProduct,
          title_ar: prodTitleAr,
          title_en: prodTitleEn,
          description_ar: prodDescAr,
          description_en: prodDescEn,
          image: prodImage,
          price_coins: parseInt(prodPrice) || 0,
          stock: parseInt(prodStock) || 0,
          category_id: prodCatId,
          active: prodActive,
          vip_only: prodVip
        });
        setEditingProduct(null);
        Alert.alert(t('success', 'Success'), t('prod_updated_success', 'Product updated successfully!'));
      } else {
        await createProduct({
          title_ar: prodTitleAr,
          title_en: prodTitleEn,
          description_ar: prodDescAr,
          description_en: prodDescEn,
          image: prodImage,
          price_coins: parseInt(prodPrice) || 0,
          stock: parseInt(prodStock) || 0,
          category_id: prodCatId,
          active: prodActive,
          vip_only: prodVip
        });
        Alert.alert(t('success', 'Success'), t('prod_created_success', 'Product created successfully!'));
      }

      setProdTitleAr('');
      setProdTitleEn('');
      setProdDescAr('');
      setProdDescEn('');
      setProdImage('https://images.unsplash.com/photo-1579546929518-9e396f3cc809?w=150');
      setProdPrice('');
      setProdStock('');
      setProdCatId('');
      setProdActive(true);
      setProdVip(false);
    } catch (e) {
      Alert.alert(t('error', 'Error'), t('operation_failed', 'Operation failed.'));
    }
  };

  const handleEditProductInit = (prod: Product) => {
    setEditingProduct(prod);
    setProdTitleAr(prod.title_ar);
    setProdTitleEn(prod.title_en);
    setProdDescAr(prod.description_ar);
    setProdDescEn(prod.description_en);
    setProdImage(prod.image);
    setProdPrice(prod.price_coins.toString());
    setProdStock(prod.stock.toString());
    setProdCatId(prod.category_id);
    setProdActive(prod.active);
    setProdVip(prod.vip_only);
  };

  const handleDeleteProduct = (id: string) => {
    Alert.alert(
      t('confirm_delete', 'Confirm Delete'),
      t('confirm_delete_prod_desc', 'Are you sure you want to delete this product?'),
      [
        { text: t('cancel', 'Cancel'), style: 'cancel' },
        { text: t('delete', 'Delete'), style: 'destructive', onPress: () => removeProduct(id) }
      ]
    );
  };

  const getCategoryName = (id: string) => {
    const cat = categories.find(c => c.id === id);
    if (!cat) return '';
    return isRTL ? cat.name_ar : cat.name_en;
  };

  // -------------------------------------------------------------
  // REFERRALS SETTINGS SAVE
  // -------------------------------------------------------------
  const handleSaveReferralSettings = async () => {
    try {
      await updateReferralSettings({
        active: refActive,
        referrer_reward: parseInt(refReferrerReward) || 0,
        referred_reward: parseInt(refReferredReward) || 0,
        version: parseInt(refVersion) || 1,
        updated_at: new Date().toISOString()
      });
      Alert.alert(t('success', 'Success'), t('ref_settings_updated_success', 'Referral settings updated. Version incremented.'));
    } catch (e) {
      Alert.alert(t('error', 'Error'), t('operation_failed', 'Failed to update referral settings.'));
    }
  };

  // -------------------------------------------------------------
  // SECURE RESET LOGIC (4-Step Pipeline)
  // -------------------------------------------------------------
  const handleResetClick = () => {
    setResetStep(1);
    setResetPinInput('');
    setResetPinError('');
    setResetConfirmVisible(true);
  };

  const handleUpdateWalletSettings = async () => {
    if (!walletSettings) return;
    const updatedSettings: WalletSettings = {
      ...walletSettings,
      exchange_rate: parseInt(walletExchangeRate) || walletSettings.exchange_rate,
      min_withdraw: parseInt(walletMinWithdraw) || walletSettings.min_withdraw,
      max_withdraw: parseInt(walletMaxWithdraw) || walletSettings.max_withdraw,
      withdraw_enabled: walletWithdrawEnabled,
      version: walletSettings.version + 1
    };

    const beforeState = JSON.stringify(walletSettings);
    const afterState = JSON.stringify(updatedSettings);
    await updateWalletSettings(updatedSettings, walletSettingsReason, beforeState, afterState);
    Alert.alert(t('success', 'Success'), t('wallet_settings_updated', 'Wallet settings were updated successfully.'));
  };

  const handleSearchTransactions = (query: string) => {
    setTxSearch(query);
  };

  const handleResetSubmit = async () => {
    if (resetStep === 1) {
      setResetStep(2);
    } else if (resetStep === 2) {
      setResetStep(3);
    } else if (resetStep === 3) {
      if (resetPinInput === '1234') { // Secure Admin PIN Validation
        setResetConfirmVisible(false);
        await resetReferrals();
        Alert.alert(t('success', 'Success'), t('system_reset_success', 'Referral logs and counters reset completely.'));
      } else {
        setResetPinError(t('wrong_pin', 'Incorrect PIN code. Try again.'));
      }
    }
  };

  // Calculate General Stats
  const totalCoinsPaid = referrals.filter(r => r.status === 'SUCCESS').reduce((sum, r) => sum + r.reward_coins, 0);
  const totalBlockedRefs = referrals.filter(r => r.status === 'BLOCKED').length;

  return (
    <View style={styles.container}>
      
      {/* Header */}
      <View style={[styles.header, rowStyle]}>
        <View style={styles.headerTitleRow}>
          <Feather name="shield" size={24} color="#00A896" />
          <Text style={[styles.headerTitle, marginStartStyle(8)]}>{t('admin_panel', 'Admin Panel')}</Text>
        </View>
        <TouchableOpacity style={styles.logoutBtn} onPress={logoutAdmin}>
          <Feather name="log-out" size={20} color="#FF5A5F" />
        </TouchableOpacity>
      </View>

      {/* Tabs */}
      <View style={{ backgroundColor: '#FFFFFF', borderBottomWidth: 1, borderColor: '#E2E8F0' }}>
        <ScrollView 
          horizontal 
          showsHorizontalScrollIndicator={false} 
          contentContainerStyle={[rowStyle, { paddingVertical: 8, paddingHorizontal: 12, alignItems: 'center' }]}
        >
          <TouchableOpacity
            style={[styles.tabButton, activeTab === 'products' ? styles.tabButtonActive : null, { paddingHorizontal: 12, minWidth: 80 }]}
            onPress={() => setActiveTab('products')}
          >
            <Text style={[styles.tabText, activeTab === 'products' ? styles.tabTextActive : null]}>
              {t('products_tab', 'Products')}
            </Text>
          </TouchableOpacity>

          <TouchableOpacity
            style={[styles.tabButton, activeTab === 'categories' ? styles.tabButtonActive : null, { paddingHorizontal: 12, minWidth: 80 }]}
            onPress={() => setActiveTab('categories')}
          >
            <Text style={[styles.tabText, activeTab === 'categories' ? styles.tabTextActive : null]}>
              {t('categories_tab', 'Categories')}
            </Text>
          </TouchableOpacity>

          <TouchableOpacity
            style={[styles.tabButton, activeTab === 'referrals' ? styles.tabButtonActive : null, { paddingHorizontal: 12, minWidth: 80 }]}
            onPress={() => setActiveTab('referrals')}
          >
            <Text style={[styles.tabText, activeTab === 'referrals' ? styles.tabTextActive : null]}>
              {t('store_referrals', 'Referrals')}
            </Text>
          </TouchableOpacity>

          <TouchableOpacity
            style={[styles.tabButton, activeTab === 'wallet' ? styles.tabButtonActive : null, { paddingHorizontal: 12, minWidth: 80 }]}
            onPress={() => setActiveTab('wallet')}
          >
            <Text style={[styles.tabText, activeTab === 'wallet' ? styles.tabTextActive : null]}>
              {t('wallet_tab', 'Wallet')}
            </Text>
          </TouchableOpacity>

          <TouchableOpacity
            style={[styles.tabButton, activeTab === 'sales' ? styles.tabButtonActive : null, { paddingHorizontal: 12, minWidth: 80 }]}
            onPress={() => setActiveTab('sales')}
          >
            <Text style={[styles.tabText, activeTab === 'sales' ? styles.tabTextActive : null]}>
              {t('sales_tab', 'Logs')}
            </Text>
          </TouchableOpacity>

          <TouchableOpacity
            style={[styles.tabButton, activeTab === 'notifications' ? styles.tabButtonActive : null, { paddingHorizontal: 12, minWidth: 120 }]}
            onPress={() => setActiveTab('notifications')}
          >
            <Text style={[styles.tabText, activeTab === 'notifications' ? styles.tabTextActive : null]}>
              {t('notification_hub', 'Notification Hub')}
            </Text>
          </TouchableOpacity>
        </ScrollView>
      </View>

      <ScrollView contentContainerStyle={styles.scrollContent} showsVerticalScrollIndicator={false}>
        
        {/* ========================================================= */}
        {/* TAB 1: PRODUCTS MANAGER */}
        {/* ========================================================= */}
        {activeTab === 'products' && (
          <View>
            <Text style={[styles.sectionTitle, textAlignStyle]}>
              {editingProduct ? t('edit_product', 'Edit Product') : t('add_new_product', 'Add New Product')}
            </Text>
            
            <View style={styles.formCard}>
              <TextInput
                style={[styles.input, textAlignStyle]}
                placeholder={t('prod_title_ar', 'Product Name (Arabic) *')}
                value={prodTitleAr}
                onChangeText={setProdTitleAr}
              />
              <TextInput
                style={[styles.input, textAlignStyle]}
                placeholder={t('prod_title_en', 'Product Name (English) *')}
                value={prodTitleEn}
                onChangeText={setProdTitleEn}
              />
              <TextInput
                style={[styles.input, styles.textArea, textAlignStyle]}
                placeholder={t('prod_desc_ar', 'Description (Arabic)')}
                value={prodDescAr}
                onChangeText={setProdDescAr}
                multiline
                numberOfLines={3}
              />
              <TextInput
                style={[styles.input, styles.textArea, textAlignStyle]}
                placeholder={t('prod_desc_en', 'Description (English)')}
                value={prodDescEn}
                onChangeText={setProdDescEn}
                multiline
                numberOfLines={3}
              />
              
              <View style={[styles.inputRow, rowStyle]}>
                <TextInput
                  style={[styles.input, { flex: 1 }, marginEndStyle(8), textAlignStyle]}
                  placeholder={t('price_coins', 'Price (Coins) *')}
                  value={prodPrice}
                  onChangeText={setProdPrice}
                  keyboardType="numeric"
                />
                <TextInput
                  style={[styles.input, { flex: 1 }, textAlignStyle]}
                  placeholder={t('stock_qty', 'Stock Quantity *')}
                  value={prodStock}
                  onChangeText={setProdStock}
                  keyboardType="numeric"
                />
              </View>

              <TouchableOpacity style={[styles.pickerButton, rowStyle]} onPress={() => setPickerVisible(true)}>
                <Text style={styles.pickerButtonText}>
                  {prodCatId 
                    ? getCategoryName(prodCatId) 
                    : t('select_category', 'Select Category *')}
                </Text>
                <Ionicons name="chevron-down" size={18} color="#64748B" />
              </TouchableOpacity>

              <TextInput
                style={[styles.input, textAlignStyle]}
                placeholder={t('image_url', 'Image URL')}
                value={prodImage}
                onChangeText={setProdImage}
              />

              <View style={[styles.switchRow, rowStyle]}>
                <Text style={styles.switchLabel}>{t('active_status', 'Active')}</Text>
                <Switch value={prodActive} onValueChange={setProdActive} trackColor={{ true: '#00A896' }} />
              </View>

              <View style={[styles.switchRow, rowStyle]}>
                <Text style={styles.switchLabel}>{t('vip_only_status', 'VIP Only')}</Text>
                <Switch value={prodVip} onValueChange={setProdVip} trackColor={{ true: '#00A896' }} />
              </View>

              <TouchableOpacity style={styles.submitBtn} onPress={handleSaveProduct}>
                <Text style={styles.submitBtnText}>
                  {editingProduct ? t('update', 'Update Product') : t('save', 'Save Product')}
                </Text>
              </TouchableOpacity>
              
              {editingProduct && (
                <TouchableOpacity 
                  style={[styles.submitBtn, { backgroundColor: '#64748B', marginTop: 8 }]} 
                  onPress={() => {
                    setEditingProduct(null);
                    setProdTitleAr('');
                    setProdTitleEn('');
                    setProdDescAr('');
                    setProdDescEn('');
                    setProdPrice('');
                    setProdStock('');
                    setProdCatId('');
                  }}
                >
                  <Text style={styles.submitBtnText}>{t('cancel', 'Cancel')}</Text>
                </TouchableOpacity>
              )}
            </View>

            <Text style={[styles.sectionTitle, textAlignStyle, { marginTop: 24 }]}>
              {t('current_products', 'Current Products')}
            </Text>
            
            {products.map(prod => (
              <View key={prod.id} style={[styles.listCard, rowStyle]}>
                <Image source={{ uri: prod.image }} style={styles.listCardImage} />
                <View style={[styles.listCardDetails, marginStartStyle(12)]}>
                  <Text style={[styles.listCardTitle, textAlignStyle]}>
                    {isRTL ? prod.title_ar : prod.title_en}
                  </Text>
                  <Text style={[styles.listCardSub, textAlignStyle]}>
                    {t('price', 'Price')}: {prod.price_coins} | {t('stock', 'Stock')}: {prod.stock}
                  </Text>
                  <Text style={[styles.listCardCat, textAlignStyle]}>
                    {getCategoryName(prod.category_id)}
                  </Text>
                </View>
                <View style={styles.listCardActions}>
                  <TouchableOpacity style={styles.actionBtnEdit} onPress={() => handleEditProductInit(prod)}>
                    <Feather name="edit" size={18} color="#00A896" />
                  </TouchableOpacity>
                  <TouchableOpacity style={styles.actionBtnDelete} onPress={() => handleDeleteProduct(prod.id)}>
                    <Feather name="trash-2" size={18} color="#FF5A5F" />
                  </TouchableOpacity>
                </View>
              </View>
            ))}
          </View>
        )}

        {/* ========================================================= */}
        {/* TAB 2: CATEGORIES MANAGER */}
        {/* ========================================================= */}
        {activeTab === 'categories' && (
          <View>
            <Text style={[styles.sectionTitle, textAlignStyle]}>
              {editingCategory ? t('edit_category', 'Edit Category') : t('add_new_category', 'Add New Category')}
            </Text>

            <View style={styles.formCard}>
              <TextInput
                style={[styles.input, textAlignStyle]}
                placeholder={t('cat_name_ar', 'Category Name (Arabic) *')}
                value={catNameAr}
                onChangeText={setCatNameAr}
              />
              <TextInput
                style={[styles.input, textAlignStyle]}
                placeholder={t('cat_name_en', 'Category Name (English) *')}
                value={catNameEn}
                onChangeText={setCatNameEn}
              />
              <View style={[styles.inputRow, rowStyle]}>
                <TextInput
                  style={[styles.input, { flex: 1 }, marginEndStyle(8), textAlignStyle]}
                  placeholder={t('cat_icon', 'Ionicons Name')}
                  value={catIcon}
                  onChangeText={setCatIcon}
                />
                <TextInput
                  style={[styles.input, { flex: 1 }, textAlignStyle]}
                  placeholder={t('cat_color', 'HEX Color')}
                  value={catColor}
                  onChangeText={setCatColor}
                />
              </View>

              <TextInput
                style={[styles.input, textAlignStyle]}
                placeholder={t('sort_order', 'Sort Order')}
                value={catSort}
                onChangeText={setCatSort}
                keyboardType="numeric"
              />

              <View style={[styles.switchRow, rowStyle]}>
                <Text style={styles.switchLabel}>{t('active_status', 'Active')}</Text>
                <Switch value={catActive} onValueChange={setCatActive} trackColor={{ true: '#00A896' }} />
              </View>

              <TouchableOpacity style={styles.submitBtn} onPress={handleSaveCategory}>
                <Text style={styles.submitBtnText}>
                  {editingCategory ? t('update', 'Update Category') : t('save', 'Save Category')}
                </Text>
              </TouchableOpacity>
              
              {editingCategory && (
                <TouchableOpacity 
                  style={[styles.submitBtn, { backgroundColor: '#64748B', marginTop: 8 }]} 
                  onPress={() => {
                    setEditingCategory(null);
                    setCatNameAr('');
                    setCatNameEn('');
                    setCatIcon('card-outline');
                    setCatColor('#00A896');
                    setCatSort('1');
                  }}
                >
                  <Text style={styles.submitBtnText}>{t('cancel', 'Cancel')}</Text>
                </TouchableOpacity>
              )}
            </View>

            <Text style={[styles.sectionTitle, textAlignStyle, { marginTop: 24 }]}>
              {t('current_categories', 'Current Categories')}
            </Text>

            {categories.map(cat => (
              <View key={cat.id} style={[styles.listCard, rowStyle, { paddingVertical: 16 }]}>
                <View style={styles.catIconCircle}>
                  <Ionicons name={cat.icon as any} size={22} color={cat.color || '#00A896'} />
                </View>
                <View style={[styles.listCardDetails, marginStartStyle(12)]}>
                  <Text style={[styles.listCardTitle, textAlignStyle]}>
                    {isRTL ? cat.name_ar : cat.name_en}
                  </Text>
                  <Text style={[styles.listCardSub, textAlignStyle]}>
                    {t('sort_order', 'Sort')}: {cat.sort_order} | {t('status', 'Status')}: {cat.active ? t('active', 'Active') : t('inactive', 'Inactive')}
                  </Text>
                </View>
                <View style={styles.listCardActions}>
                  <TouchableOpacity style={styles.actionBtnEdit} onPress={() => handleEditCategoryInit(cat)}>
                    <Feather name="edit" size={18} color="#00A896" />
                  </TouchableOpacity>
                  <TouchableOpacity style={styles.actionBtnDelete} onPress={() => handleDeleteCategory(cat.id)}>
                    <Feather name="trash-2" size={18} color="#FF5A5F" />
                  </TouchableOpacity>
                </View>
              </View>
            ))}
          </View>
        )}

        {/* ========================================================= */}
        {/* TAB 3: REFERRALS SYSTEM MANAGER */}
        {/* ========================================================= */}
        {activeTab === 'referrals' && (
          <View>
            <Text style={[styles.sectionTitle, textAlignStyle]}>
              {t('referral_settings_title', 'Referral System Configuration')}
            </Text>
            
            {/* Referral Settings Card */}
            <View style={styles.formCard}>
              <View style={[styles.switchRow, rowStyle]}>
                <Text style={styles.switchLabel}>{t('enable_referral_sys', 'Enable Referral System')}</Text>
                <Switch value={refActive} onValueChange={setRefActive} trackColor={{ true: '#00A896' }} />
              </View>

              <TextInput
                style={[styles.input, textAlignStyle]}
                placeholder={t('ref_reward', 'Referrer Reward (Coins) *')}
                value={refReferrerReward}
                onChangeText={setRefReferrerReward}
                keyboardType="numeric"
              />

              <TextInput
                style={[styles.input, textAlignStyle]}
                placeholder={t('referred_reward_lbl', 'New User Reward (Coins) *')}
                value={refReferredReward}
                onChangeText={setRefReferredReward}
                keyboardType="numeric"
              />

              <TextInput
                style={[styles.input, textAlignStyle]}
                placeholder={t('rules_version', 'Rules Settings Version *')}
                value={refVersion}
                onChangeText={setRefVersion}
                keyboardType="numeric"
              />

              <TouchableOpacity style={styles.submitBtn} onPress={handleSaveReferralSettings}>
                <Text style={styles.submitBtnText}>{t('update_settings', 'Update Settings')}</Text>
              </TouchableOpacity>
            </View>

            {/* General Referral Analytics */}
            <Text style={[styles.sectionTitle, textAlignStyle, { marginTop: 24 }]}>
              {t('referral_analytics', 'Referral System Analytics')}
            </Text>

            <View style={[styles.analyticsContainer, rowStyle]}>
              <View style={styles.analyticsBox}>
                <Text style={styles.analyticsVal}>{referrals.filter(r => r.status === 'SUCCESS').length}</Text>
                <Text style={styles.analyticsLabel}>{t('total_referrals', 'Total Referrals')}</Text>
              </View>

              <View style={styles.analyticsBox}>
                <Text style={styles.analyticsVal}>{totalCoinsPaid.toLocaleString()}</Text>
                <Text style={styles.analyticsLabel}>{t('total_payouts', 'Total Payouts')}</Text>
              </View>

              <View style={styles.analyticsBox}>
                <Text style={[styles.analyticsVal, { color: '#FF5A5F' }]}>{totalBlockedRefs}</Text>
                <Text style={styles.analyticsLabel}>{t('blocked_attempts', 'Blocked (Rate/Security)')}</Text>
              </View>
            </View>

            {/* Secure Reset System (4-Step Pipeline) */}
            <View style={styles.resetCard}>
              <Text style={styles.resetTitle}>{t('danger_zone', 'DANGER ZONE')}</Text>
              <Text style={styles.resetDesc}>
                {t('reset_desc', 'Reset all referral invite counts and delete referral logs. Action is irreversible.')}
              </Text>
              <TouchableOpacity style={styles.resetBtn} onPress={handleResetClick}>
                <Text style={styles.resetBtnText}>{t('reset_system', 'Reset System Logs')}</Text>
              </TouchableOpacity>
            </View>

          </View>
        )}

        {/* ========================================================= */}
        {/* TAB 4: WALLET SYSTEM MANAGER */}
        {/* ========================================================= */}
        {activeTab === 'wallet' && (
          <View>
            <Text style={[styles.sectionTitle, textAlignStyle]}>{t('wallet_admin_title', 'Wallet System Manager')}</Text>

            <View style={styles.walletStatsGrid}>
              <View style={styles.walletStatCard}>
                <Text style={styles.walletStatLabel}>{t('available_balance', 'Available Balance')}</Text>
                <Text style={styles.walletStatValue}>{availableBalance.toLocaleString()} Coins</Text>
              </View>
              <View style={styles.walletStatCard}>
                <Text style={styles.walletStatLabel}>{t('pending_balance', 'Pending Withdrawals')}</Text>
                <Text style={styles.walletStatValue}>{pendingBalance.toLocaleString()} Coins</Text>
              </View>
              <View style={styles.walletStatCard}>
                <Text style={styles.walletStatLabel}>{t('total_earned', 'Total Earned')}</Text>
                <Text style={styles.walletStatValue}>{totalEarned.toLocaleString()} Coins</Text>
              </View>
            </View>

            {/* System Solvency Dashboard */}
            <View style={[styles.formCard, { borderLeftWidth: 4, borderLeftColor: solvencyColor, marginTop: 16 }]}>
              <Text style={[styles.sectionTitle, textAlignStyle, { marginBottom: 8 }]}>
                {t('solvency_dashboard', 'System Solvency Dashboard')}
              </Text>
              <View style={[styles.switchRow, rowStyle, { paddingVertical: 4 }]}>
                <Text style={styles.switchLabel}>{t('rpi_index', 'Reserve-to-Liability (RPI)')}:</Text>
                <Text style={{ fontWeight: 'bold', fontSize: 16, color: solvencyColor }}>
                  {(rpi * 100).toFixed(1)}%
                </Text>
              </View>
              <View style={[styles.switchRow, rowStyle, { paddingVertical: 4 }]}>
                <Text style={styles.switchLabel}>{t('solvency_status', 'Solvency Status')}:</Text>
                <Text style={{ fontWeight: 'bold', color: solvencyColor }}>{solvencyStatus}</Text>
              </View>
              <View style={[styles.switchRow, rowStyle, { paddingVertical: 4 }]}>
                <Text style={styles.switchLabel}>{t('total_reserves_label', 'Total Reserves (35% Pool)')}:</Text>
                <Text style={{ fontWeight: 'bold' }}>{totalReserves.toLocaleString()} Coins</Text>
              </View>
              <View style={[styles.switchRow, rowStyle, { paddingVertical: 4 }]}>
                <Text style={styles.switchLabel}>{t('total_liabilities_label', 'Total Liabilities (User Balances)')}:</Text>
                <Text style={{ fontWeight: 'bold' }}>{totalLiabilities.toLocaleString()} Coins</Text>
              </View>
            </View>

            {/* Daily Economy Split Data */}
            <View style={[styles.formCard, { marginTop: 16 }]}>
              <Text style={[styles.sectionTitle, textAlignStyle, { marginBottom: 8 }]}>
                {t('daily_economy_split', 'Daily Economy Split Data (50/15/35)')}
              </Text>
              <Text style={[styles.emptyLogsText, textAlignStyle, { marginBottom: 12, fontSize: 12, color: '#64748B' }]}>
                {t('economy_split_desc', 'Daily ad activity splits: 50% user profit, 15% referrer commission, 35% system reserve.')}
              </Text>
              {dailyEconomyRecords.length === 0 ? (
                <Text style={styles.emptyLogsText}>{t('no_economy_records', 'No economy records logged yet.')}</Text>
              ) : (
                dailyEconomyRecords.map((record) => (
                  <View key={record.date} style={{ borderBottomWidth: 1, borderBottomColor: '#E2E8F0', paddingVertical: 8 }}>
                    <View style={[rowStyle, { justifyContent: 'space-between' }]}>
                      <Text style={{ fontWeight: 'bold' }}>{record.date}</Text>
                      <Text style={{ color: '#00A896', fontWeight: 'bold' }}>
                        {t('value_per_share_label', 'Share Val')}: {record.conversion_rate.toFixed(3)}
                      </Text>
                    </View>
                    <View style={[rowStyle, { justifyContent: 'space-between', marginTop: 4 }]}>
                      <Text style={{ fontSize: 12, color: '#64748B' }}>
                        {t('shares_lbl', 'Total Shares')}: {record.total_shares_weight}
                      </Text>
                      <Text style={{ fontSize: 12, color: '#64748B' }}>
                        {t('pool_lbl', 'Reserve (35%)')}: {record.total_pool_coins.toFixed(0)}
                      </Text>
                      <Text style={{ fontSize: 12, color: '#64748B' }}>
                        {t('dist_lbl', 'Profits (50%)')}: {record.distributed_coins.toFixed(0)}
                      </Text>
                    </View>
                  </View>
                ))
              )}
            </View>

            <View style={styles.formCard}>
              <Text style={[styles.sectionTitle, textAlignStyle, { marginBottom: 8 }]}>{t('wallet_settings', 'Wallet Settings')}</Text>
              <TextInput
                style={[styles.input, textAlignStyle]}
                placeholder={t('exchange_rate', 'Exchange Rate (Coins per USD)')}
                value={walletExchangeRate}
                onChangeText={setWalletExchangeRate}
                keyboardType="numeric"
              />
              <TextInput
                style={[styles.input, textAlignStyle]}
                placeholder={t('min_withdraw', 'Minimum Withdraw (Coins)')}
                value={walletMinWithdraw}
                onChangeText={setWalletMinWithdraw}
                keyboardType="numeric"
              />
              <TextInput
                style={[styles.input, textAlignStyle]}
                placeholder={t('max_withdraw', 'Maximum Withdraw (Coins)')}
                value={walletMaxWithdraw}
                onChangeText={setWalletMaxWithdraw}
                keyboardType="numeric"
              />
              <View style={[styles.switchRow, rowStyle]}>
                <Text style={styles.switchLabel}>{t('withdraw_enabled', 'Withdrawals Enabled')}</Text>
                <Switch value={walletWithdrawEnabled} onValueChange={setWalletWithdrawEnabled} trackColor={{ true: '#00A896' }} />
              </View>
              <TextInput
                style={[styles.input, textAlignStyle]}
                placeholder={t('update_reason', 'Reason for change')}
                value={walletSettingsReason}
                onChangeText={setWalletSettingsReason}
              />
              <TouchableOpacity style={styles.submitBtn} onPress={handleUpdateWalletSettings}>
                <Text style={styles.submitBtnText}>{t('save_wallet_settings', 'Update Wallet Settings')}</Text>
              </TouchableOpacity>
            </View>

            <View style={[styles.sectionCard, { padding: 16, marginTop: 20 }]}> 
              <Text style={[styles.sectionTitle, textAlignStyle, { marginBottom: 12 }]}>{t('withdrawal_requests', 'Withdrawal Requests')}</Text>
              {storeWithdrawals.length === 0 ? (
                <Text style={styles.emptyLogsText}>{t('no_withdrawals', 'No withdrawal requests found.')}</Text>
              ) : (
                storeWithdrawals.map(withdrawal => (
                  <View key={withdrawal.id} style={[styles.withdrawalRow, rowStyle]}>
                    <View style={{ flex: 1 }}>
                      <Text style={styles.txTitle}>{withdrawal.user_id} • {withdrawal.method}</Text>
                      <Text style={styles.txRef}>{t('amount', 'Amount')}: {withdrawal.coins.toLocaleString()} Coins</Text>
                      <Text style={styles.txRef}>{t('status', 'Status')}: {withdrawal.status}</Text>
                      <Text style={styles.txDate}>{new Date(withdrawal.created_at).toLocaleString()}</Text>
                    </View>
                    {withdrawal.status === 'pending' && (
                      <View style={styles.withdrawalActions}>
                        <TouchableOpacity style={[styles.actionBtnEdit, { marginBottom: 8 }]} onPress={() => approveWithdrawal(withdrawal.id)}>
                          <Feather name="check" size={18} color="#FFFFFF" />
                        </TouchableOpacity>
                        <TouchableOpacity style={styles.actionBtnDelete} onPress={() => {
                          Alert.alert(
                            t('reject_withdrawal', 'Reject Withdrawal'),
                            t('reject_withdrawal_confirm', 'Reject and refund this withdrawal request?'),
                            [
                              { text: t('cancel', 'Cancel'), style: 'cancel' },
                              { text: t('reject', 'Reject'), onPress: () => rejectWithdrawal(withdrawal.id, 'Rejected by admin') }
                            ]
                          );
                        }}>
                          <Feather name="x" size={18} color="#FFFFFF" />
                        </TouchableOpacity>
                      </View>
                    )}
                  </View>
                ))
              )}
            </View>

            <View style={[styles.sectionCard, { padding: 16, marginTop: 20 }]}> 
              <Text style={[styles.sectionTitle, textAlignStyle, { marginBottom: 12 }]}>{t('user_freeze_controls', 'User Freeze Controls')}</Text>
              {allUsers.map(user => (
                <View key={user.id} style={[styles.freezeRow, rowStyle]}>
                  <View style={{ flex: 1 }}>
                    <Text style={styles.txTitle}>{user.name} ({user.id})</Text>
                    <Text style={styles.txRef}>{t('withdraw_status', 'Withdraw Frozen')}: {user.withdraw_frozen ? t('yes', 'Yes') : t('no', 'No')}</Text>
                  </View>
                  <TouchableOpacity
                    style={[styles.submitBtn, { paddingHorizontal: 16, backgroundColor: user.withdraw_frozen ? '#00A896' : '#FF5A5F' }]}
                    onPress={() => toggleUserFreeze(user.id, !user.withdraw_frozen)}
                  >
                    <Text style={styles.submitBtnText}>{user.withdraw_frozen ? t('unfreeze', 'Unfreeze') : t('freeze', 'Freeze')}</Text>
                  </TouchableOpacity>
                </View>
              ))}
            </View>

            <View style={[styles.sectionCard, { padding: 16, marginTop: 20 }]}> 
              <Text style={[styles.sectionTitle, textAlignStyle, { marginBottom: 12 }]}>{t('transaction_inspector', 'Transaction Inspector')}</Text>
              <TextInput
                style={[styles.input, textAlignStyle]}
                placeholder={t('search_transactions', 'Search by user_id / reference_id / sequence')}
                value={txSearch}
                onChangeText={handleSearchTransactions}
              />
              {filteredTransactions.length === 0 ? (
                <Text style={styles.emptyLogsText}>{t('no_transactions', 'No matching transactions found.')}</Text>
              ) : (
                filteredTransactions.map(tx => (
                  <View key={tx.id} style={[styles.transactionRow, rowStyle]}>
                    <View style={{ flex: 1 }}>
                      <Text style={styles.txTitle}>#{tx.sequence_number} • {tx.type}</Text>
                      <Text style={styles.txRef}>{t('reference', 'Reference')}: {tx.reference_id}</Text>
                      <Text style={styles.txRef}>{t('user', 'User')}: {tx.user_id} • {new Date(tx.created_at).toLocaleString()}</Text>
                    </View>
                    <TouchableOpacity
                      style={[styles.actionBtnEdit, { backgroundColor: '#64748B' }]}
                      onPress={() => compensatingRollback(tx.user_id, tx.id)}
                    >
                      <Feather name="refresh-cw" size={18} color="#FFFFFF" />
                    </TouchableOpacity>
                  </View>
                ))
              )}
            </View>

            <View style={[styles.resetCard, { marginTop: 20 }]}> 
              <Text style={styles.resetTitle}>{t('emergency_controls', 'Emergency Controls')}</Text>
              <Text style={styles.resetDesc}>{t('emergency_desc', 'Run automatic ledger rebuild or full wallet reset if the ledger becomes inconsistent.')}</Text>
              <TouchableOpacity
                style={[styles.resetBtn, { backgroundColor: '#0F766E' }]}
                onPress={async () => {
                  await rebuildWalletBalance();
                  Alert.alert(t('success', 'Success'), t('ledger_rebuilt', 'Ledger rebuilt and cache synchronized.'));
                }}
              >
                <Text style={styles.resetBtnText}>{t('rebuild_ledger', 'Rebuild Ledger')}</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={[styles.resetBtn, { marginTop: 12, backgroundColor: '#EF4444' }]}
                onPress={() => {
                  Alert.alert(
                    t('confirm', 'Confirm'),
                    t('reset_wallet_confirm', 'Reset wallet system and transactions? This will seed the wallet back to initial state.'),
                    [
                      { text: t('cancel', 'Cancel'), style: 'cancel' },
                      { text: t('confirm', 'Confirm'), style: 'destructive', onPress: async () => {
                        await resetWalletSystem();
                        Alert.alert(t('success', 'Success'), t('wallet_reset_success', 'Wallet system has been reset.'));
                      }}
                    ]
                  );
                }}
              >
                <Text style={styles.resetBtnText}>{t('reset_wallet_system', 'Reset Wallet System')}</Text>
              </TouchableOpacity>
            </View>
          </View>
        )}

        {/* ========================================================= */}
        {/* TAB 5: LOGS & SECURITY AUDIT */}
        {activeTab === 'sales' && (
          <View>
            {/* Sales Table */}
            <Text style={[styles.sectionTitle, textAlignStyle]}>{t('sales_logs', 'Sales Log')}</Text>
            {purchases.length === 0 ? (
              <View style={styles.emptyLogs}>
                <Text style={styles.emptyLogsText}>{t('no_sales', 'No purchases recorded yet.')}</Text>
              </View>
            ) : (
              purchases.map(pur => {
                const prod = products.find(p => p.id === pur.product_id);
                return (
                  <View key={pur.id} style={styles.purchaseLogCard}>
                    <View style={[styles.logRow, rowStyle]}>
                      <Text style={styles.logTitle}>{isRTL ? prod?.title_ar : prod?.title_en}</Text>
                      <Text style={styles.logPrice}>{pur.price_coins} Coins</Text>
                    </View>
                    <View style={[styles.logRow, rowStyle, { marginTop: 4 }]}>
                      <Text style={styles.logCode}>{pur.delivery_code}</Text>
                      <Text style={styles.logDate}>{new Date(pur.created_at).toLocaleTimeString()}</Text>
                    </View>
                  </View>
                );
              })
            )}

            {/* Referrals Log */}
            <Text style={[styles.sectionTitle, textAlignStyle, { marginTop: 24 }]}>
              {t('referrals_log_title', 'Referrals Activity Log')}
            </Text>
            {referrals.length === 0 ? (
              <View style={styles.emptyLogs}>
                <Text style={styles.emptyLogsText}>{t('no_referrals_yet', 'No referrals recorded yet.')}</Text>
              </View>
            ) : (
              referrals.map(ref => (
                <View 
                  key={ref.id} 
                  style={[
                    styles.purchaseLogCard, 
                    ref.status === 'BLOCKED' ? { borderColor: '#FFEBEB', backgroundColor: '#FFFDFD' } : null
                  ]}
                >
                  <View style={[styles.logRow, rowStyle]}>
                    <Text style={[styles.logTitle, ref.status === 'BLOCKED' ? { color: '#FF5A5F' } : null]}>
                      {ref.status === 'BLOCKED' 
                        ? `[BLOCKED] ${ref.referred_name}` 
                        : `${ref.referred_name} -> Invited`}
                    </Text>
                    <Text style={[styles.logPrice, ref.status === 'BLOCKED' ? { color: '#FF5A5F' } : null]}>
                      +{ref.reward_coins} Coins
                    </Text>
                  </View>
                  <View style={[styles.logRow, rowStyle, { marginTop: 4 }]}>
                    <Text style={styles.logCode}>ID: {ref.referred_id.substring(0, 8)}</Text>
                    <Text style={styles.logDate}>{new Date(ref.timestamp).toLocaleTimeString()}</Text>
                  </View>
                </View>
              ))
            )}

            {/* Audit Security Log */}
            <Text style={[styles.sectionTitle, textAlignStyle, { marginTop: 24 }]}>
              {t('audit_logs', 'Security Audit Logs')}
            </Text>
            <View style={styles.auditContainer}>
              {auditLogs.map(log => (
                <View key={log.id} style={styles.auditLogItem}>
                  <Text style={styles.auditLogTime}>{new Date(log.timestamp).toLocaleTimeString()}</Text>
                  <Text style={[styles.auditLogText, textAlignStyle]}>{log.action}</Text>
                </View>
              ))        }
            </View>
          </View>
        )}

        {/* ========================================================= */}
        {/* TAB 6: NOTIFICATION HUB */}
        {/* ========================================================= */}
        {activeTab === 'notifications' && (
          <View>
            <Text style={[styles.sectionTitle, textAlignStyle]}>{t('broadcast_title', 'Broadcast Message')}</Text>
            
            <View style={styles.formCard}>
              {/* Title Inputs */}
              <Text style={[styles.label, textAlignStyle]}>{t('notif_title_en', 'Title (English) *')}</Text>
              <TextInput
                style={[styles.input, textAlignStyle]}
                placeholder={t('notif_title_en', 'Title (English) *')}
                value={notifTitleEn}
                onChangeText={setNotifTitleEn}
              />

              <Text style={[styles.label, textAlignStyle]}>{t('notif_title_ar', 'Title (Arabic) *')}</Text>
              <TextInput
                style={[styles.input, textAlignStyle]}
                placeholder={t('notif_title_ar', 'Title (Arabic) *')}
                value={notifTitleAr}
                onChangeText={setNotifTitleAr}
              />

              {/* Message Body Inputs */}
              <Text style={[styles.label, textAlignStyle]}>{t('notif_body_en', 'Message Body (English) *')}</Text>
              <TextInput
                style={[styles.input, styles.textArea, textAlignStyle]}
                multiline
                placeholder={t('notif_body_en', 'Message Body (English) *')}
                value={notifMessageEn}
                onChangeText={setNotifMessageEn}
              />

              <Text style={[styles.label, textAlignStyle]}>{t('notif_body_ar', 'Message Body (Arabic) *')}</Text>
              <TextInput
                style={[styles.input, styles.textArea, textAlignStyle]}
                multiline
                placeholder={t('notif_body_ar', 'Message Body (Arabic) *')}
                value={notifMessageAr}
                onChangeText={setNotifMessageAr}
              />

              {/* Type Selection */}
              <Text style={[styles.label, textAlignStyle]}>{t('notif_type', 'Notification Type')}</Text>
              <View style={[rowStyle, { flexWrap: 'wrap', marginBottom: 12 }]}>
                {(['SYSTEM', 'EARN', 'WITHDRAW', 'SPEND', 'REFERRAL'] as const).map(type => (
                  <TouchableOpacity
                    key={type}
                    style={[
                      styles.pickerPill,
                      notifType === type && styles.pickerPillActive,
                      marginStartStyle(4),
                      { marginBottom: 8 }
                    ]}
                    onPress={() => setNotifType(type)}
                  >
                    <Text style={[styles.pickerPillText, notifType === type && styles.pickerPillTextActive]}>
                      {type}
                    </Text>
                  </TouchableOpacity>
                ))}
              </View>

              {/* Target Audience */}
              <Text style={[styles.label, textAlignStyle]}>{t('notif_target', 'Target Audience')}</Text>
              <View style={[rowStyle, { flexWrap: 'wrap', marginBottom: 12 }]}>
                {([
                  { key: 'all', labelKey: 'target_all' },
                  { key: 'vip', labelKey: 'target_vip' },
                  { key: 'active', labelKey: 'target_active' },
                  { key: 'inactive', labelKey: 'target_inactive' },
                  { key: 'specific', labelKey: 'target_specific' }
                ] as const).map(item => (
                  <TouchableOpacity
                    key={item.key}
                    style={[
                      styles.pickerPill,
                      notifTarget === item.key && styles.pickerPillActive,
                      marginStartStyle(4),
                      { marginBottom: 8 }
                    ]}
                    onPress={() => setNotifTarget(item.key)}
                  >
                    <Text style={[styles.pickerPillText, notifTarget === item.key && styles.pickerPillTextActive]}>
                      {t(item.labelKey, item.key.toUpperCase())}
                    </Text>
                  </TouchableOpacity>
                ))}
              </View>

              {/* Specific User ID */}
              {notifTarget === 'specific' && (
                <View style={{ marginBottom: 12 }}>
                  <Text style={[styles.label, textAlignStyle]}>{t('specific_user_id_lbl', 'Enter Target User ID *')}</Text>
                  <TextInput
                    style={[styles.input, textAlignStyle]}
                    placeholder="e.g. u1, u2"
                    value={specificUserId}
                    onChangeText={setSpecificUserId}
                  />
                </View>
              )}

              {/* Scheduler Input */}
              <Text style={[styles.label, textAlignStyle]}>{t('schedule_in_minutes', 'Schedule delay (minutes, 0 for immediate)')}</Text>
              <TextInput
                style={[styles.input, textAlignStyle]}
                keyboardType="numeric"
                placeholder="0"
                value={notifDelayMin}
                onChangeText={setNotifDelayMin}
              />

              <TouchableOpacity style={styles.submitBtn} onPress={handleBroadcast}>
                <Text style={styles.submitBtnText}>{t('broadcast_btn', 'Send Broadcast')}</Text>
              </TouchableOpacity>
            </View>

            {/* Scheduled Notifications Manager */}
            <Text style={[styles.sectionTitle, textAlignStyle, { marginTop: 24 }]}>{t('scheduled_notifs', 'Scheduled Notifications')}</Text>
            {scheduledNotifs.length === 0 ? (
              <View style={styles.emptyLogs}>
                <Text style={styles.emptyLogsText}>{t('no_scheduled_notifs', 'No scheduled notifications.')}</Text>
              </View>
            ) : (
              scheduledNotifs.map(item => (
                <View key={item.id} style={styles.purchaseLogCard}>
                  <View style={[styles.logRow, rowStyle, { justifyContent: 'space-between', alignItems: 'center' }]}>
                    <Text style={[styles.logTitle, { flex: 1 }, textAlignStyle]}>{isRTL ? item.title_ar : item.title_en}</Text>
                    <TouchableOpacity 
                      style={styles.cancelBtn} 
                      onPress={() => cancelScheduledNotification(item.id)}
                    >
                      <Text style={styles.cancelBtnText}>{t('cancel_scheduled', 'Cancel')}</Text>
                    </TouchableOpacity>
                  </View>
                  <View style={[styles.logRow, rowStyle, { marginTop: 4, justifyContent: 'space-between' }]}>
                    <Text style={styles.logCode}>Target: {item.user_id}</Text>
                    <Text style={styles.logDate}>
                      {new Date(item.scheduled_at || '').toLocaleString()}
                    </Text>
                  </View>
                </View>
              ))
            )}
          </View>
        )}

        <View style={{ height: 120 }} />
      </ScrollView>

      {/* Picker Modal */}
      <Modal visible={pickerVisible} transparent animationType="fade">
        <View style={styles.modalOverlay}>
          <View style={styles.pickerCard}>
            <View style={styles.pickerHeader}>
              <Text style={styles.pickerTitle}>{t('select_category', 'Select Category')}</Text>
              <TouchableOpacity onPress={() => setPickerVisible(false)}>
                <Feather name="x" size={20} color="#64748B" />
              </TouchableOpacity>
            </View>
            <ScrollView style={styles.pickerList}>
              {categories.map(cat => (
                <TouchableOpacity
                  key={cat.id}
                  style={[styles.pickerItem, rowStyle]}
                  onPress={() => {
                    setProdCatId(cat.id);
                    setPickerVisible(false);
                  }}
                >
                  <Ionicons name={cat.icon as any} size={18} color={cat.color || '#00A896'} style={marginEndStyle(8)} />
                  <Text style={styles.pickerItemText}>
                    {isRTL ? cat.name_ar : cat.name_en}
                  </Text>
                </TouchableOpacity>
              ))}
            </ScrollView>
          </View>
        </View>
      </Modal>

      {/* Reset Confirmation 4-Step Pipeline Modal */}
      <Modal visible={resetConfirmVisible} transparent animationType="fade">
        <View style={styles.modalOverlay}>
          <View style={styles.resetModalCard}>
            <View style={styles.pickerHeader}>
              <Text style={styles.resetModalTitle}>
                {resetStep === 1 && t('reset_step1_title', 'Step 1: Confirm Reset')}
                {resetStep === 2 && t('reset_step2_title', 'Step 2: WARNING')}
                {resetStep === 3 && t('reset_step3_title', 'Step 3: Security PIN')}
              </Text>
              <TouchableOpacity onPress={() => setResetConfirmVisible(false)}>
                <Feather name="x" size={20} color="#64748B" />
              </TouchableOpacity>
            </View>

            <View style={styles.resetModalBody}>
              {resetStep === 1 && (
                <Text style={styles.resetModalText}>
                  {t('reset_step1_desc', 'Are you sure you want to reset the referral system? This will clear all invited counters and log tables.')}
                </Text>
              )}
              {resetStep === 2 && (
                <Text style={[styles.resetModalText, { color: '#FF5A5F', fontWeight: 'bold' }]}>
                  {t('reset_step2_desc', 'CRITICAL WARNING: This action is destructive and absolutely irreversible. All user counters will return to 0. Do you want to proceed?')}
                </Text>
              )}
              {resetStep === 3 && (
                <View>
                  <Text style={styles.resetModalText}>
                    {t('reset_step3_desc', 'Please enter your Admin PIN to authorize system reset.')}
                  </Text>
                  <TextInput
                    style={styles.pinInput}
                    placeholder="PIN Code"
                    value={resetPinInput}
                    onChangeText={setResetPinInput}
                    secureTextEntry
                    keyboardType="numeric"
                    maxLength={4}
                  />
                  {resetPinError ? <Text style={styles.pinErrorText}>{resetPinError}</Text> : null}
                </View>
              )}
            </View>

            <View style={[styles.modalActionRow, { marginTop: 24 }]}>
              <TouchableOpacity
                style={[styles.modalBtn, styles.modalBtnCancel]}
                onPress={() => setResetConfirmVisible(false)}
              >
                <Text style={styles.modalBtnCancelText}>{t('cancel', 'Cancel')}</Text>
              </TouchableOpacity>

              <TouchableOpacity
                style={[styles.modalBtn, { backgroundColor: '#FF5A5F' }]}
                onPress={handleResetSubmit}
              >
                <Text style={styles.modalBtnConfirmText}>
                  {resetStep === 3 ? t('execute', 'RESET NOW') : t('proceed', 'Proceed')}
                </Text>
              </TouchableOpacity>
            </View>
          </View>
        </View>
      </Modal>

    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F8FAFC',
  },
  header: {
    paddingTop: 50,
    paddingBottom: 16,
    paddingHorizontal: 20,
    backgroundColor: '#FFFFFF',
    borderBottomWidth: 1,
    borderColor: '#E2E8F0',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  headerTitleRow: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  headerTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#1E293B',
  },
  logoutBtn: {
    padding: 6,
  },
  tabsRow: {
    backgroundColor: '#FFFFFF',
    paddingVertical: 8,
    paddingHorizontal: 12,
    borderBottomWidth: 1,
    borderColor: '#E2E8F0',
    justifyContent: 'space-between',
  },
  tabButton: {
    flex: 1,
    paddingVertical: 10,
    alignItems: 'center',
    borderRadius: 12,
  },
  tabButtonActive: {
    backgroundColor: '#E6F7F5',
  },
  tabText: {
    fontSize: 13,
    fontWeight: 'bold',
    color: '#64748B',
  },
  tabTextActive: {
    color: '#00A896',
  },
  scrollContent: {
    padding: 20,
  },
  sectionTitle: {
    fontSize: 16,
    fontWeight: 'bold',
    color: '#1E293B',
    marginBottom: 12,
  },
  formCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 24,
    padding: 20,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.02,
    shadowRadius: 8,
    elevation: 2,
  },
  input: {
    height: 48,
    backgroundColor: '#F8FAFC',
    borderWidth: 1,
    borderColor: '#E2E8F0',
    borderRadius: 14,
    paddingHorizontal: 16,
    marginBottom: 12,
    fontSize: 14,
    color: '#1E293B',
  },
  textArea: {
    height: 80,
    textAlignVertical: 'top',
    paddingTop: 12,
  },
  inputRow: {
    justifyContent: 'space-between',
  },
  pickerButton: {
    height: 48,
    backgroundColor: '#F8FAFC',
    borderWidth: 1,
    borderColor: '#E2E8F0',
    borderRadius: 14,
    paddingHorizontal: 16,
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 12,
  },
  pickerButtonText: {
    fontSize: 14,
    color: '#64748B',
  },
  switchRow: {
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 12,
  },
  switchLabel: {
    fontSize: 14,
    fontWeight: '600',
    color: '#64748B',
  },
  submitBtn: {
    backgroundColor: '#00A896',
    paddingVertical: 14,
    borderRadius: 16,
    alignItems: 'center',
    justifyContent: 'center',
    marginTop: 8,
  },
  submitBtnText: {
    fontSize: 14,
    color: '#FFFFFF',
    fontWeight: 'bold',
  },
  listCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 20,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    padding: 12,
    alignItems: 'center',
    marginBottom: 10,
  },
  listCardImage: {
    width: 60,
    height: 60,
    borderRadius: 12,
    resizeMode: 'cover',
  },
  catIconCircle: {
    width: 50,
    height: 50,
    borderRadius: 25,
    backgroundColor: '#F8FAFC',
    justifyContent: 'center',
    alignItems: 'center',
  },
  listCardDetails: {
    flex: 1,
  },
  listCardTitle: {
    fontSize: 14,
    fontWeight: 'bold',
    color: '#1E293B',
    marginBottom: 4,
  },
  listCardSub: {
    fontSize: 11,
    color: '#64748B',
    marginBottom: 2,
  },
  listCardCat: {
    fontSize: 10,
    fontWeight: '600',
    color: '#00A896',
  },
  listCardActions: {
    flexDirection: 'row',
  },
  actionBtnEdit: {
    padding: 8,
    backgroundColor: '#E6F7F5',
    borderRadius: 10,
    marginRight: 6,
  },
  actionBtnDelete: {
    padding: 8,
    backgroundColor: '#FFEBEB',
    borderRadius: 10,
  },
  emptyLogs: {
    paddingVertical: 30,
    alignItems: 'center',
  },
  emptyLogsText: {
    fontSize: 14,
    color: '#64748B',
  },
  purchaseLogCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 16,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    padding: 16,
    marginBottom: 10,
  },
  logRow: {
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  logTitle: {
    fontSize: 14,
    fontWeight: 'bold',
    color: '#1E293B',
  },
  logPrice: {
    fontSize: 14,
    fontWeight: '800',
    color: '#00A896',
  },
  logCode: {
    fontSize: 12,
    fontWeight: '700',
    color: '#64748B',
    backgroundColor: '#F1F5F9',
    paddingVertical: 4,
    paddingHorizontal: 8,
    borderRadius: 6,
  },
  logDate: {
    fontSize: 11,
    color: '#94A3B8',
  },
  auditContainer: {
    backgroundColor: '#FFFFFF',
    borderRadius: 20,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    padding: 16,
  },
  auditLogItem: {
    paddingVertical: 10,
    borderBottomWidth: 1,
    borderColor: '#F1F5F9',
  },
  auditLogTime: {
    fontSize: 10,
    color: '#94A3B8',
    marginBottom: 2,
  },
  auditLogText: {
    fontSize: 12,
    color: '#1E293B',
    lineHeight: 16,
  },
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(15, 23, 42, 0.5)',
    justifyContent: 'center',
    alignItems: 'center',
    padding: 24,
  },
  pickerCard: {
    width: '100%',
    maxHeight: 350,
    backgroundColor: '#FFFFFF',
    borderRadius: 24,
    padding: 20,
  },
  pickerHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 16,
  },
  pickerTitle: {
    fontSize: 16,
    fontWeight: 'bold',
    color: '#1E293B',
  },
  pickerList: {
    width: '100%',
  },
  pickerItem: {
    paddingVertical: 14,
    borderBottomWidth: 1,
    borderColor: '#F1F5F9',
    alignItems: 'center',
  },
  pickerItemText: {
    fontSize: 14,
    fontWeight: '600',
    color: '#1E293B',
  },
  analyticsContainer: {
    justifyContent: 'space-between',
    marginBottom: 24,
  },
  analyticsBox: {
    width: '31%',
    backgroundColor: '#FFFFFF',
    borderRadius: 16,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    paddingVertical: 16,
    paddingHorizontal: 8,
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.02,
    shadowRadius: 4,
  },
  analyticsVal: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#00A896',
    marginBottom: 4,
  },
  analyticsLabel: {
    fontSize: 9,
    color: '#64748B',
    fontWeight: '600',
    textAlign: 'center',
  },
  walletStatsGrid: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 20,
  },
  walletStatCard: {
    flex: 1,
    backgroundColor: '#FFFFFF',
    borderRadius: 18,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    padding: 16,
    marginHorizontal: 4,
    alignItems: 'center',
  },
  walletStatLabel: {
    fontSize: 11,
    fontWeight: '600',
    color: '#64748B',
    marginBottom: 8,
    textAlign: 'center',
  },
  walletStatValue: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#0F766E',
  },
  sectionCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 20,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    padding: 16,
    marginBottom: 16,
  },
  withdrawalRow: {
    backgroundColor: '#F8FAFC',
    borderRadius: 16,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    padding: 14,
    marginBottom: 12,
  },
  withdrawalActions: {
    justifyContent: 'flex-end',
  },
  freezeRow: {
    backgroundColor: '#F8FAFC',
    borderRadius: 16,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    padding: 14,
    marginBottom: 12,
    alignItems: 'center',
  },
  transactionRow: {
    backgroundColor: '#F8FAFC',
    borderRadius: 16,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    padding: 14,
    marginBottom: 12,
    alignItems: 'center',
  },
  txTitle: {
    fontSize: 13,
    fontWeight: '700',
    color: '#1E293B',
    marginBottom: 4,
  },
  txRef: {
    fontSize: 12,
    color: '#475569',
    marginBottom: 2,
  },
  txDate: {
    fontSize: 11,
    color: '#94A3B8',
  },
  resetCard: {
    backgroundColor: '#FFF5F5',
    borderWidth: 1.5,
    borderColor: '#FEE2E2',
    borderRadius: 24,
    padding: 20,
    alignItems: 'center',
  },
  resetTitle: {
    fontSize: 11,
    fontWeight: 'bold',
    color: '#EF4444',
    letterSpacing: 1,
    marginBottom: 8,
  },
  resetDesc: {
    fontSize: 12,
    color: '#7F1D1D',
    textAlign: 'center',
    lineHeight: 16,
    marginBottom: 16,
  },
  resetBtn: {
    backgroundColor: '#EF4444',
    paddingVertical: 12,
    paddingHorizontal: 24,
    borderRadius: 14,
  },
  resetBtnText: {
    fontSize: 13,
    color: '#FFFFFF',
    fontWeight: 'bold',
  },
  resetModalCard: {
    width: '100%',
    backgroundColor: '#FFFFFF',
    borderRadius: 28,
    padding: 24,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 10 },
    shadowOpacity: 0.1,
    shadowRadius: 20,
    elevation: 8,
  },
  resetModalTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#1E293B',
  },
  resetModalBody: {
    marginVertical: 16,
  },
  resetModalText: {
    fontSize: 14,
    color: '#64748B',
    lineHeight: 20,
  },
  pinInput: {
    height: 48,
    backgroundColor: '#F8FAFC',
    borderWidth: 1.5,
    borderColor: '#CBD5E1',
    borderRadius: 14,
    paddingHorizontal: 16,
    fontSize: 18,
    fontWeight: 'bold',
    textAlign: 'center',
    marginTop: 16,
    letterSpacing: 2,
  },
  pinErrorText: {
    fontSize: 12,
    color: '#EF4444',
    fontWeight: '600',
    marginTop: 8,
    textAlign: 'center',
  },
  modalActionRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
  },
  modalBtn: {
    flex: 1,
    paddingVertical: 12,
    borderRadius: 14,
    alignItems: 'center',
  },
  modalBtnCancel: {
    backgroundColor: '#F1F5F9',
    marginRight: 8,
  },
  modalBtnCancelText: {
    fontSize: 14,
    color: '#64748B',
    fontWeight: '600',
  },
  modalBtnConfirmText: {
    fontSize: 14,
    color: '#FFFFFF',
    fontWeight: '700',
  },
  label: {
    fontSize: 13,
    fontWeight: 'bold',
    color: '#64748B',
    marginBottom: 6,
    marginTop: 6,
  },
  pickerPill: {
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 12,
    backgroundColor: '#F1F5F9',
    marginRight: 6,
    marginTop: 4,
  },
  pickerPillActive: {
    backgroundColor: '#E6F7F5',
    borderColor: '#00A896',
    borderWidth: 1,
  },
  pickerPillText: {
    fontSize: 12,
    fontWeight: '600',
    color: '#64748B',
  },
  pickerPillTextActive: {
    color: '#00A896',
  },
  cancelBtn: {
    backgroundColor: '#FFEBEB',
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderRadius: 8,
  },
  cancelBtnText: {
    fontSize: 11,
    color: '#EF4444',
    fontWeight: '600',
  },
});
