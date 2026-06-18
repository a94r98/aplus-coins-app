import React, { useState, useEffect } from 'react';
import {
  StyleSheet,
  Text,
  View,
  TouchableOpacity,
  Modal,
  Vibration
} from 'react-native';
import { Feather, Ionicons } from '@expo/vector-icons';
import { useTranslation } from 'react-i18next';
import * as Haptics from 'expo-haptics';
import { useApp } from '../services/store';

interface PinCodeModalProps {
  visible: boolean;
  onClose: () => void;
  onSuccess: () => void;
}

export default function PinCodeModal({ visible, onClose, onSuccess }: PinCodeModalProps) {
  const { t } = useTranslation();
  const { authenticateAdmin, pinLockoutTime } = useApp();
  const [pin, setPin] = useState<string>('');
  const [errorMessage, setErrorMessage] = useState<string>('');
  const [lockdownSec, setLockdownSec] = useState<number>(0);

  // Cooldown countdown effect
  useEffect(() => {
    let timer: ReturnType<typeof setTimeout>;
    if (pinLockoutTime) {
      const updateLockdown = () => {
        const diff = pinLockoutTime - Date.now();
        if (diff > 0) {
          setLockdownSec(Math.ceil(diff / 1000));
          timer = setTimeout(updateLockdown, 1000);
        } else {
          setLockdownSec(0);
          setErrorMessage('');
        }
      };
      updateLockdown();
    }
    return () => clearTimeout(timer);
  }, [pinLockoutTime]);

  const handleKeyPress = async (num: string) => {
    if (lockdownSec > 0) return;
    
    setErrorMessage('');
    
    // Play light haptic tap
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light).catch(() => {});

    if (pin.length < 4) {
      const newPin = pin + num;
      setPin(newPin);

      if (newPin.length === 4) {
        // Trigger validation
        const result = await authenticateAdmin(newPin);
        if (result.success) {
          Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success).catch(() => {});
          setPin('');
          onSuccess();
        } else {
          Haptics.notificationAsync(Haptics.NotificationFeedbackType.Error).catch(() => {});
          Vibration.vibrate(200);
          setPin('');
          if (result.locked) {
            setErrorMessage(t('locked_out', 'Locked out! Limit reached.'));
          } else {
            setErrorMessage(t('wrong_pin', 'Incorrect PIN code. Try again.'));
          }
        }
      }
    }
  };

  const handleDelete = () => {
    if (pin.length > 0) {
      Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light).catch(() => {});
      setPin(pin.slice(0, -1));
    }
  };

  const formatTime = (seconds: number) => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins}:${secs < 10 ? '0' : ''}${secs}`;
  };

  return (
    <Modal visible={visible} animationType="slide" transparent>
      <View style={styles.modalOverlay}>
        <View style={styles.modalContent}>
          
          {/* Header */}
          <View style={styles.header}>
            <Text style={styles.title}>{t('admin_panel', 'Admin Control')}</Text>
            <TouchableOpacity style={styles.closeButton} onPress={onClose}>
              <Feather name="x" size={24} color="#64748B" />
            </TouchableOpacity>
          </View>

          {/* Prompt */}
          <Text style={styles.subtitle}>
            {lockdownSec > 0 
              ? t('try_again_in', 'Try again in:') 
              : t('enter_pin', 'Enter 4-Digit Security PIN')}
          </Text>

          {/* Cooldown Display or Input Indicators */}
          {lockdownSec > 0 ? (
            <View style={styles.lockoutWrapper}>
              <Ionicons name="lock-closed" size={48} color="#FF5A5F" />
              <Text style={styles.lockoutTimer}>{formatTime(lockdownSec)}</Text>
            </View>
          ) : (
            <View style={styles.indicatorWrapper}>
              {[0, 1, 2, 3].map(index => (
                <View
                  key={index}
                  style={[
                    styles.dot,
                    pin.length > index ? styles.dotFilled : null,
                    errorMessage ? styles.dotError : null
                  ]}
                />
              ))}
            </View>
          )}

          {/* Error Message */}
          <Text style={[styles.errorText, errorMessage ? styles.errorTextVisible : null]}>
            {errorMessage}
          </Text>

          {/* Keypad */}
          <View style={styles.keypad}>
            {[
              ['1', '2', '3'],
              ['4', '5', '6'],
              ['7', '8', '9'],
              ['cancel', '0', 'delete']
            ].map((row, rowIndex) => (
              <View key={rowIndex} style={styles.keypadRow}>
                {row.map((key, keyIndex) => {
                  if (key === 'cancel') {
                    return (
                      <TouchableOpacity 
                        key={keyIndex} 
                        style={styles.keyButton} 
                        onPress={onClose}
                        disabled={lockdownSec > 0}
                      >
                        <Text style={styles.cancelText}>{t('cancel', 'Cancel')}</Text>
                      </TouchableOpacity>
                    );
                  }
                  if (key === 'delete') {
                    return (
                      <TouchableOpacity 
                        key={keyIndex} 
                        style={styles.keyButton} 
                        onPress={handleDelete}
                        disabled={lockdownSec > 0}
                      >
                        <Feather name="delete" size={22} color="#64748B" />
                      </TouchableOpacity>
                    );
                  }
                  return (
                    <TouchableOpacity
                      key={keyIndex}
                      style={[styles.keyButton, styles.numButton]}
                      onPress={() => handleKeyPress(key)}
                      disabled={lockdownSec > 0}
                    >
                      <Text style={styles.numText}>{key}</Text>
                    </TouchableOpacity>
                  );
                })}
              </View>
            ))}
          </View>

        </View>
      </View>
    </Modal>
  );
}

const styles = StyleSheet.create({
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(15, 23, 42, 0.75)',
    justifyContent: 'flex-end',
  },
  modalContent: {
    backgroundColor: '#FFFFFF',
    borderTopLeftRadius: 32,
    borderTopRightRadius: 32,
    padding: 24,
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: -10 },
    shadowOpacity: 0.1,
    shadowRadius: 20,
    elevation: 10,
  },
  header: {
    width: '100%',
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 20,
  },
  title: {
    fontSize: 20,
    fontWeight: 'bold',
    color: '#1E293B',
  },
  closeButton: {
    padding: 4,
  },
  subtitle: {
    fontSize: 15,
    fontWeight: '600',
    color: '#64748B',
    marginBottom: 24,
  },
  indicatorWrapper: {
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 16,
    height: 48,
  },
  dot: {
    width: 16,
    height: 16,
    borderRadius: 8,
    borderWidth: 2,
    borderColor: '#CBD5E1',
    marginHorizontal: 12,
    backgroundColor: 'transparent',
  },
  dotFilled: {
    backgroundColor: '#00A896',
    borderColor: '#00A896',
  },
  dotError: {
    borderColor: '#FF5A5F',
  },
  lockoutWrapper: {
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 16,
    height: 90,
  },
  lockoutTimer: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#FF5A5F',
    marginTop: 8,
  },
  errorText: {
    fontSize: 14,
    fontWeight: '600',
    color: '#FF5A5F',
    marginBottom: 24,
    height: 20,
    textAlign: 'center',
    opacity: 0,
  },
  errorTextVisible: {
    opacity: 1,
  },
  keypad: {
    width: '100%',
    paddingHorizontal: 20,
    marginBottom: 10,
  },
  keypadRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 16,
  },
  keyButton: {
    width: 70,
    height: 70,
    borderRadius: 35,
    justifyContent: 'center',
    alignItems: 'center',
  },
  numButton: {
    backgroundColor: '#F8FAFC',
    borderWidth: 1,
    borderColor: '#F1F5F9',
  },
  numText: {
    fontSize: 26,
    fontWeight: '700',
    color: '#1E293B',
  },
  cancelText: {
    fontSize: 14,
    fontWeight: 'bold',
    color: '#FF5A5F',
  },
});
