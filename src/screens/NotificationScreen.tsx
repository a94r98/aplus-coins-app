import React, { useState } from 'react';
import {
  StyleSheet,
  Text,
  View,
  ScrollView,
  TouchableOpacity,
  Dimensions,
  ViewStyle,
  TextStyle
} from 'react-native';
import { useTranslation } from 'react-i18next';
import { Ionicons, Feather } from '@expo/vector-icons';
import { useApp } from '../services/store';
import { Notification } from '../services/api';

const { width } = Dimensions.get('window');

interface NotificationScreenProps {
  onBack: () => void;
}

type FilterType = 'all' | 'earnings' | 'store' | 'withdraw' | 'admin';

export default function NotificationScreen({ onBack }: NotificationScreenProps) {
  const { t, i18n } = useTranslation();
  const isRTL = i18n.language === 'ar';
  
  const { notifications, markNotificationRead } = useApp();
  const [activeFilter, setActiveFilter] = useState<FilterType>('all');

  const rowStyle: ViewStyle = { flexDirection: isRTL ? 'row-reverse' : 'row' };
  const textAlignStyle: TextStyle = { textAlign: isRTL ? 'right' : 'left' };
  const marginStartStyle = (val: number) => isRTL ? { marginRight: val } : { marginLeft: val };

  // Filter logic
  const filteredNotifications = notifications.filter(n => {
    if (activeFilter === 'all') return true;
    if (activeFilter === 'earnings') return n.type === 'EARN' || n.type === 'REFERRAL';
    if (activeFilter === 'store') return n.type === 'SPEND';
    if (activeFilter === 'withdraw') return n.type === 'WITHDRAW' || n.type === 'REFUND';
    if (activeFilter === 'admin') return n.type === 'SYSTEM';
    return true;
  });

  // Helper to mark all as read
  const handleMarkAllAsRead = async () => {
    const unread = notifications.filter(n => !n.read);
    for (const notif of unread) {
      await markNotificationRead(notif.id);
    }
  };

  // Helper to get type styling
  const getTypeStyling = (type: Notification['type']) => {
    switch (type) {
      case 'EARN':
      case 'REFERRAL':
        return {
          icon: 'trending-up-outline' as const,
          bgColor: 'hsla(150, 80%, 40%, 0.12)',
          iconColor: 'hsl(150, 80%, 35%)',
          borderColor: 'hsla(150, 80%, 40%, 0.3)'
        };
      case 'WITHDRAW':
        return {
          icon: 'arrow-down-circle-outline' as const,
          bgColor: 'hsla(30, 90%, 50%, 0.12)',
          iconColor: 'hsl(30, 90%, 45%)',
          borderColor: 'hsla(30, 90%, 50%, 0.3)'
        };
      case 'REFUND':
        return {
          icon: 'refresh-outline' as const,
          bgColor: 'hsla(180, 75%, 45%, 0.12)',
          iconColor: 'hsl(180, 75%, 40%)',
          borderColor: 'hsla(180, 75%, 45%, 0.3)'
        };
      case 'SPEND':
        return {
          icon: 'cart-outline' as const,
          bgColor: 'hsla(205, 85%, 45%, 0.12)',
          iconColor: 'hsl(205, 85%, 40%)',
          borderColor: 'hsla(205, 85%, 45%, 0.3)'
        };
      case 'SYSTEM':
      default:
        return {
          icon: 'shield-outline' as const,
          bgColor: 'hsla(280, 80%, 55%, 0.12)',
          iconColor: 'hsl(280, 80%, 50%)',
          borderColor: 'hsla(280, 80%, 55%, 0.3)'
        };
    }
  };

  // Format time relative
  const formatTime = (isoString: string) => {
    try {
      const date = new Date(isoString);
      const diffMs = Date.now() - date.getTime();
      const diffMins = Math.floor(diffMs / 60000);
      const diffHours = Math.floor(diffMins / 60);
      const diffDays = Math.floor(diffHours / 24);

      if (diffMins < 1) return isRTL ? 'الآن' : 'Just now';
      if (diffMins < 60) return isRTL ? `منذ ${diffMins} د` : `${diffMins}m ago`;
      if (diffHours < 24) return isRTL ? `منذ ${diffHours} س` : `${diffHours}h ago`;
      if (diffDays < 7) return isRTL ? `منذ ${diffDays} ي` : `${diffDays}d ago`;

      return date.toLocaleDateString(isRTL ? 'ar-EG' : 'en-US', {
        month: 'short',
        day: 'numeric'
      });
    } catch {
      return '';
    }
  };

  const filters: { key: FilterType; labelKey: string }[] = [
    { key: 'all', labelKey: 'filter_all' },
    { key: 'earnings', labelKey: 'filter_earnings' },
    { key: 'store', labelKey: 'filter_store' },
    { key: 'withdraw', labelKey: 'filter_withdraw' },
    { key: 'admin', labelKey: 'filter_admin' }
  ];

  return (
    <View style={styles.container}>
      {/* Header */}
      <View style={[styles.header, rowStyle]}>
        <TouchableOpacity style={styles.backButton} onPress={onBack}>
          <Feather name={isRTL ? "arrow-right" : "arrow-left"} size={24} color="#1E293B" />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>{t('notifications_title', 'Notifications')}</Text>
        <TouchableOpacity style={styles.markReadButton} onPress={handleMarkAllAsRead}>
          <Text style={styles.markReadText}>{t('mark_all_read', 'Mark all read')}</Text>
        </TouchableOpacity>
      </View>

      {/* Horizontal filters */}
      <View style={{ backgroundColor: '#FFFFFF', borderBottomWidth: 1, borderColor: '#F1F5F9' }}>
        <ScrollView
          horizontal
          showsHorizontalScrollIndicator={false}
          contentContainerStyle={[rowStyle, styles.filtersScroll]}
        >
          {filters.map(item => {
            const isActive = activeFilter === item.key;
            return (
              <TouchableOpacity
                key={item.key}
                style={[
                  styles.filterPill,
                  isActive && styles.filterPillActive,
                  marginStartStyle(8)
                ]}
                onPress={() => setActiveFilter(item.key)}
              >
                <Text style={[styles.filterPillText, isActive && styles.filterPillTextActive]}>
                  {t(item.labelKey, item.key.toUpperCase())}
                </Text>
              </TouchableOpacity>
            );
          })}
        </ScrollView>
      </View>

      {/* Timeline Scroll */}
      <ScrollView contentContainerStyle={styles.scrollContent} showsVerticalScrollIndicator={false}>
        {filteredNotifications.length === 0 ? (
          <View style={styles.emptyContainer}>
            <View style={styles.emptyIconCircle}>
              <Feather name="bell-off" size={40} color="#94A3B8" />
            </View>
            <Text style={styles.emptyTitle}>{t('no_notifications', "You're all caught up!")}</Text>
            <Text style={styles.emptySub}>{t('no_notifications_desc', "When you receive notifications, they'll show up here.")}</Text>
          </View>
        ) : (
          <View style={styles.timelineContainer}>
            {/* Vertical Line */}
            <View style={[styles.timelineLine, isRTL ? { right: 23 } : { left: 23 }]} />

            {filteredNotifications.map((item) => {
              const stylesType = getTypeStyling(item.type);
              return (
                <TouchableOpacity
                  key={item.id}
                  activeOpacity={0.8}
                  style={[styles.notificationCard, rowStyle]}
                  onPress={() => markNotificationRead(item.id)}
                >
                  {/* Timeline Node Icon */}
                  <View style={[
                    styles.nodeIconContainer,
                    {
                      backgroundColor: stylesType.bgColor,
                      borderColor: stylesType.borderColor
                    }
                  ]}>
                    <Ionicons name={stylesType.icon} size={20} color={stylesType.iconColor} />
                  </View>

                  {/* Card Content */}
                  <View style={[styles.cardContent, marginStartStyle(16)]}>
                    <View style={[styles.cardHeader, rowStyle]}>
                      <Text style={[
                        styles.cardTitle,
                        textAlignStyle,
                        !item.read && styles.unreadText
                      ]}>
                        {isRTL ? item.title_ar : item.title_en}
                      </Text>
                      <Text style={styles.timeText}>{formatTime(item.created_at)}</Text>
                    </View>

                    <Text style={[styles.cardMessage, textAlignStyle]}>
                      {isRTL ? item.message_ar : item.message_en}
                    </Text>

                    {/* Unread dot indicator */}
                    {!item.read && (
                      <View style={[styles.unreadDot, isRTL ? { left: 8 } : { right: 8 }]} />
                    )}
                  </View>
                </TouchableOpacity>
              );
            })}
          </View>
        )}
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F8FAFC',
  },
  header: {
    height: 60,
    backgroundColor: '#FFFFFF',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 16,
    borderBottomWidth: 1,
    borderColor: '#E2E8F0',
  },
  backButton: {
    padding: 8,
  },
  headerTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#1E293B',
  },
  markReadButton: {
    paddingVertical: 6,
    paddingHorizontal: 10,
  },
  markReadText: {
    fontSize: 13,
    color: '#00A896',
    fontWeight: '600',
  },
  filtersScroll: {
    paddingVertical: 10,
    paddingHorizontal: 16,
  },
  filterPill: {
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderRadius: 20,
    backgroundColor: '#F1F5F9',
  },
  filterPillActive: {
    backgroundColor: '#E6F7F5',
  },
  filterPillText: {
    fontSize: 13,
    fontWeight: '600',
    color: '#64748B',
  },
  filterPillTextActive: {
    color: '#00A896',
  },
  scrollContent: {
    paddingVertical: 20,
    paddingHorizontal: 16,
    flexGrow: 1,
  },
  emptyContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingVertical: 80,
  },
  emptyIconCircle: {
    width: 80,
    height: 80,
    borderRadius: 40,
    backgroundColor: '#F1F5F9',
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 16,
  },
  emptyTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#334155',
    marginBottom: 8,
  },
  emptySub: {
    fontSize: 14,
    color: '#64748B',
    textAlign: 'center',
    paddingHorizontal: 40,
  },
  timelineContainer: {
    position: 'relative',
  },
  timelineLine: {
    position: 'absolute',
    top: 24,
    bottom: 24,
    width: 2,
    backgroundColor: '#E2E8F0',
  },
  notificationCard: {
    marginBottom: 20,
    alignItems: 'flex-start',
    position: 'relative',
  },
  nodeIconContainer: {
    width: 48,
    height: 48,
    borderRadius: 24,
    borderWidth: 2,
    justifyContent: 'center',
    alignItems: 'center',
    zIndex: 2,
  },
  cardContent: {
    flex: 1,
    backgroundColor: '#FFFFFF',
    borderRadius: 16,
    padding: 16,
    shadowColor: '#0F172A',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.04,
    shadowRadius: 8,
    elevation: 2,
    position: 'relative',
  },
  cardHeader: {
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 6,
  },
  cardTitle: {
    fontSize: 14,
    fontWeight: '600',
    color: '#64748B',
    flex: 1,
  },
  unreadText: {
    color: '#1E293B',
    fontWeight: 'bold',
  },
  timeText: {
    fontSize: 11,
    color: '#94A3B8',
  },
  cardMessage: {
    fontSize: 13,
    color: '#475569',
    lineHeight: 18,
  },
  unreadDot: {
    position: 'absolute',
    top: 16,
    width: 6,
    height: 6,
    borderRadius: 3,
    backgroundColor: '#FF5A5F',
  }
});
