import React, { useState } from 'react';
import {
  StyleSheet,
  Text,
  View,
  TouchableOpacity,
  TextInput,
  ScrollView,
  Share,
  Clipboard,
  Alert,
  ActivityIndicator,
  ViewStyle,
  TextStyle
} from 'react-native';
import { useTranslation } from 'react-i18next';
import { Feather, Ionicons, MaterialCommunityIcons } from '@expo/vector-icons';
import { useApp } from '../services/store';

export default function ReferralScreen() {
  const { t, i18n } = useTranslation();
  const isRTL = i18n.language === 'ar';
  
  const {
    userProfile,
    referrals,
    referralSettings,
    applyReferralCode,
    simulateFriendInvite,
    isLoading
  } = useApp();

  const [inputCode, setInputCode] = useState<string>('');
  const [submittingCode, setSubmittingCode] = useState<boolean>(false);
  const [simulating, setSimulating] = useState<boolean>(false);

  // Styles helpers
  const rowStyle: ViewStyle = { flexDirection: isRTL ? 'row-reverse' : 'row' };
  const textAlignStyle: TextStyle = { textAlign: isRTL ? 'right' : 'left' };
  const marginStartStyle = (val: number) => isRTL ? { marginRight: val } : { marginLeft: val };
  const marginEndStyle = (val: number) => isRTL ? { marginLeft: val } : { marginRight: val };

  const handleCopyCode = () => {
    if (userProfile?.referral_code) {
      Clipboard.setString(userProfile.referral_code);
      Alert.alert(t('copied', 'Copied'), t('code_copied_success', 'Referral code copied successfully!'));
    }
  };

  const handleShareCode = async () => {
    if (!userProfile?.referral_code) return;
    try {
      const message = isRTL
        ? `حمل التطبيق الآن وسجل باستخدام كود الإحالة الخاص بي: ${userProfile.referral_code} للحصول على 100 عملة مجاناً!`
        : `Download the app now and register using my referral code: ${userProfile.referral_code} to get 100 coins for free!`;
      await Share.share({ message });
    } catch (error) {
      console.error('Share error:', error);
    }
  };

  const handleSubmitReferral = async () => {
    if (!inputCode.trim()) {
      Alert.alert(t('error', 'Error'), t('enter_code_prompt', 'Please enter a code.'));
      return;
    }

    setSubmittingCode(true);
    try {
      const result = await applyReferralCode(inputCode.trim());
      if (result.success) {
        Alert.alert(
          t('success', 'Success'),
          `${t('ref_applied_success', 'Referral applied!')} +${result.rewardCoins} ${t('coins', 'Coins')}`
        );
        setInputCode('');
      } else {
        let msg = t('purchase_failed', 'Operation failed.');
        if (result.error === 'system_inactive') {
          msg = t('ref_system_inactive', 'Referral system is currently disabled by Admin.');
        } else if (result.error === 'self_referral_blocked') {
          msg = t('self_referral_blocked_msg', 'You cannot use your own referral code!');
        } else if (result.error === 'already_referred') {
          msg = t('already_referred_msg', 'You have already registered using a referral code.');
        } else if (result.error === 'invalid_code') {
          msg = t('invalid_code_msg', 'The referral code entered is invalid.');
        } else if (result.error === 'rate_limit_exceeded') {
          msg = t('rate_limit_exceeded_msg', 'Too many referrals in a short time. Please try again later.');
        }
        Alert.alert(t('error', 'Error'), msg);
      }
    } catch (e) {
      Alert.alert(t('error', 'Error'), t('purchase_failed', 'Operation failed.'));
    } finally {
      setSubmittingCode(false);
    }
  };

  const handleSimulateInvite = async () => {
    setSimulating(true);
    try {
      const result = await simulateFriendInvite();
      if (result.success) {
        Alert.alert(
          t('success', 'Success'),
          t('sim_invite_success', 'A simulated friend registered! Referrer reward added.')
        );
      } else {
        let msg = t('purchase_failed', 'Simulation failed.');
        if (result.error === 'rate_limit_exceeded') {
          msg = t('rate_limit_exceeded_msg', 'Security Warning: Rate limit reached! Max 3 referrals per hour allowed.');
        } else if (result.error === 'system_inactive') {
          msg = t('ref_system_inactive', 'Referral system is disabled by Admin.');
        }
        Alert.alert(t('error', 'Error'), msg);
      }
    } catch (e) {
      Alert.alert(t('error', 'Error'), t('purchase_failed', 'Simulation failed.'));
    } finally {
      setSimulating(false);
    }
  };

  // Ahmed's code
  const myCode = userProfile?.referral_code || '';
  const myInviteCount = userProfile?.referral_count || 0;
  
  // Calculate total earnings: reward * count
  const refReward = referralSettings?.referrer_reward || 100;
  const totalEarnings = myInviteCount * refReward;

  // Filter only Ahmed's successful referrals
  const myInvitedFriends = referrals.filter(r => r.status === 'SUCCESS' && r.referrer_id === userProfile?.id);

  return (
    <View style={styles.container}>
      <ScrollView contentContainerStyle={styles.scrollContent} showsVerticalScrollIndicator={false}>
        
        {/* Title & Icon Header */}
        <View style={styles.topHeader}>
          <View style={styles.iconCircle}>
            <Ionicons name="people-outline" size={32} color="#00A896" />
          </View>
          <Text style={styles.title}>{t('nav_referrals', 'Referrals')}</Text>
          <Text style={styles.subtitle}>
            {t('ref_description', 'Invite your friends to earn coins. The more friends you invite, the more coins you get!')}
          </Text>
        </View>

        {/* 1) Referral Code Container */}
        <View style={styles.codeCard}>
          <Text style={styles.cardLabel}>{t('your_ref_code', 'YOUR REFERRAL CODE')}</Text>
          <View style={[styles.codeRow, rowStyle]}>
            <Text style={styles.codeText}>{myCode}</Text>
            <View style={[styles.codeActions, rowStyle]}>
              <TouchableOpacity style={styles.copyBtn} onPress={handleCopyCode}>
                <Feather name="copy" size={20} color="#00A896" />
              </TouchableOpacity>
              <TouchableOpacity style={[styles.shareBtn, marginStartStyle(10)]} onPress={handleShareCode}>
                <Feather name="share-2" size={20} color="#FFFFFF" />
              </TouchableOpacity>
            </View>
          </View>
        </View>

        {/* 2) Statistics Grid */}
        <View style={[styles.statsRow, rowStyle]}>
          <View style={styles.statBox}>
            <Feather name="users" size={22} color="#00A896" style={styles.statIcon} />
            <Text style={styles.statVal}>{myInviteCount}</Text>
            <Text style={styles.statLabel}>{t('total_invites', 'Total Invites')}</Text>
          </View>

          <View style={styles.statBox}>
            <MaterialCommunityIcons name="piggy-bank-outline" size={24} color="#00A896" style={styles.statIcon} />
            <Text style={styles.statVal}>{totalEarnings.toLocaleString()}</Text>
            <Text style={styles.statLabel}>{t('earned_coins', 'Total Earned')}</Text>
          </View>
        </View>

        {/* 3) Enter Code Section */}
        <View style={styles.enterCodeCard}>
          <Text style={[styles.cardTitle, textAlignStyle]}>{t('enter_friend_code', 'Enter Friend\'s Code')}</Text>
          
          {userProfile?.referred_by ? (
            <View style={[styles.referredByBadge, rowStyle]}>
              <Ionicons name="checkmark-circle" size={18} color="#00A896" style={marginEndStyle(6)} />
              <Text style={styles.referredByText}>
                {t('referred_by_indicator', 'You registered using code:')} {userProfile.referred_by}
              </Text>
            </View>
          ) : (
            <View>
              <Text style={[styles.enterCodeDesc, textAlignStyle]}>
                {t('enter_code_desc', 'Enter a friend\'s referral code to get bonus coins instantly.')}
              </Text>
              <View style={[styles.inputRow, rowStyle]}>
                <TextInput
                  style={[styles.input, { flex: 1 }, marginEndStyle(10), textAlignStyle]}
                  placeholder={t('enter_code_placeholder', 'Enter code... (e.g. D3X7-9LQ)')}
                  value={inputCode}
                  onChangeText={setInputCode}
                  autoCapitalize="characters"
                />
                <TouchableOpacity 
                  style={styles.applyBtn} 
                  onPress={handleSubmitReferral}
                  disabled={submittingCode}
                >
                  {submittingCode ? (
                    <ActivityIndicator size="small" color="#FFFFFF" />
                  ) : (
                    <Text style={styles.applyBtnText}>{t('apply', 'Apply')}</Text>
                  )}
                </TouchableOpacity>
              </View>
            </View>
          )}
        </View>

        {/* 4) Recent Invites List */}
        <Text style={[styles.sectionTitle, textAlignStyle]}>{t('recent_invites', 'Recent Invites')}</Text>
        {myInvitedFriends.length === 0 ? (
          <View style={styles.emptyInvites}>
            <Feather name="user-plus" size={32} color="#94A3B8" />
            <Text style={styles.emptyInvitesText}>{t('no_invites_yet', 'No friends invited yet.')}</Text>
          </View>
        ) : (
          myInvitedFriends.map(friend => (
            <View key={friend.id} style={[styles.friendCard, rowStyle]}>
              <View style={styles.friendAvatar}>
                <Text style={styles.friendAvatarText}>
                  {friend.referred_name.charAt(0)}
                </Text>
              </View>
              <View style={[styles.friendDetails, marginStartStyle(12)]}>
                <Text style={[styles.friendName, textAlignStyle]}>{friend.referred_name}</Text>
                <Text style={[styles.friendDate, textAlignStyle]}>
                  {new Date(friend.timestamp).toLocaleDateString()}
                </Text>
              </View>
              <View style={[styles.friendReward, rowStyle]}>
                <Text style={styles.rewardText}>+{friend.reward_coins}</Text>
                <Image source={require('../../assets/coins_stack_3d.png')} style={styles.rewardCoinIcon} />
              </View>
            </View>
          ))
        )}

        {/* 5) DEV Simulation Button (Shown in DEV mode only) */}
        {__DEV__ && (
          <View style={styles.devContainer}>
            <Text style={styles.devTitle}>{t('dev_simulation_tool', 'DEV Simulation Tool')}</Text>
            <TouchableOpacity 
              style={[styles.devBtn, simulating ? styles.devBtnLoading : null]} 
              onPress={handleSimulateInvite}
              disabled={simulating}
            >
              {simulating ? (
                <ActivityIndicator size="small" color="#00A896" />
              ) : (
                <View style={styles.devBtnContent}>
                  <Ionicons name="construct-outline" size={18} color="#00A896" style={{ marginRight: 6 }} />
                  <Text style={styles.devBtnText}>{t('simulate_friend_invite', 'Simulate Friend Registration')}</Text>
                </View>
              )}
            </TouchableOpacity>
          </View>
        )}

        <View style={{ height: 120 }} />
      </ScrollView>
    </View>
  );
}

// Simple Image placeholder helper for code
import { Image } from 'react-native';

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F8FAFC',
  },
  scrollContent: {
    padding: 20,
  },
  topHeader: {
    alignItems: 'center',
    marginVertical: 16,
  },
  iconCircle: {
    width: 64,
    height: 64,
    borderRadius: 32,
    backgroundColor: '#E6F7F5',
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 12,
  },
  title: {
    fontSize: 22,
    fontWeight: 'bold',
    color: '#1E293B',
    marginBottom: 6,
  },
  subtitle: {
    fontSize: 13,
    color: '#64748B',
    textAlign: 'center',
    lineHeight: 18,
    paddingHorizontal: 16,
  },
  codeCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 24,
    borderWidth: 1.5,
    borderColor: '#E6F7F5',
    padding: 20,
    marginBottom: 16,
    shadowColor: '#00A896',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.03,
    shadowRadius: 10,
    elevation: 2,
  },
  cardLabel: {
    fontSize: 11,
    fontWeight: 'bold',
    color: '#94A3B8',
    letterSpacing: 1,
    marginBottom: 8,
    textAlign: 'center',
  },
  codeRow: {
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  codeText: {
    fontSize: 28,
    fontWeight: '900',
    color: '#00A896',
    letterSpacing: 1,
  },
  codeActions: {
    alignItems: 'center',
  },
  copyBtn: {
    width: 44,
    height: 44,
    borderRadius: 14,
    backgroundColor: '#E6F7F5',
    justifyContent: 'center',
    alignItems: 'center',
  },
  shareBtn: {
    width: 44,
    height: 44,
    borderRadius: 14,
    backgroundColor: '#00A896',
    justifyContent: 'center',
    alignItems: 'center',
  },
  statsRow: {
    justifyContent: 'space-between',
    marginBottom: 16,
  },
  statBox: {
    width: '48%',
    backgroundColor: '#FFFFFF',
    borderRadius: 20,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    padding: 16,
    alignItems: 'center',
  },
  statIcon: {
    marginBottom: 8,
  },
  statVal: {
    fontSize: 20,
    fontWeight: '900',
    color: '#1E293B',
    marginBottom: 2,
  },
  statLabel: {
    fontSize: 11,
    fontWeight: '600',
    color: '#64748B',
  },
  enterCodeCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 24,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    padding: 20,
    marginBottom: 24,
  },
  cardTitle: {
    fontSize: 15,
    fontWeight: 'bold',
    color: '#1E293B',
    marginBottom: 6,
  },
  enterCodeDesc: {
    fontSize: 12,
    color: '#64748B',
    lineHeight: 16,
    marginBottom: 12,
  },
  referredByBadge: {
    backgroundColor: '#F8FAFC',
    borderRadius: 14,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    paddingVertical: 12,
    paddingHorizontal: 16,
    alignItems: 'center',
    justifyContent: 'center',
  },
  referredByText: {
    fontSize: 13,
    fontWeight: '600',
    color: '#00A896',
  },
  inputRow: {
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  input: {
    height: 48,
    backgroundColor: '#F8FAFC',
    borderWidth: 1,
    borderColor: '#E2E8F0',
    borderRadius: 14,
    paddingHorizontal: 16,
    fontSize: 14,
    color: '#1E293B',
  },
  applyBtn: {
    backgroundColor: '#1E293B',
    borderRadius: 14,
    paddingHorizontal: 20,
    height: 48,
    justifyContent: 'center',
    alignItems: 'center',
  },
  applyBtnText: {
    fontSize: 13,
    color: '#FFFFFF',
    fontWeight: 'bold',
  },
  sectionTitle: {
    fontSize: 16,
    fontWeight: 'bold',
    color: '#1E293B',
    marginBottom: 12,
  },
  emptyInvites: {
    backgroundColor: '#FFFFFF',
    borderRadius: 20,
    paddingVertical: 32,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 1,
    borderColor: '#E2E8F0',
    marginBottom: 20,
  },
  emptyInvitesText: {
    fontSize: 13,
    color: '#64748B',
    marginTop: 10,
  },
  friendCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 20,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    padding: 12,
    alignItems: 'center',
    marginBottom: 10,
  },
  friendAvatar: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: '#E6F7F5',
    justifyContent: 'center',
    alignItems: 'center',
  },
  friendAvatarText: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#00A896',
  },
  friendDetails: {
    flex: 1,
  },
  friendName: {
    fontSize: 14,
    fontWeight: 'bold',
    color: '#1E293B',
    marginBottom: 2,
  },
  friendDate: {
    fontSize: 11,
    color: '#94A3B8',
  },
  friendReward: {
    alignItems: 'center',
  },
  rewardText: {
    fontSize: 15,
    fontWeight: 'bold',
    color: '#00A896',
  },
  rewardCoinIcon: {
    width: 14,
    height: 14,
    resizeMode: 'contain',
    marginLeft: 3,
  },
  devContainer: {
    marginTop: 32,
    backgroundColor: '#FFFBEB',
    borderWidth: 1,
    borderColor: '#FDE68A',
    borderRadius: 20,
    padding: 16,
    alignItems: 'center',
  },
  devTitle: {
    fontSize: 11,
    fontWeight: 'bold',
    color: '#D97706',
    letterSpacing: 1,
    marginBottom: 12,
  },
  devBtn: {
    width: '100%',
    backgroundColor: '#FFFFFF',
    borderWidth: 1.5,
    borderColor: '#00A896',
    borderRadius: 14,
    paddingVertical: 10,
    alignItems: 'center',
    justifyContent: 'center',
  },
  devBtnLoading: {
    borderColor: '#CBD5E1',
  },
  devBtnContent: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  devBtnText: {
    fontSize: 13,
    fontWeight: 'bold',
    color: '#00A896',
  },
});
