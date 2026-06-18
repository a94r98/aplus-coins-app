import React, { useState, useEffect } from 'react';
import {
  StyleSheet,
  Text,
  View,
  TouchableOpacity,
  ScrollView,
  TextInput,
  Image,
  Dimensions,
  ActivityIndicator,
  Alert,
  ViewStyle,
  TextStyle,
  KeyboardAvoidingView,
  Platform
} from 'react-native';
import { useTranslation } from 'react-i18next';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons, Feather, MaterialCommunityIcons } from '@expo/vector-icons';
import { useApp } from '../services/store';

const { width } = Dimensions.get('window');

// Available payment methods
const PAYMENT_METHODS = [
  { id: 'zain_cash', name: 'Zain Cash', icon: 'phone-portrait-outline', color: '#FF5A5F' },
  { id: 'fast_pay', name: 'FastPay', icon: 'wallet-outline', color: '#00A896' },
  { id: 'paypal', name: 'PayPal', icon: 'logo-paypal', color: '#0079C1' },
  { id: 'usdt', name: 'USDT (TRC20)', icon: 'logo-usd', color: '#26A17B' }
];

export default function WalletScreen() {
  const { t, i18n } = useTranslation();
  const isRTL = i18n.language === 'ar';

  const {
    userCoins,
    userProfile,
    walletSettings,
    walletTransactions,
    storeWithdrawals,
    availableBalance,
    pendingBalance,
    totalEarned,
    financialIntegrityStatus,
    requestWithdrawal,
    rebuildWalletBalance,
    isLoading
  } = useApp();

  // Form states
  const [selectedMethod, setSelectedMethod] = useState<string>('zain_cash');
  const [withdrawAmount, setWithdrawAmount] = useState<string>('');
  const [walletAddress, setWalletAddress] = useState<string>('');
  const [idempotencyKey, setIdempotencyKey] = useState<string>('');
  const [submitting, setSubmitting] = useState<boolean>(false);

  // Generate fresh idempotency key when screen mounts or withdrawal succeeds
  useEffect(() => {
    generateIdempotencyKey();
  }, []);

  const generateIdempotencyKey = () => {
    const key = `req_withdraw_${Math.random().toString(36).substring(2, 11)}_${Date.now()}`;
    setIdempotencyKey(key);
  };

  // Styles helpers
  const rowStyle: ViewStyle = { flexDirection: isRTL ? 'row-reverse' : 'row' };
  const textAlignStyle: TextStyle = { textAlign: isRTL ? 'right' : 'left' };
  const marginStartStyle = (val: number) => isRTL ? { marginRight: val } : { marginLeft: val };
  const marginEndStyle = (val: number) => isRTL ? { marginLeft: val } : { marginRight: val };

  // Live validation calculations
  const coinsNum = parseInt(withdrawAmount) || 0;
  const exchangeRate = walletSettings?.exchange_rate || 1000;
  const usdEquivalent = coinsNum / exchangeRate;

  // Validation checks
  const isAmountValid = coinsNum > 0;
  const isBelowMin = walletSettings ? coinsNum < walletSettings.min_withdraw : false;
  const isAboveMax = walletSettings ? coinsNum > walletSettings.max_withdraw : false;
  const hasEnoughBalance = availableBalance >= coinsNum;
  const isAddressValid = walletAddress.trim().length > 4;

  const isFormValid =
    isAmountValid &&
    !isBelowMin &&
    !isAboveMax &&
    hasEnoughBalance &&
    isAddressValid &&
    walletSettings?.withdraw_enabled &&
    !userProfile?.withdraw_frozen;

  const handleWithdrawSubmit = async () => {
    if (!isFormValid || !walletSettings) return;

    setSubmitting(true);
    try {
      const selectedMethodName = PAYMENT_METHODS.find(m => m.id === selectedMethod)?.name || selectedMethod;
      const res = await requestWithdrawal(coinsNum, selectedMethodName, walletAddress, idempotencyKey);
      
      if (res.success) {
        Alert.alert(
          t('success', 'Success'),
          t('withdraw_success_msg', 'Your withdrawal request has been placed successfully. It will be verified by administration.')
        );
        // Clear form and rotate idempotency key
        setWithdrawAmount('');
        setWalletAddress('');
        generateIdempotencyKey();
      } else {
        if (res.error === 'concurrency_lock_active') {
          Alert.alert(t('error', 'Error'), t('concurrency_lock_msg', 'Your wallet is busy. Please try again in a few seconds.'));
        } else if (res.error === 'wallet_frozen') {
          Alert.alert(t('error', 'Error'), t('wallet_frozen_msg', 'Your wallet is frozen. Please contact customer support.'));
        } else if (res.error === 'system_inactive') {
          Alert.alert(t('error', 'Error'), t('system_inactive_msg', 'Withdrawals are currently frozen by administration.'));
        } else {
          Alert.alert(t('error', 'Error'), t('withdraw_failed_msg', 'Withdrawal request failed.'));
        }
      }
    } catch (e) {
      Alert.alert(t('error', 'Error'), t('withdraw_failed_msg', 'Withdrawal request failed.'));
    } finally {
      setSubmitting(false);
    }
  };

  const getLedgerHealthConfig = () => {
    switch (financialIntegrityStatus) {
      case 'WARNING':
        return { label: t('ledger_health_warning', 'Warning'), color: '#FFB86C', icon: 'alert-circle' };
      case 'CRITICAL':
        return { label: t('ledger_health_critical', 'Critical'), color: '#FF5A5F', icon: 'close-circle' };
      case 'OK':
      default:
        return { label: t('ledger_health_ok', 'Secure'), color: '#02C39A', icon: 'checkmark-circle' };
    }
  };

  const healthConfig = getLedgerHealthConfig();

  // Map transaction types for timeline display
  const getTxTypeConfig = (type: string) => {
    switch (type) {
      case 'EARN':
        return { label: t('tx_type_earn', 'Earn'), color: '#02C39A', icon: 'arrow-down-circle-outline' };
      case 'SPEND':
        return { label: t('tx_type_spend', 'Spend'), color: '#FF5A5F', icon: 'cart-outline' };
      case 'WITHDRAW':
        return { label: t('tx_type_withdraw', 'Withdraw'), color: '#FFB86C', icon: 'arrow-up-circle-outline' };
      case 'REFUND':
        return { label: t('tx_type_refund', 'Refund'), color: '#BD93F9', icon: 'refresh-outline' };
      default:
        return { label: type, color: '#64748B', icon: 'help-circle-outline' };
    }
  };

  return (
    <KeyboardAvoidingView
      behavior={Platform.OS === 'ios' ? 'padding' : undefined}
      style={{ flex: 1 }}
    >
      <ScrollView style={styles.container} showsVerticalScrollIndicator={false}>
        
        {/* Header Section */}
        <LinearGradient
          colors={['#00B4DB', '#0083B0']}
          start={{ x: 0, y: 0 }}
          end={{ x: 1, y: 1 }}
          style={styles.headerCard}
        >
          <View style={[styles.headerRow, rowStyle]}>
            <View>
              <Text style={styles.headerTitle}>{t('my_wallet', 'My Wallet')}</Text>
              <Text style={styles.headerSubtitle}>{t('hybrid_ledger_desc', 'Hybrid Event Ledger system')}</Text>
            </View>
            
            {/* Ledger Integrity Status Badge */}
            <TouchableOpacity 
              style={[styles.healthBadge, { borderColor: healthConfig.color }, rowStyle]}
              onPress={rebuildWalletBalance}
              activeOpacity={0.7}
            >
              <Ionicons name={healthConfig.icon as any} size={14} color={healthConfig.color} style={marginEndStyle(4)} />
              <Text style={[styles.healthText, { color: healthConfig.color }]}>{healthConfig.label}</Text>
              {financialIntegrityStatus !== 'OK' && (
                <Ionicons name="sync-outline" size={12} color={healthConfig.color} style={marginStartStyle(4)} />
              )}
            </TouchableOpacity>
          </View>

          {/* Cards Grid */}
          <View style={styles.cardsGrid}>
            
            {/* 1. Available Balance */}
            <View style={styles.cardColFull}>
              <LinearGradient
                colors={['rgba(255, 255, 255, 0.15)', 'rgba(255, 255, 255, 0.05)']}
                style={styles.balanceDisplayCard}
              >
                <Text style={styles.cardLabel}>{t('available_balance', 'Available Balance')}</Text>
                <View style={[styles.cardValueRow, rowStyle]}>
                  <Text style={styles.cardValueCoins}>{availableBalance.toLocaleString()}</Text>
                  <Image source={require('../../assets/coins_stack_3d.png')} style={styles.coinIconLarge} />
                </View>
                <Text style={styles.cardValueUsd}>
                  ≈ ${(availableBalance / exchangeRate).toFixed(2)} USD
                </Text>
              </LinearGradient>
            </View>

            <View style={[styles.subCardsRow, rowStyle]}>
              {/* 2. Pending Balance */}
              <View style={styles.subCard}>
                <Text style={styles.subCardLabel}>{t('pending_balance', 'Pending')}</Text>
                <View style={[styles.subCardValueRow, rowStyle]}>
                  <Text style={styles.subCardValue}>{pendingBalance.toLocaleString()}</Text>
                  <Image source={require('../../assets/coins_stack_3d.png')} style={styles.coinIconSmall} />
                </View>
                <Text style={styles.subCardUsd}>
                  ≈ ${(pendingBalance / exchangeRate).toFixed(2)} USD
                </Text>
              </View>

              {/* 3. Total Earned */}
              <View style={styles.subCard}>
                <Text style={styles.subCardLabel}>{t('total_earned', 'Total Earned')}</Text>
                <View style={[styles.subCardValueRow, rowStyle]}>
                  <Text style={[styles.subCardValue, { color: '#02C39A' }]}>{totalEarned.toLocaleString()}</Text>
                  <Image source={require('../../assets/coins_stack_3d.png')} style={styles.coinIconSmall} />
                </View>
                <Text style={styles.subCardUsd}>
                  ≈ ${(totalEarned / exchangeRate).toFixed(2)} USD
                </Text>
              </View>
            </View>
          </View>
        </LinearGradient>

        {/* Withdrawal Form Area */}
        <View style={styles.sectionCard}>
          <Text style={[styles.sectionTitle, textAlignStyle]}>{t('withdraw_request_title', 'Request Withdrawal')}</Text>
          <Text style={[styles.sectionSubtitle, textAlignStyle]}>
            {t('withdraw_limits_desc', 'Limits:')} {walletSettings?.min_withdraw.toLocaleString()} - {walletSettings?.max_withdraw.toLocaleString()} {t('coins', 'Coins')}
          </Text>

          {/* Warning banner if frozen */}
          {userProfile?.withdraw_frozen && (
            <View style={[styles.dangerBanner, rowStyle]}>
              <Ionicons name="alert-circle" size={20} color="#FF5A5F" style={marginEndStyle(8)} />
              <Text style={styles.dangerBannerText}>
                {t('wallet_frozen_banner', 'Your wallet is frozen by administration due to safety flags.')}
              </Text>
            </View>
          )}

          {!walletSettings?.withdraw_enabled && (
            <View style={[styles.dangerBanner, rowStyle]}>
              <Ionicons name="alert-circle" size={20} color="#FF5A5F" style={marginEndStyle(8)} />
              <Text style={styles.dangerBannerText}>
                {t('withdraw_system_disabled_banner', 'Withdrawals are temporarily disabled for system updates.')}
              </Text>
            </View>
          )}

          {/* Payment Methods Slider */}
          <Text style={[styles.fieldLabel, textAlignStyle]}>{t('payment_method_lbl', 'Select Payment Method')}</Text>
          <View style={[styles.methodsRow, rowStyle]}>
            {PAYMENT_METHODS.map(method => (
              <TouchableOpacity
                key={method.id}
                style={[
                  styles.methodButton,
                  selectedMethod === method.id ? { borderColor: method.color, backgroundColor: `${method.color}10` } : null
                ]}
                onPress={() => setSelectedMethod(method.id)}
              >
                <Ionicons 
                  name={method.icon as any} 
                  size={20} 
                  color={selectedMethod === method.id ? method.color : '#64748B'} 
                />
                <Text style={[
                  styles.methodText, 
                  selectedMethod === method.id ? { color: method.color, fontWeight: '700' } : null
                ]}>
                  {method.name}
                </Text>
              </TouchableOpacity>
            ))}
          </View>

          {/* Amount Input */}
          <Text style={[styles.fieldLabel, textAlignStyle]}>{t('withdraw_amount_lbl', 'Amount (in Coins)')}</Text>
          <View style={[styles.inputWrapper, rowStyle]}>
            <TextInput
              style={[styles.textInput, textAlignStyle, { flex: 1 }]}
              placeholder={t('withdraw_amount_placeholder', 'Enter coins amount')}
              placeholderTextColor="#94A3B8"
              keyboardType="number-pad"
              value={withdrawAmount}
              onChangeText={setWithdrawAmount}
              editable={!(userProfile?.withdraw_frozen || !walletSettings?.withdraw_enabled)}
            />
            {coinsNum > 0 && (
              <Text style={styles.conversionSnap}>
                ≈ ${usdEquivalent.toFixed(2)} USD
              </Text>
            )}
          </View>

          {/* Validation Messages */}
          {withdrawAmount.length > 0 && (
            <View style={styles.validationWrapper}>
              {isBelowMin && (
                <Text style={[styles.errorText, textAlignStyle]}>
                  ⚠️ {t('error_below_min', 'Amount is below minimum allowed limit.')}
                </Text>
              )}
              {isAboveMax && (
                <Text style={[styles.errorText, textAlignStyle]}>
                  ⚠️ {t('error_above_max', 'Amount exceeds maximum allowed limit.')}
                </Text>
              )}
              {!hasEnoughBalance && (
                <Text style={[styles.errorText, textAlignStyle]}>
                  ⚠️ {t('error_insufficient', 'Insufficient available balance.')}
                </Text>
              )}
            </View>
          )}

          {/* Address/Number Input */}
          <Text style={[styles.fieldLabel, textAlignStyle]}>
            {selectedMethod === 'paypal' 
              ? t('paypal_email_lbl', 'PayPal Email') 
              : selectedMethod === 'usdt' 
              ? t('usdt_address_lbl', 'USDT Wallet Address (TRC-20)') 
              : t('payment_address_lbl', 'Wallet Account / Phone number')}
          </Text>
          <View style={[styles.inputWrapper, rowStyle]}>
            <TextInput
              style={[styles.textInput, textAlignStyle, { flex: 1 }]}
              placeholder={
                selectedMethod === 'paypal'
                  ? 'email@example.com'
                  : selectedMethod === 'usdt'
                  ? 'T...'
                  : '077xxxxxxx'
              }
              placeholderTextColor="#94A3B8"
              value={walletAddress}
              onChangeText={setWalletAddress}
              editable={!(userProfile?.withdraw_frozen || !walletSettings?.withdraw_enabled)}
            />
          </View>

          {/* Submit button */}
          <TouchableOpacity
            style={[styles.submitButton, !isFormValid ? styles.submitButtonDisabled : null]}
            onPress={handleWithdrawSubmit}
            disabled={!isFormValid || submitting}
          >
            {submitting ? (
              <ActivityIndicator color="#FFFFFF" size="small" />
            ) : (
              <Text style={styles.submitBtnText}>{t('withdraw_submit_btn', 'Send Request')}</Text>
            )}
          </TouchableOpacity>
        </View>

        {/* Ledger Transaction History */}
        <View style={styles.sectionCard}>
          <Text style={[styles.sectionTitle, textAlignStyle]}>{t('ledger_timeline_title', 'Financial Timeline')}</Text>
          <Text style={[styles.sectionSubtitle, textAlignStyle]}>
            {t('ledger_timeline_subtitle', 'Immutable chronological ledger transaction logs')}
          </Text>

          {walletTransactions.length === 0 ? (
            <View style={styles.emptyTimeline}>
              <MaterialCommunityIcons name="history" size={40} color="#CBD5E1" />
              <Text style={styles.emptyTimelineText}>{t('no_txs_yet', 'No transactions recorded in the ledger yet.')}</Text>
            </View>
          ) : (
            <View style={styles.timelineContainer}>
              {walletTransactions.map((tx) => {
                const txConfig = getTxTypeConfig(tx.type);
                const isDebit = tx.type === 'SPEND' || tx.type === 'WITHDRAW';
                const formattedValue = isDebit 
                  ? `-${Math.abs(tx.coins).toLocaleString()}` 
                  : `+${Math.abs(tx.coins).toLocaleString()}`;
                const formattedUsd = isDebit
                  ? `-$${Math.abs(tx.usd_snapshot).toFixed(2)}`
                  : `+$${Math.abs(tx.usd_snapshot).toFixed(2)}`;

                return (
                  <View key={tx.id} style={styles.timelineItem}>
                    
                    {/* Sequence Number Label */}
                    <View style={styles.seqBadge}>
                      <Text style={styles.seqBadgeText}>#{tx.sequence_number}</Text>
                    </View>

                    {/* Content Row */}
                    <View style={[styles.timelineItemContent, rowStyle]}>
                      
                      {/* Icon */}
                      <View style={[styles.txIconWrapper, { backgroundColor: `${txConfig.color}15` }]}>
                        <Ionicons name={txConfig.icon as any} size={20} color={txConfig.color} />
                      </View>

                      {/* Info Texts */}
                      <View style={[styles.txTexts, marginStartStyle(12)]}>
                        <Text style={[styles.txTitle, textAlignStyle]}>
                          {txConfig.label}
                        </Text>
                        <Text style={[styles.txRef, textAlignStyle]}>
                          Ref: {tx.reference_id}
                        </Text>
                        <Text style={[styles.txDate, textAlignStyle]}>
                          {new Date(tx.created_at).toLocaleDateString()} {new Date(tx.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                        </Text>
                      </View>

                      {/* Amounts */}
                      <View style={styles.txAmounts}>
                        <Text style={[styles.txCoinsVal, { color: txConfig.color }]}>
                          {formattedValue}
                        </Text>
                        <Text style={styles.txUsdVal}>
                          {formattedUsd}
                        </Text>
                      </View>
                    </View>
                  </View>
                );
              })}
            </View>
          )}
        </View>

        <View style={{ height: 120 }} />
      </ScrollView>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F8FAFC',
  },
  headerCard: {
    paddingTop: 50,
    paddingBottom: 24,
    paddingHorizontal: 20,
    borderBottomLeftRadius: 28,
    borderBottomRightRadius: 28,
  },
  headerRow: {
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 20,
  },
  headerTitle: {
    fontSize: 22,
    fontWeight: 'bold',
    color: '#FFFFFF',
    marginBottom: 2,
  },
  headerSubtitle: {
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.75)',
    fontWeight: '500',
  },
  healthBadge: {
    backgroundColor: '#FFFFFF',
    borderWidth: 1.5,
    borderRadius: 16,
    paddingVertical: 5,
    paddingHorizontal: 12,
    alignItems: 'center',
  },
  healthText: {
    fontSize: 11,
    fontWeight: 'bold',
  },
  cardsGrid: {
    width: '100%',
  },
  cardColFull: {
    width: '100%',
  },
  balanceDisplayCard: {
    borderRadius: 20,
    padding: 18,
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.2)',
    marginBottom: 12,
  },
  cardLabel: {
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.8)',
    fontWeight: '600',
    marginBottom: 6,
  },
  cardValueRow: {
    alignItems: 'center',
  },
  cardValueCoins: {
    fontSize: 30,
    fontWeight: '900',
    color: '#FFFFFF',
  },
  coinIconLarge: {
    width: 24,
    height: 24,
    resizeMode: 'contain',
    marginLeft: 6,
  },
  cardValueUsd: {
    fontSize: 14,
    color: '#FFFFFF',
    fontWeight: '700',
    marginTop: 4,
  },
  subCardsRow: {
    justifyContent: 'space-between',
  },
  subCard: {
    width: (width - 52) / 2,
    backgroundColor: 'rgba(255, 255, 255, 0.1)',
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.15)',
    borderRadius: 18,
    padding: 12,
  },
  subCardLabel: {
    fontSize: 10,
    color: 'rgba(255, 255, 255, 0.8)',
    fontWeight: '600',
    marginBottom: 4,
  },
  subCardValueRow: {
    alignItems: 'center',
  },
  subCardValue: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#FFB86C',
  },
  coinIconSmall: {
    width: 14,
    height: 14,
    resizeMode: 'contain',
    marginLeft: 4,
  },
  subCardUsd: {
    fontSize: 11,
    color: 'rgba(255, 255, 255, 0.7)',
    fontWeight: '600',
    marginTop: 2,
  },
  sectionCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 24,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    marginHorizontal: 16,
    marginTop: 16,
    padding: 20,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.02,
    shadowRadius: 10,
    elevation: 2,
  },
  sectionTitle: {
    fontSize: 16,
    fontWeight: 'bold',
    color: '#1E293B',
    marginBottom: 4,
  },
  sectionSubtitle: {
    fontSize: 11,
    color: '#64748B',
    marginBottom: 16,
  },
  dangerBanner: {
    backgroundColor: '#FFF1F2',
    borderWidth: 1,
    borderColor: '#FFE4E6',
    borderRadius: 14,
    padding: 12,
    alignItems: 'center',
    marginBottom: 16,
  },
  dangerBannerText: {
    flex: 1,
    fontSize: 11,
    color: '#FF5A5F',
    fontWeight: '600',
  },
  fieldLabel: {
    fontSize: 13,
    color: '#475569',
    fontWeight: '700',
    marginBottom: 8,
  },
  methodsRow: {
    flexWrap: 'wrap',
    justifyContent: 'space-between',
    marginBottom: 16,
  },
  methodButton: {
    width: (width - 80) / 2,
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 10,
    paddingHorizontal: 14,
    borderWidth: 1.5,
    borderColor: '#E2E8F0',
    borderRadius: 14,
    marginBottom: 8,
  },
  methodText: {
    fontSize: 12,
    color: '#64748B',
    fontWeight: '600',
    marginLeft: 8,
  },
  inputWrapper: {
    borderWidth: 1.5,
    borderColor: '#E2E8F0',
    borderRadius: 16,
    paddingHorizontal: 16,
    height: 52,
    alignItems: 'center',
    backgroundColor: '#F8FAFC',
    marginBottom: 12,
  },
  textInput: {
    fontSize: 14,
    color: '#1E293B',
    fontWeight: '600',
    height: '100%',
  },
  conversionSnap: {
    fontSize: 12,
    color: '#00A896',
    fontWeight: 'bold',
  },
  validationWrapper: {
    marginBottom: 10,
  },
  errorText: {
    fontSize: 11,
    color: '#FF5A5F',
    fontWeight: '600',
    marginBottom: 4,
  },
  submitButton: {
    backgroundColor: '#1E293B',
    borderRadius: 16,
    height: 52,
    justifyContent: 'center',
    alignItems: 'center',
    marginTop: 8,
    shadowColor: '#1E293B',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.1,
    shadowRadius: 10,
    elevation: 3,
  },
  submitButtonDisabled: {
    backgroundColor: '#CBD5E1',
    shadowOpacity: 0,
    elevation: 0,
  },
  submitBtnText: {
    color: '#FFFFFF',
    fontSize: 14,
    fontWeight: 'bold',
  },
  emptyTimeline: {
    alignItems: 'center',
    paddingVertical: 40,
  },
  emptyTimelineText: {
    fontSize: 12,
    color: '#94A3B8',
    marginTop: 8,
    textAlign: 'center',
  },
  timelineContainer: {
    marginTop: 8,
  },
  timelineItem: {
    position: 'relative',
    paddingLeft: 24,
    borderLeftWidth: 2,
    borderLeftColor: '#E2E8F0',
    paddingBottom: 20,
  },
  seqBadge: {
    position: 'absolute',
    left: -12,
    top: 2,
    backgroundColor: '#F1F5F9',
    borderWidth: 1,
    borderColor: '#CBD5E1',
    borderRadius: 8,
    paddingHorizontal: 4,
    paddingVertical: 2,
    alignItems: 'center',
    justifyContent: 'center',
  },
  seqBadgeText: {
    fontSize: 9,
    fontWeight: 'bold',
    color: '#64748B',
  },
  timelineItemContent: {
    backgroundColor: '#F8FAFC',
    borderWidth: 1,
    borderColor: '#E2E8F0',
    borderRadius: 16,
    padding: 12,
    alignItems: 'center',
  },
  txIconWrapper: {
    width: 36,
    height: 36,
    borderRadius: 12,
    justifyContent: 'center',
    alignItems: 'center',
  },
  txTexts: {
    flex: 1,
  },
  txTitle: {
    fontSize: 13,
    fontWeight: 'bold',
    color: '#1E293B',
  },
  txRef: {
    fontSize: 10,
    color: '#94A3B8',
    marginTop: 2,
  },
  txDate: {
    fontSize: 9,
    color: '#94A3B8',
    marginTop: 2,
  },
  txAmounts: {
    alignItems: 'flex-end',
  },
  txCoinsVal: {
    fontSize: 14,
    fontWeight: 'bold',
  },
  txUsdVal: {
    fontSize: 11,
    color: '#94A3B8',
    fontWeight: '600',
    marginTop: 2,
  },
});
