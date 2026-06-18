import React, { useState, useEffect } from 'react';
import {
  StyleSheet,
  Text,
  View,
  ScrollView,
  TouchableOpacity,
  SafeAreaView,
  Alert,
  Dimensions,
  ActivityIndicator,
  ViewStyle,
  TextStyle
} from 'react-native';
import { useTranslation } from 'react-i18next';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons, Feather, FontAwesome5 } from '@expo/vector-icons';
import { useApp } from '../services/store';
import { SubscriptionPlan } from '../services/api';

const { width } = Dimensions.get('window');

export default function VIPScreen() {
  const { t, i18n } = useTranslation();
  const isRTL = i18n.language === 'ar';
  
  const {
    userProfile,
    userCoins,
    allUsers,
    dailyEconomyRecords,
    purchaseVIPSubscription,
    refreshData
  } = useApp();

  const [selectedPlan, setSelectedPlan] = useState<SubscriptionPlan>('monthly');
  const [purchasing, setPurchasing] = useState(false);
  const [cooldownSec, setCooldownSec] = useState(0);

  // Calculate System Solvency Reserve-to-Liability Index (RPI)
  const totalReserves = dailyEconomyRecords.reduce((sum, r) => sum + r.total_pool_coins, 0);
  const totalLiabilities = allUsers.reduce((sum, u) => sum + (u.coins || 0), 0);
  const rpi = totalLiabilities > 0 ? (totalReserves / totalLiabilities) : 1.0;

  // RPI Solvency Thresholds
  let solvencyColor = 'hsl(142, 70%, 45%)'; // Green
  let solvencyBg = 'hsla(142, 70%, 45%, 0.15)';
  let solvencyStatus = t('solvency_safe', 'Safe');
  
  if (rpi < 0.2) {
    solvencyColor = 'hsl(350, 80%, 55%)'; // Red
    solvencyBg = 'hsla(350, 80%, 55%, 0.15)';
    solvencyStatus = t('solvency_critical', 'Critical');
  } else if (rpi < 0.5) {
    solvencyColor = 'hsl(45, 90%, 55%)'; // Yellow
    solvencyBg = 'hsla(45, 90%, 55%, 0.15)';
    solvencyStatus = t('solvency_warning', 'Warning');
  }

  // Handle ad watch task cooldown timer
  useEffect(() => {
    let interval: any;
    const checkCooldown = () => {
      if (userProfile?.subscription?.last_ad_watch_time) {
        const lastWatch = new Date(userProfile.subscription.last_ad_watch_time).getTime();
        const diff = Date.now() - lastWatch;
        if (diff < 60000) {
          setCooldownSec(Math.ceil((60000 - diff) / 1000));
        } else {
          setCooldownSec(0);
        }
      } else {
        setCooldownSec(0);
      }
    };

    checkCooldown();
    interval = setInterval(checkCooldown, 1000);

    return () => clearInterval(interval);
  }, [userProfile]);

  useEffect(() => {
    refreshData();
  }, []);

  const handlePurchase = async () => {
    if (selectedPlan === 'free') return;
    
    let price = 2500;
    if (selectedPlan === '90days') price = 6000;
    else if (selectedPlan === 'yearly') price = 20000;
    else if (selectedPlan === 'lifetime') price = 50000;

    if (userCoins < price) {
      Alert.alert(t('error', 'Error'), t('insufficient_balance', 'Insufficient coins balance.'));
      return;
    }

    Alert.alert(
      t('confirm_title', 'Confirm Purchase'),
      `${t('confirm_prompt', 'Are you sure you want to purchase:')} VIP ${selectedPlan.toUpperCase()} (${price} Coins)?`,
      [
        { text: t('cancel', 'Cancel'), style: 'cancel' },
        {
          text: t('confirm', 'Confirm'),
          onPress: async () => {
            setPurchasing(true);
            try {
              const res = await purchaseVIPSubscription(selectedPlan);
              if (res.success) {
                Alert.alert(t('success', 'Success'), t('vip_purchase_success', 'VIP Upgrade Active!'));
              } else {
                Alert.alert(t('error', 'Error'), t(res.error || 'purchase_failed'));
              }
            } catch (err) {
              Alert.alert(t('error', 'Error'), t('purchase_failed'));
            } finally {
              setPurchasing(false);
            }
          }
        }
      ]
    );
  };

  const rowStyle: ViewStyle = { flexDirection: isRTL ? 'row-reverse' : 'row' };
  const textAlignStyle: TextStyle = { textAlign: isRTL ? 'right' : 'left' };
  const marginStartStyle = (val: number) => isRTL ? { marginRight: val } : { marginLeft: val };

  const plans = [
    { id: 'monthly', name: t('vip_monthly', 'Monthly VIP'), price: 2500, weight: 3, cap: 500, icon: 'gem' },
    { id: '90days', name: t('vip_90days', '90-Days VIP'), price: 6000, weight: 4, cap: 750, icon: 'crown' },
    { id: 'yearly', name: t('vip_yearly', 'Yearly VIP'), price: 20000, weight: 5, cap: 1000, icon: 'award' },
    { id: 'lifetime', name: t('vip_lifetime', 'Lifetime VIP'), price: 50000, weight: 10, cap: 5000, icon: 'meteor' }
  ];

  return (
    <SafeAreaView style={styles.container}>
      <LinearGradient
        colors={['hsl(275, 60%, 10%)', 'hsl(285, 45%, 5%)']}
        style={StyleSheet.absoluteFill}
      />
      
      <ScrollView contentContainerStyle={styles.scrollContent} showsVerticalScrollIndicator={false}>
        {/* Header Title */}
        <View style={styles.header}>
          <Text style={[styles.title, { color: 'hsl(45, 95%, 60%)' }]}>
            {t('vip_club', 'VIP Premium Club')}
          </Text>
          <Text style={styles.subtitle}>
            {t('vip_desc', 'Unlock weight multipliers, higher ad earning caps, and system revenue shares.')}
          </Text>
        </View>

        {/* Current status */}
        <View style={styles.glassCard}>
          <Text style={[styles.cardTitle, textAlignStyle]}>{t('current_status', 'Your Subscription Status')}</Text>
          <View style={[styles.statusRow, rowStyle]}>
            <Text style={styles.statusLabel}>{t('current_plan', 'Active Plan')}:</Text>
            <Text style={[styles.statusValue, { color: 'hsl(45, 95%, 65%)', fontWeight: 'bold' }]}>
              {userProfile?.subscription?.plan.toUpperCase() || 'FREE'}
            </Text>
          </View>
          <View style={[styles.statusRow, rowStyle]}>
            <Text style={styles.statusLabel}>{t('share_weight_label', 'Your Share Weight')}:</Text>
            <Text style={styles.statusValue}>{userProfile?.subscription?.share_weight || 1}x</Text>
          </View>
          <View style={[styles.statusRow, rowStyle]}>
            <Text style={styles.statusLabel}>{t('earning_cap_label', 'Daily Cap')}:</Text>
            <Text style={styles.statusValue}>
              {userProfile?.subscription?.today_coins_earned || 0} / {userProfile?.subscription?.daily_earning_cap || 100} Coins
            </Text>
          </View>
        </View>

        {/* Solvency Indicator */}
        <View style={[styles.glassCard, { borderColor: solvencyColor }]}>
          <Text style={[styles.cardTitle, textAlignStyle]}>{t('solvency_dashboard', 'System Solvency Dashboard')}</Text>
          <View style={[styles.statusRow, rowStyle]}>
            <Text style={styles.statusLabel}>{t('rpi_index', 'Reserve-to-Liability (RPI)')}:</Text>
            <Text style={[styles.statusValue, { color: solvencyColor, fontWeight: 'bold' }]}>
              {(rpi * 100).toFixed(1)}%
            </Text>
          </View>
          
          <View style={[styles.solvencyBadge, { backgroundColor: solvencyBg }]}>
            <Text style={[styles.solvencyStatusText, { color: solvencyColor }]}>
              {t('solvency_status', 'System Status')}: {solvencyStatus}
            </Text>
          </View>
          
          <Text style={[styles.solvencyDesc, textAlignStyle]}>
            {t('solvency_indicator_desc', 'RPI measures reserves backing outstanding coin liabilities. Status updates dynamically to guarantee full financial backing.')}
          </Text>
        </View>

        {/* Task Cooldown Section */}
        <View style={styles.glassCard}>
          <Text style={[styles.cardTitle, textAlignStyle]}>{t('task_cooldowns', 'Task Cooldowns & Daily Tasks')}</Text>
          
          <View style={[styles.taskItem, rowStyle]}>
            <View style={styles.taskIcon}>
              <Feather name="play-circle" size={24} color="hsl(45, 90%, 55%)" />
            </View>
            <View style={[styles.taskDetails, marginStartStyle(12)]}>
              <Text style={[styles.taskName, textAlignStyle]}>{t('daily_ad_watch', 'Daily Ad Watch Task')}</Text>
              {cooldownSec > 0 ? (
                <Text style={[styles.cooldownText, textAlignStyle]}>
                  {t('cooldown_active_label', 'Cooldown active')}: {cooldownSec}s
                </Text>
              ) : (
                <Text style={[styles.readyText, textAlignStyle]}>{t('ready_to_claim', 'Ready to Claim')}</Text>
              )}
            </View>
            <View style={styles.taskProgress}>
              <Text style={styles.progressText}>{userProfile?.subscription?.ads_watched_today || 0} watched</Text>
            </View>
          </View>
        </View>

        {/* VIP Packages */}
        <Text style={[styles.sectionTitle, textAlignStyle]}>{t('vip_packages', 'Upgrade Packages')}</Text>
        {plans.map((plan) => {
          const isSelected = selectedPlan === plan.id;
          return (
            <TouchableOpacity
              key={plan.id}
              style={[
                styles.planCard,
                isSelected && styles.planCardSelected,
                rowStyle
              ]}
              onPress={() => setSelectedPlan(plan.id as SubscriptionPlan)}
            >
              <View style={styles.planIconWrapper}>
                <FontAwesome5 name={plan.icon} size={28} color={isSelected ? 'hsl(45, 95%, 55%)' : 'hsl(0, 0%, 70%)'} />
              </View>
              
              <View style={[styles.planDetails, marginStartStyle(12)]}>
                <Text style={[styles.planName, isSelected && { color: 'hsl(45, 95%, 65%)' }, textAlignStyle]}>
                  {plan.name}
                </Text>
                <Text style={[styles.planPrice, textAlignStyle]}>
                  {plan.price} Coins
                </Text>
                <Text style={[styles.planMeta, textAlignStyle]}>
                  {t('share_weight', 'Share Weight')}: {plan.weight}x • {t('earning_cap', 'Earning Cap')}: {plan.cap} Coins
                </Text>
              </View>
              
              <View style={styles.planSelector}>
                <View style={[styles.radio, isSelected && styles.radioSelected]} />
              </View>
            </TouchableOpacity>
          );
        })}

        {/* Buy VIP Button */}
        <TouchableOpacity
          style={styles.buyBtn}
          onPress={handlePurchase}
          disabled={purchasing}
        >
          {purchasing ? (
            <ActivityIndicator size="small" color="#000" />
          ) : (
            <Text style={styles.buyBtnText}>{t('upgrade_vip_btn', 'Unlock Premium Access Now')}</Text>
          )}
        </TouchableOpacity>

        <View style={{ height: 100 }} />
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  scrollContent: {
    padding: 20,
  },
  header: {
    alignItems: 'center',
    marginBottom: 24,
    marginTop: 10,
  },
  title: {
    fontSize: 28,
    fontWeight: 'bold',
    letterSpacing: 0.5,
    marginBottom: 8,
  },
  subtitle: {
    fontSize: 14,
    color: 'hsl(210, 15%, 75%)',
    textAlign: 'center',
    lineHeight: 20,
    paddingHorizontal: 10,
  },
  glassCard: {
    backgroundColor: 'hsla(0, 0%, 100%, 0.06)',
    borderColor: 'hsla(0, 0%, 100%, 0.12)',
    borderWidth: 1,
    borderRadius: 16,
    padding: 16,
    marginBottom: 20,
  },
  cardTitle: {
    fontSize: 16,
    fontWeight: 'bold',
    color: '#FFFFFF',
    marginBottom: 12,
  },
  statusRow: {
    justifyContent: 'space-between',
    alignItems: 'center',
    marginVertical: 6,
  },
  statusLabel: {
    fontSize: 14,
    color: 'hsl(210, 10%, 75%)',
  },
  statusValue: {
    fontSize: 14,
    color: '#FFFFFF',
  },
  solvencyBadge: {
    paddingVertical: 6,
    paddingHorizontal: 12,
    borderRadius: 8,
    alignSelf: 'flex-start',
    marginVertical: 8,
  },
  solvencyStatusText: {
    fontSize: 13,
    fontWeight: 'bold',
  },
  solvencyDesc: {
    fontSize: 12,
    color: 'hsl(210, 10%, 65%)',
    lineHeight: 16,
    marginTop: 6,
  },
  taskItem: {
    alignItems: 'center',
    paddingVertical: 8,
  },
  taskIcon: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: 'hsla(0, 0%, 100%, 0.08)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  taskDetails: {
    flex: 1,
  },
  taskName: {
    color: '#FFFFFF',
    fontSize: 14,
    fontWeight: 'bold',
  },
  cooldownText: {
    color: 'hsl(350, 80%, 65%)',
    fontSize: 12,
    marginTop: 2,
  },
  readyText: {
    color: 'hsl(142, 70%, 55%)',
    fontSize: 12,
    fontWeight: 'bold',
    marginTop: 2,
  },
  taskProgress: {
    backgroundColor: 'hsla(0, 0%, 100%, 0.12)',
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderRadius: 12,
  },
  progressText: {
    color: '#FFFFFF',
    fontSize: 12,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#FFFFFF',
    marginBottom: 16,
    marginTop: 8,
  },
  planCard: {
    backgroundColor: 'hsla(0, 0%, 100%, 0.05)',
    borderColor: 'hsla(0, 0%, 100%, 0.1)',
    borderWidth: 1,
    borderRadius: 16,
    padding: 16,
    marginBottom: 12,
    alignItems: 'center',
  },
  planCardSelected: {
    borderColor: 'hsl(45, 95%, 55%)',
    backgroundColor: 'hsla(45, 95%, 55%, 0.08)',
  },
  planIconWrapper: {
    width: 48,
    height: 48,
    borderRadius: 24,
    backgroundColor: 'hsla(0, 0%, 100%, 0.06)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  planDetails: {
    flex: 1,
  },
  planName: {
    color: '#FFFFFF',
    fontSize: 15,
    fontWeight: 'bold',
  },
  planPrice: {
    color: 'hsl(45, 90%, 60%)',
    fontSize: 14,
    fontWeight: '600',
    marginTop: 2,
  },
  planMeta: {
    color: 'hsl(210, 10%, 70%)',
    fontSize: 11,
    marginTop: 4,
  },
  planSelector: {
    justifyContent: 'center',
    alignItems: 'center',
    width: 24,
    height: 24,
  },
  radio: {
    width: 18,
    height: 18,
    borderRadius: 9,
    borderWidth: 2,
    borderColor: 'hsl(0, 0%, 60%)',
  },
  radioSelected: {
    borderColor: 'hsl(45, 95%, 55%)',
    backgroundColor: 'hsl(45, 95%, 55%)',
  },
  buyBtn: {
    backgroundColor: 'hsl(45, 95%, 55%)',
    borderRadius: 14,
    paddingVertical: 16,
    justifyContent: 'center',
    alignItems: 'center',
    marginTop: 16,
    shadowColor: 'hsl(45, 95%, 35%)',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.3,
    shadowRadius: 8,
    elevation: 4,
  },
  buyBtnText: {
    color: '#000000',
    fontSize: 16,
    fontWeight: 'bold',
  }
});
