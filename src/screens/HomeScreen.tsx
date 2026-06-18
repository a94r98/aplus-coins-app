import React, { useState, useEffect } from 'react';
import {
  StyleSheet,
  Text,
  View,
  Image,
  TouchableOpacity,
  ScrollView,
  SafeAreaView,
  Dimensions,
  ViewStyle,
  TextStyle,
  Vibration,
  Alert,
  StatusBar
} from 'react-native';
import { useTranslation } from 'react-i18next';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons, Feather, MaterialCommunityIcons } from '@expo/vector-icons';
import * as Haptics from 'expo-haptics';

import { useApp } from '../services/store';
import StoreScreen from './StoreScreen';
import WalletScreen from './WalletScreen';
import AdminScreen from './AdminScreen';
import ReferralScreen from './ReferralScreen';
import NotificationScreen from './NotificationScreen';
import PinCodeModal from '../components/PinCodeModal';
import VIPScreen from './VIPScreen';

const { width } = Dimensions.get('window');

export default function HomeScreen() {
  const { t, i18n } = useTranslation();
  const isRTL = i18n.language === 'ar';
  
  const { userCoins, userProfile, isAdmin, unreadNotificationsCount } = useApp();

  // Navigation states
  const [currentTab, setCurrentTab] = useState<'home' | 'store' | 'referrals' | 'wallet' | 'profile' | 'notifications' | 'vip'>('home');
  const [isAdminActive, setIsAdminActive] = useState<boolean>(false);
  const [pinModalVisible, setPinModalVisible] = useState<boolean>(false);

  // Sync admin state
  useEffect(() => {
    if (!isAdmin) {
      setIsAdminActive(false);
    }
  }, [isAdmin]);

  const toggleLanguage = () => {
    const nextLang = i18n.language === 'ar' ? 'en' : 'ar';
    i18n.changeLanguage(nextLang);
  };

  const handleAvatarLongPress = () => {
    // Heavy haptic press feedback to notify admin trigger
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Heavy).catch(() => {});
    Vibration.vibrate(100);
    setPinModalVisible(true);
  };

  // Helper styles for dynamic RTL/LTR support
  const rowStyle: ViewStyle = { flexDirection: isRTL ? 'row-reverse' : 'row' };
  const textAlignStyle: TextStyle = { textAlign: isRTL ? 'right' : 'left' };
  
  const marginStartStyle = (val: number) => isRTL ? { marginRight: val } : { marginLeft: val };
  const marginEndStyle = (val: number) => isRTL ? { marginLeft: val } : { marginRight: val };

  // Render Placeholder for simple tabs
  const renderPlaceholder = (title: string) => {
    return (
      <View style={styles.placeholderContainer}>
        <Feather name="info" size={48} color="#94A3B8" />
        <Text style={styles.placeholderText}>{title}</Text>
        <Text style={styles.placeholderSub}>
          {t('section_placeholder_desc', 'This section will be developed in future releases.')}
        </Text>
      </View>
    );
  };

  const renderProfileContent = () => {
    if (!userProfile) {
      return renderPlaceholder(t('nav_profile', 'Profile'));
    }

    // Translate status to Arabic if language is 'ar'
    const statusText = isRTL 
      ? (userProfile.status === 'active' ? 'نشط' : userProfile.status === 'suspended' ? 'معلق' : 'محظور')
      : userProfile.status.toUpperCase();

    return (
      <ScrollView contentContainerStyle={styles.scrollContent} showsVerticalScrollIndicator={false}>
        {/* Profile Header Header Info Card */}
        <View style={styles.profileHeaderCard}>
          <View style={[styles.profileRow, rowStyle, { marginBottom: 0 }]}>
            <View style={[styles.profileInfo, rowStyle]}>
              <View style={[styles.avatarContainer, { width: 72, height: 72, borderRadius: 36 }]}>
                <Image
                  source={require('../../assets/avatar_3d.png')}
                  style={styles.avatar}
                />
              </View>
              <View style={[styles.profileTexts, marginStartStyle(16)]}>
                <Text style={[styles.welcomeText, textAlignStyle, { fontSize: 20 }]}>{userProfile.name}</Text>
                <Text style={[styles.subText, textAlignStyle, { fontSize: 13, color: 'rgba(255, 255, 255, 0.85)', marginTop: 2 }]}>
                  ID: {userProfile.id}
                </Text>
                <View style={[styles.badgeContainer, rowStyle, { marginTop: 6 }]}>
                  <Text style={styles.badgeText}>{isRTL ? 'الحالة' : 'Status'}: {statusText}</Text>
                </View>
              </View>
            </View>
          </View>
        </View>

        {/* Options list like modern apps */}
        <View style={styles.profileCard}>
          {/* Subscriptions item */}
          <TouchableOpacity 
            style={[styles.menuItem, rowStyle]}
            onPress={() => setCurrentTab('vip')}
          >
            <View style={[styles.menuItemLeft, rowStyle]}>
              <View style={[styles.menuIconWrapper, { backgroundColor: '#FEF3C7' }]}>
                <Feather name="award" size={18} color="#D97706" />
              </View>
              <Text style={[styles.menuItemText, marginStartStyle(12)]}>
                {isRTL ? 'الاشتراكات' : 'Subscriptions'}
              </Text>
            </View>
            <View style={[rowStyle, { alignItems: 'center' }]}>
              <Text style={[styles.menuItemValue, { color: '#D97706', fontWeight: 'bold' }]}>
                {userProfile.subscription.plan === 'free' 
                  ? (isRTL ? 'مجاني' : 'Free') 
                  : userProfile.subscription.plan.toUpperCase()}
              </Text>
              <Feather name={isRTL ? "chevron-left" : "chevron-right"} size={16} color="#D97706" style={marginStartStyle(6)} />
            </View>
          </TouchableOpacity>

          {/* 1. Edit Profile */}
          <TouchableOpacity 
            style={[styles.menuItem, rowStyle]}
            onPress={() => Alert.alert(t('edit_profile', 'Edit Profile'), t('section_placeholder_desc'))}
          >
            <View style={[styles.menuItemLeft, rowStyle]}>
              <View style={[styles.menuIconWrapper, { backgroundColor: '#E6F7F5' }]}>
                <Feather name="edit-3" size={18} color="#00A896" />
              </View>
              <Text style={[styles.menuItemText, marginStartStyle(12)]}>{t('edit_profile', 'Edit Profile')}</Text>
            </View>
            <Feather name={isRTL ? "chevron-left" : "chevron-right"} size={18} color="#94A3B8" />
          </TouchableOpacity>

          {/* 2. Settings */}
          <TouchableOpacity 
            style={[styles.menuItem, rowStyle]}
            onPress={() => Alert.alert(t('settings', 'Settings'), t('section_placeholder_desc'))}
          >
            <View style={[styles.menuItemLeft, rowStyle]}>
              <View style={[styles.menuIconWrapper, { backgroundColor: '#F1F5F9' }]}>
                <Feather name="settings" size={18} color="#64748B" />
              </View>
              <Text style={[styles.menuItemText, marginStartStyle(12)]}>{t('settings', 'Settings')}</Text>
            </View>
            <Feather name={isRTL ? "chevron-left" : "chevron-right"} size={18} color="#94A3B8" />
          </TouchableOpacity>

          {/* 3. About App */}
          <TouchableOpacity 
            style={[styles.menuItem, rowStyle]}
            onPress={() => Alert.alert(t('about_app', 'About App'), t('section_placeholder_desc'))}
          >
            <View style={[styles.menuItemLeft, rowStyle]}>
              <View style={[styles.menuIconWrapper, { backgroundColor: '#F5F3FF' }]}>
                <Feather name="info" size={18} color="#7C3AED" />
              </View>
              <Text style={[styles.menuItemText, marginStartStyle(12)]}>{t('about_app', 'About App')}</Text>
            </View>
            <Feather name={isRTL ? "chevron-left" : "chevron-right"} size={18} color="#94A3B8" />
          </TouchableOpacity>

          {/* 4. Terms of Use */}
          <TouchableOpacity 
            style={[styles.menuItem, rowStyle]}
            onPress={() => Alert.alert(t('terms_of_use', 'Terms of Use'), t('section_placeholder_desc'))}
          >
            <View style={[styles.menuItemLeft, rowStyle]}>
              <View style={[styles.menuIconWrapper, { backgroundColor: '#FFF7ED' }]}>
                <Feather name="file-text" size={18} color="#EA580C" />
              </View>
              <Text style={[styles.menuItemText, marginStartStyle(12)]}>{t('terms_of_use', 'Terms of Use')}</Text>
            </View>
            <Feather name={isRTL ? "chevron-left" : "chevron-right"} size={18} color="#94A3B8" />
          </TouchableOpacity>

          {/* 5. Privacy Policy */}
          <TouchableOpacity 
            style={[styles.menuItem, rowStyle, { borderBottomWidth: 0 }]}
            onPress={() => Alert.alert(t('privacy_policy', 'Privacy Policy'), t('section_placeholder_desc'))}
          >
            <View style={[styles.menuItemLeft, rowStyle]}>
              <View style={[styles.menuIconWrapper, { backgroundColor: '#ECFDF5' }]}>
                <Feather name="lock" size={18} color="#059669" />
              </View>
              <Text style={[styles.menuItemText, marginStartStyle(12)]}>{t('privacy_policy', 'Privacy Policy')}</Text>
            </View>
            <Feather name={isRTL ? "chevron-left" : "chevron-right"} size={18} color="#94A3B8" />
          </TouchableOpacity>
        </View>

        <View style={{ height: 120 }} />
      </ScrollView>
    );
  };

  // Render Home Tab Content
  const renderHomeContent = () => {
    return (
      <ScrollView contentContainerStyle={styles.scrollContent} showsVerticalScrollIndicator={false}>
        
        {/* Profile Card & Streak */}
        <View style={[styles.profileRow, rowStyle]}>
          <View style={[styles.profileInfo, rowStyle]}>
            {/* Long Press triggers PinCodeModal */}
            <TouchableOpacity 
              activeOpacity={0.8} 
              onLongPress={handleAvatarLongPress}
              delayLongPress={1500}
              style={styles.avatarContainer}
            >
              <Image 
                source={require('../../assets/avatar_3d.png')} 
                style={styles.avatar}
              />
            </TouchableOpacity>
            
            <View style={[styles.profileTexts, marginStartStyle(12)]}>
              <Text style={[styles.welcomeText, textAlignStyle]}>
                {t('welcome')} 👋
              </Text>
              <Text style={[styles.subText, textAlignStyle]}>
                {t('subtext')}
              </Text>
            </View>
          </View>

          {/* Streak Card */}
          <View style={styles.streakCard}>
            <View style={[styles.streakRow, rowStyle]}>
              <Text style={styles.streakNumber}>7</Text>
              <MaterialCommunityIcons name="fire" size={22} color="#FF5A5F" style={marginStartStyle(2)} />
            </View>
            <Text style={styles.streakText}>{t('streak_days')}</Text>
          </View>
        </View>

        {/* Balance Card */}
        <LinearGradient
          colors={['#00B5D1', '#00A1C9']}
          start={{ x: 0, y: 0 }}
          end={{ x: 1, y: 1 }}
          style={styles.balanceCard}
        >
          {/* Always lay out row manually to ensure Circle Coins is on the LEFT, details in MIDDLE, button on the RIGHT */}
          <View style={{ flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', width: '100%' }}>
            
            {/* Left side: White Circle container enclosing coins */}
            <View style={styles.balanceLeftContainer}>
              <Image 
                source={require('../../assets/coins_stack_3d.png')} 
                style={styles.coinsImage}
              />
            </View>
            
            {/* Middle: Value and label */}
            <View style={[styles.balanceInfo, { alignItems: 'flex-start' }]}>
              <Text style={[styles.balanceText, { textAlign: 'left' }]}>{userCoins.toLocaleString()}</Text>
              <Text style={[styles.balanceLabel, { textAlign: 'left' }]}>{t('coins')}</Text>
            </View>

            {/* Right: Wallet navigation button */}
            <TouchableOpacity 
              style={[styles.walletButton, { flexDirection: 'row', alignItems: 'center' }]}
              onPress={() => setCurrentTab('wallet')}
            >
              <Ionicons name="chevron-back" size={14} color="#00A896" style={{ marginRight: 6 }} />
              <Text style={styles.walletButtonText}>{t('my_wallet')}</Text>
            </TouchableOpacity>
          </View>
        </LinearGradient>

        {/* Promo Banner Card */}
        <LinearGradient
          colors={['#02C39A', '#00A896']}
          start={{ x: 0, y: 0 }}
          end={{ x: 1, y: 0 }}
          style={styles.promoCard}
        >
          {/* Always lay out elements with play button on Left, Texts in Middle, Gift on the Right */}
          <TouchableOpacity 
            style={{ flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', width: '100%' }}
            onPress={() => setCurrentTab('store')}
          >
            <View style={styles.promoPlayIconWrapper}>
              <Ionicons name="play" size={20} color="#00A896" style={{ marginLeft: 2 }} />
            </View>
            
            <View style={[styles.promoTexts, { paddingHorizontal: 12, alignItems: 'flex-start' }]}>
              <Text style={[styles.promoTitle, { textAlign: 'left' }]}>{t('watch_ad')}</Text>
              <Text style={[styles.promoSubtitle, { textAlign: 'left' }]}>{t('watch_ad_sub')}</Text>
            </View>
            
            <View style={{ width: 80, height: 60, justifyContent: 'center', alignItems: 'flex-end', position: 'relative' }}>
              <Image 
                source={require('../../assets/gift_box_3d.png')} 
                style={{ width: 60, height: 60, resizeMode: 'contain' }}
              />
            </View>
          </TouchableOpacity>
        </LinearGradient>

        {/* Daily Tasks Header */}
        <View style={[styles.sectionHeader, rowStyle]}>
          <Text style={styles.sectionTitle}>{t('daily_tasks')}</Text>
          <TouchableOpacity>
            <Text style={styles.viewAllText}>{t('view_all')}</Text>
          </TouchableOpacity>
        </View>

        {/* Task 1 */}
        <View style={[styles.taskCard, rowStyle]}>
          <View style={styles.taskIconContainer}>
            <Ionicons name="calendar-outline" size={24} color="#00A896" />
          </View>
          <View style={[styles.taskDetails, marginStartStyle(12)]}>
            <Text style={[styles.taskTitle, textAlignStyle]}>{t('task_daily_checkin')}</Text>
            <Text style={[styles.taskSubtitle, textAlignStyle]}>{t('task_daily_checkin_sub')}</Text>
          </View>
          <View style={[styles.taskRight, rowStyle]}>
            <Text style={styles.taskReward}>+50</Text>
            <Image source={require('../../assets/coins_stack_3d.png')} style={styles.smallCoinIcon} />
            <View style={[styles.checkCircle, styles.checkCircleChecked, marginStartStyle(8)]}>
              <Feather name="check" size={14} color="#FFFFFF" />
            </View>
          </View>
        </View>

        {/* Task 2 */}
        <View style={[styles.taskCard, rowStyle]}>
          <View style={styles.taskIconContainer}>
            <Ionicons name="play-circle-outline" size={26} color="#00A896" />
          </View>
          <View style={[styles.taskDetails, marginStartStyle(12)]}>
            <Text style={[styles.taskTitle, textAlignStyle]}>{t('task_watch_ads')}</Text>
            <Text style={[styles.taskSubtitle, textAlignStyle]}>{t('task_watch_ads_sub')}</Text>
          </View>
          <View style={[styles.taskRight, rowStyle]}>
            <Text style={styles.taskReward}>+150</Text>
            <Image source={require('../../assets/coins_stack_3d.png')} style={styles.smallCoinIcon} />
            <View style={[styles.progressPill, marginStartStyle(8)]}>
              <Text style={styles.progressPillText}>2/3</Text>
            </View>
          </View>
        </View>

        {/* Task 3 */}
        <View style={[styles.taskCard, rowStyle]}>
          <View style={styles.taskIconContainer}>
            <Ionicons name="people-outline" size={24} color="#00A896" />
          </View>
          <View style={[styles.taskDetails, marginStartStyle(12)]}>
            <Text style={[styles.taskTitle, textAlignStyle]}>{t('task_invite_friend')}</Text>
            <Text style={[styles.taskSubtitle, textAlignStyle]}>{t('task_invite_friend_sub')}</Text>
          </View>
          <View style={[styles.taskRight, rowStyle]}>
            <Text style={styles.taskReward}>+500</Text>
            <Image source={require('../../assets/coins_stack_3d.png')} style={styles.smallCoinIcon} />
            <View style={[styles.progressPill, marginStartStyle(8)]}>
              <Text style={styles.progressPillText}>0/1</Text>
            </View>
          </View>
        </View>

        {/* Daily Progress Header */}
        <View style={[styles.sectionHeader, rowStyle, { marginTop: 24 }]}>
          <Text style={styles.sectionTitle}>{t('daily_progress')}</Text>
        </View>

        {/* Daily Progress Card */}
        <View style={[styles.progressCard, rowStyle]}>
          <View style={styles.progressLeft}>
            <Text style={[styles.progressTargetText, textAlignStyle]}>{t('daily_target')}</Text>
            <View style={[styles.progressScoreRow, rowStyle]}>
              <Text style={styles.progressScoreVal}>500 / 1000</Text>
              <Image source={require('../../assets/coins_stack_3d.png')} style={[styles.smallCoinIcon, marginStartStyle(4)]} />
            </View>
            <View style={styles.progressBarBg}>
              <View style={[styles.progressBarFill, { width: '50%' }]} />
            </View>
          </View>
          
          <View style={styles.progressRight}>
            <Image 
              source={require('../../assets/treasure_chest_3d.png')} 
              style={styles.chestImage}
            />
          </View>
        </View>

        <View style={{ height: 120 }} />
      </ScrollView>
    );
  };

  // Render Body based on navigation state
  const renderBody = () => {
    if (isAdminActive) {
      return <AdminScreen />;
    }

    switch (currentTab) {
      case 'home':
        return renderHomeContent();
      case 'store':
        return <StoreScreen />;
      case 'referrals':
        return <ReferralScreen />;
      case 'wallet':
        return <WalletScreen />;
      case 'profile':
        return renderProfileContent();
      case 'vip':
        return <VIPScreen />;
      case 'notifications':
        return <NotificationScreen onBack={() => setCurrentTab('home')} />;
      default:
        return renderHomeContent();
    }
  };

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="dark-content" backgroundColor="#f2f7fc" />
      
      {/* Show header ONLY if admin dashboard is NOT active */}
      {!isAdminActive && (
        <View style={[styles.header, rowStyle]}>
          <View style={{ width: 26 }} />
          
          {/* Middle Language Switcher */}
          <TouchableOpacity style={styles.langButton} onPress={toggleLanguage}>
            <Text style={styles.langButtonText}>
              {i18n.language === 'ar' ? 'English' : 'العربية'}
            </Text>
          </TouchableOpacity>

          <View style={[styles.headerRight, rowStyle]}>
            {/* Admin Dashboard Entry icon shown ONLY if Admin role is authenticated */}
            {isAdmin && (
              <TouchableOpacity 
                style={[styles.iconButton, { marginRight: 8 }]} 
                onPress={() => setIsAdminActive(true)}
              >
                <Feather name="shield" size={24} color="#00A896" />
              </TouchableOpacity>
            )}

            <TouchableOpacity 
              style={styles.iconButton}
              onPress={() => {
                setIsAdminActive(false);
                setCurrentTab('notifications');
              }}
            >
              <View style={styles.notificationWrapper}>
                <Feather name="bell" size={26} color="#1E293B" />
                {unreadNotificationsCount > 0 && (
                  <View style={styles.notificationBadge}>
                    <Text style={styles.notificationBadgeText}>
                      {unreadNotificationsCount > 99 ? '99+' : unreadNotificationsCount}
                    </Text>
                  </View>
                )}
              </View>
            </TouchableOpacity>
          </View>
        </View>
      )}

      {/* Main Body View */}
      {renderBody()}

      {/* Bottom Navigation */}
      <View style={styles.bottomNavContainer}>
        <View style={[styles.bottomNav, rowStyle]}>
          
          <TouchableOpacity 
            style={styles.navItem} 
            onPress={() => {
              setIsAdminActive(false);
              setCurrentTab('home');
            }}
          >
            <Ionicons 
              name={currentTab === 'home' && !isAdminActive ? "home" : "home-outline"} 
              size={24} 
              color={currentTab === 'home' && !isAdminActive ? "#00A896" : "#64748B"} 
            />
            <Text style={[styles.navText, currentTab === 'home' && !isAdminActive ? styles.navTextActive : null]}>
              {t('nav_home')}
            </Text>
          </TouchableOpacity>

          {/* Replaced REWARDS with STORE */}
          <TouchableOpacity 
            style={styles.navItem} 
            onPress={() => {
              setIsAdminActive(false);
              setCurrentTab('store');
            }}
          >
            <Ionicons 
              name={currentTab === 'store' && !isAdminActive ? "storefront" : "storefront-outline"} 
              size={24} 
              color={currentTab === 'store' && !isAdminActive ? "#00A896" : "#64748B"} 
            />
            <Text style={[styles.navText, currentTab === 'store' && !isAdminActive ? styles.navTextActive : null]}>
              {t('store', 'Store')}
            </Text>
          </TouchableOpacity>

          <TouchableOpacity 
            style={styles.navItem} 
            onPress={() => {
              setIsAdminActive(false);
              setCurrentTab('referrals');
            }}
          >
            <Ionicons 
              name={currentTab === 'referrals' && !isAdminActive ? "people" : "people-outline"} 
              size={24} 
              color={currentTab === 'referrals' && !isAdminActive ? "#00A896" : "#64748B"} 
            />
            <Text style={[styles.navText, currentTab === 'referrals' && !isAdminActive ? styles.navTextActive : null]}>
              {t('nav_referrals')}
            </Text>
          </TouchableOpacity>

          <TouchableOpacity 
            style={styles.navItem} 
            onPress={() => {
              setIsAdminActive(false);
              setCurrentTab('wallet');
            }}
          >
            <Ionicons 
              name={currentTab === 'wallet' && !isAdminActive ? "wallet" : "wallet-outline"} 
              size={24} 
              color={currentTab === 'wallet' && !isAdminActive ? "#00A896" : "#64748B"} 
            />
            <Text style={[styles.navText, currentTab === 'wallet' && !isAdminActive ? styles.navTextActive : null]}>
              {t('nav_wallet')}
            </Text>
          </TouchableOpacity>

          <TouchableOpacity 
            style={styles.navItem} 
            onPress={() => {
              setIsAdminActive(false);
              setCurrentTab('vip');
            }}
          >
            <Ionicons 
              name={currentTab === 'vip' && !isAdminActive ? "diamond" : "diamond-outline"} 
              size={24} 
              color={currentTab === 'vip' && !isAdminActive ? "#D97706" : "#64748B"} 
            />
            <Text style={[styles.navText, currentTab === 'vip' && !isAdminActive ? styles.navTextActive : null]}>
              {t('nav_vip', 'VIP')}
            </Text>
          </TouchableOpacity>

          <TouchableOpacity 
            style={styles.navItem} 
            onPress={() => {
              setIsAdminActive(false);
              setCurrentTab('profile');
            }}
          >
            <Ionicons 
              name={currentTab === 'profile' && !isAdminActive ? "person" : "person-outline"} 
              size={24} 
              color={currentTab === 'profile' && !isAdminActive ? "#00A896" : "#64748B"} 
            />
            <Text style={[styles.navText, currentTab === 'profile' && !isAdminActive ? styles.navTextActive : null]}>
              {t('nav_profile')}
            </Text>
          </TouchableOpacity>

        </View>
      </View>

      {/* Hidden authentication PIN pad */}
      <PinCodeModal
        visible={pinModalVisible}
        onClose={() => setPinModalVisible(false)}
        onSuccess={() => {
          setPinModalVisible(false);
          setIsAdminActive(true);
        }}
      />

    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f2f7fc',
  },
  header: {
    height: 60,
    paddingHorizontal: 20,
    justifyContent: 'space-between',
    alignItems: 'center',
    backgroundColor: '#f2f7fc',
  },
  headerRight: {
    alignItems: 'center',
  },
  iconButton: {
    width: 40,
    height: 40,
    borderRadius: 12,
    justifyContent: 'center',
    alignItems: 'center',
  },
  notificationWrapper: {
    position: 'relative',
  },
  notificationBadge: {
    position: 'absolute',
    top: -4,
    right: -4,
    minWidth: 16,
    height: 16,
    borderRadius: 8,
    backgroundColor: '#FF5A5F',
    justifyContent: 'center',
    alignItems: 'center',
    paddingHorizontal: 3,
  },
  notificationBadgeText: {
    color: '#FFFFFF',
    fontSize: 9,
    fontWeight: 'bold',
    textAlign: 'center',
  },
  langButton: {
    paddingVertical: 6,
    paddingHorizontal: 12,
    borderRadius: 20,
    backgroundColor: '#FFFFFF',
    borderWidth: 1,
    borderColor: '#E2E8F0',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.03,
    shadowRadius: 4,
    elevation: 1,
  },
  langButtonText: {
    fontSize: 14,
    fontWeight: '600',
    color: '#00A896',
  },
  scrollContent: {
    paddingHorizontal: 20,
    paddingTop: 10,
  },
  profileRow: {
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 20,
  },
  profileInfo: {
    alignItems: 'center',
    flex: 1,
  },
  avatarContainer: {
    width: 64,
    height: 64,
    borderRadius: 32,
    borderWidth: 3,
    borderColor: '#FFFFFF',
    shadowColor: '#00A896',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.15,
    shadowRadius: 8,
    elevation: 4,
    overflow: 'hidden',
  },
  avatar: {
    width: '100%',
    height: '100%',
    resizeMode: 'cover',
  },
  profileTexts: {
    flex: 1,
    justifyContent: 'center',
  },
  welcomeText: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#1E293B',
    marginBottom: 4,
  },
  subText: {
    fontSize: 12,
    color: '#64748B',
  },
  streakCard: {
    backgroundColor: '#FFFFFF',
    paddingVertical: 8,
    paddingHorizontal: 16,
    borderRadius: 20,
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.05,
    shadowRadius: 10,
    elevation: 2,
  },
  streakRow: {
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 2,
  },
  streakNumber: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#1E293B',
  },
  streakText: {
    fontSize: 10,
    color: '#64748B',
    fontWeight: '500',
  },
  balanceCard: {
    borderRadius: 24,
    padding: 24,
    marginBottom: 20,
    shadowColor: '#0083B0',
    shadowOffset: { width: 0, height: 10 },
    shadowOpacity: 0.2,
    shadowRadius: 20,
    elevation: 6,
  },
  balanceCardContent: {
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  balanceLeftContainer: {
    width: 110,
    height: 110,
    borderRadius: 55,
    backgroundColor: '#FFFFFF',
    justifyContent: 'center',
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.08,
    shadowRadius: 8,
    elevation: 3,
  },
  balanceInfo: {
    flex: 1,
    paddingHorizontal: 16,
  },
  balanceText: {
    fontSize: 34,
    fontWeight: '900',
    color: '#FFFFFF',
  },
  balanceLabel: {
    fontSize: 14,
    color: 'rgba(255, 255, 255, 0.85)',
    fontWeight: '600',
    marginTop: 2,
  },
  coinsImage: {
    width: 70,
    height: 70,
    resizeMode: 'contain',
  },
  walletButton: {
    backgroundColor: '#FFFFFF',
    paddingVertical: 10,
    paddingHorizontal: 18,
    borderRadius: 20,
    alignItems: 'center',
    justifyContent: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.05,
    shadowRadius: 8,
    elevation: 2,
  },
  walletButtonText: {
    fontSize: 13,
    fontWeight: '700',
    color: '#00A896',
  },
  promoCard: {
    borderRadius: 24,
    padding: 16,
    marginBottom: 24,
    shadowColor: '#00A896',
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.15,
    shadowRadius: 16,
    elevation: 4,
  },
  promoCardContent: {
    justifyContent: 'space-between',
    alignItems: 'center',
    width: '100%',
  },
  promoPlayIconWrapper: {
    width: 44,
    height: 44,
    borderRadius: 14,
    backgroundColor: '#FFFFFF',
    justifyContent: 'center',
    alignItems: 'center',
  },
  promoTexts: {
    flex: 1,
  },
  promoTitle: {
    fontSize: 16,
    fontWeight: 'bold',
    color: '#FFFFFF',
    marginBottom: 4,
  },
  promoSubtitle: {
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.85)',
  },
  promoRightArea: {
    alignItems: 'center',
    position: 'relative',
    height: 50,
    width: 70,
    justifyContent: 'center',
  },
  giftImage: {
    width: 65,
    height: 65,
    resizeMode: 'contain',
    position: 'absolute',
    right: -10,
    top: -20,
  },
  sectionHeader: {
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 16,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#1E293B',
  },
  viewAllText: {
    fontSize: 14,
    color: '#00A896',
    fontWeight: '600',
  },
  taskCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 20,
    padding: 16,
    alignItems: 'center',
    marginBottom: 12,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.03,
    shadowRadius: 10,
    elevation: 1.5,
  },
  taskIconContainer: {
    width: 48,
    height: 48,
    borderRadius: 16,
    backgroundColor: '#E6F7F5',
    justifyContent: 'center',
    alignItems: 'center',
  },
  taskDetails: {
    flex: 1,
  },
  taskTitle: {
    fontSize: 15,
    fontWeight: 'bold',
    color: '#1E293B',
    marginBottom: 4,
  },
  taskSubtitle: {
    fontSize: 11,
    color: '#64748B',
  },
  taskRight: {
    alignItems: 'center',
    justifyContent: 'flex-end',
  },
  taskReward: {
    fontSize: 15,
    fontWeight: 'bold',
    color: '#00A896',
  },
  smallCoinIcon: {
    width: 18,
    height: 18,
    resizeMode: 'contain',
    marginLeft: 4,
  },
  checkCircle: {
    width: 24,
    height: 24,
    borderRadius: 12,
    justifyContent: 'center',
    alignItems: 'center',
    borderWidth: 2,
    borderColor: '#E2E8F0',
  },
  checkCircleChecked: {
    backgroundColor: '#00A896',
    borderColor: '#00A896',
  },
  progressPill: {
    backgroundColor: '#E6F7F5',
    paddingVertical: 4,
    paddingHorizontal: 8,
    borderRadius: 12,
    justifyContent: 'center',
    alignItems: 'center',
  },
  progressPillText: {
    fontSize: 12,
    fontWeight: 'bold',
    color: '#00A896',
  },
  progressCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 24,
    padding: 20,
    alignItems: 'center',
    justifyContent: 'space-between',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.03,
    shadowRadius: 10,
    elevation: 2,
  },
  progressLeft: {
    flex: 1,
  },
  progressTargetText: {
    fontSize: 14,
    fontWeight: '600',
    color: '#64748B',
    marginBottom: 6,
  },
  progressScoreRow: {
    alignItems: 'center',
    marginBottom: 12,
  },
  progressScoreVal: {
    fontSize: 20,
    fontWeight: 'bold',
    color: '#1E293B',
  },
  progressBarBg: {
    height: 10,
    backgroundColor: '#F1F5F9',
    borderRadius: 5,
    overflow: 'hidden',
  },
  progressBarFill: {
    height: '100%',
    backgroundColor: '#00A896',
    borderRadius: 5,
  },
  progressRight: {
    marginLeft: 16,
  },
  chestImage: {
    width: 80,
    height: 80,
    resizeMode: 'contain',
  },
  profileCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 20,
    padding: 18,
    marginBottom: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.05,
    shadowRadius: 12,
    elevation: 2,
  },
  profileDetailRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginTop: 14,
  },
  profileDetailLabel: {
    fontSize: 13,
    color: '#64748B',
    flex: 1,
  },
  profileDetailValue: {
    fontSize: 14,
    color: '#1E293B',
    fontWeight: '700',
    flex: 1,
    textAlign: 'right',
  },
  profileHeaderCard: {
    backgroundColor: '#00A896',
    borderRadius: 24,
    padding: 20,
    marginBottom: 16,
    shadowColor: '#00A896',
    shadowOffset: { width: 0, height: 6 },
    shadowOpacity: 0.15,
    shadowRadius: 12,
    elevation: 3,
  },
  badgeContainer: {
    backgroundColor: 'rgba(255, 255, 255, 0.2)',
    paddingVertical: 4,
    paddingHorizontal: 10,
    borderRadius: 12,
    alignSelf: 'flex-start',
  },
  badgeText: {
    fontSize: 11,
    fontWeight: 'bold',
    color: '#FFFFFF',
  },
  menuItem: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingVertical: 14,
    borderBottomWidth: 1,
    borderBottomColor: '#F1F5F9',
  },
  menuItemLeft: {
    alignItems: 'center',
  },
  menuIconWrapper: {
    width: 36,
    height: 36,
    borderRadius: 10,
    justifyContent: 'center',
    alignItems: 'center',
  },
  menuItemText: {
    fontSize: 14,
    fontWeight: '600',
    color: '#334155',
  },
  menuItemValue: {
    fontSize: 13,
    color: '#64748B',
    fontWeight: '500',
  },
  bottomNavContainer: {
    position: 'absolute',
    bottom: 20,
    left: 20,
    right: 20,
    backgroundColor: 'transparent',
  },
  bottomNav: {
    backgroundColor: '#FFFFFF',
    borderRadius: 24,
    paddingVertical: 12,
    paddingHorizontal: 16,
    justifyContent: 'space-around',
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.08,
    shadowRadius: 20,
    elevation: 8,
  },
  navItem: {
    alignItems: 'center',
    justifyContent: 'center',
  },
  navText: {
    fontSize: 10,
    fontWeight: '600',
    color: '#64748B',
    marginTop: 4,
  },
  navTextActive: {
    color: '#00A896',
  },
  placeholderContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 32,
    backgroundColor: '#F8FAFC',
  },
  placeholderText: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#1E293B',
    marginTop: 16,
    marginBottom: 8,
  },
  placeholderSub: {
    fontSize: 13,
    color: '#64748B',
    textAlign: 'center',
    lineHeight: 18,
  }
});
