import React, { useState, useEffect } from 'react';
import {
  StyleSheet,
  Text,
  View,
  Image,
  TouchableOpacity,
  ScrollView,
  FlatList,
  Modal,
  Dimensions,
  ActivityIndicator,
  Clipboard,
  Alert,
  ViewStyle,
  TextStyle
} from 'react-native';
import { useTranslation } from 'react-i18next';
import { LinearGradient } from 'expo-linear-gradient';
import { Ionicons, Feather, MaterialCommunityIcons } from '@expo/vector-icons';
import { useApp } from '../services/store';
import { Category, Product } from '../services/api';

const { width } = Dimensions.get('window');

export default function StoreScreen() {
  const { t, i18n } = useTranslation();
  const isRTL = i18n.language === 'ar';
  const { userCoins, categories, products, buyProduct, isLoading } = useApp();

  const [selectedCategoryId, setSelectedCategoryId] = useState<string | null>(null);
  const [purchaseModalVisible, setPurchaseModalVisible] = useState<boolean>(false);
  const [successModalVisible, setSuccessModalVisible] = useState<boolean>(false);
  const [selectedProduct, setSelectedProduct] = useState<Product | null>(null);
  
  const [purchasing, setPurchasing] = useState<boolean>(false);
  const [generatedCode, setGeneratedCode] = useState<string>('');

  // Styles helpers
  const rowStyle: ViewStyle = { flexDirection: isRTL ? 'row-reverse' : 'row' };
  const textAlignStyle: TextStyle = { textAlign: isRTL ? 'right' : 'left' };
  const marginStartStyle = (val: number) => isRTL ? { marginRight: val } : { marginLeft: val };
  const marginEndStyle = (val: number) => isRTL ? { marginLeft: val } : { marginRight: val };

  // Filter products
  const filteredProducts = selectedCategoryId
    ? products.filter(p => p.category_id === selectedCategoryId && p.active)
    : products.filter(p => p.active);

  const handlePurchaseInit = (product: Product) => {
    if (product.stock <= 0) return;
    
    // Check VIP warning (in a real app check if user has VIP role, here warn if vip only)
    if (product.vip_only) {
      Alert.alert(
        t('vip_only_title', 'VIP Member Only'),
        t('vip_only_desc', 'This product is reserved for VIP members. Continue anyway?'),
        [
          { text: t('cancel', 'Cancel'), style: 'cancel' },
          { text: t('yes', 'Yes'), onPress: () => {
              setSelectedProduct(product);
              setPurchaseModalVisible(true);
            }
          }
        ]
      );
    } else {
      setSelectedProduct(product);
      setPurchaseModalVisible(true);
    }
  };

  const handleConfirmPurchase = async () => {
    if (!selectedProduct) return;

    setPurchasing(true);
    setPurchaseModalVisible(false);

    try {
      const result = await buyProduct(selectedProduct.id);
      if (result.success && result.deliveryCode) {
        setGeneratedCode(result.deliveryCode);
        setSuccessModalVisible(true);
      } else {
        if (result.error === 'insufficient_coins') {
          Alert.alert(t('error', 'Error'), t('insufficient_balance', 'Insufficient coins balance.'));
        } else if (result.error === 'out_of_stock') {
          Alert.alert(t('error', 'Error'), t('out_of_stock_alert', 'Product is out of stock.'));
        } else {
          Alert.alert(t('error', 'Error'), t('purchase_failed', 'Purchase failed. Try again.'));
        }
      }
    } catch (e) {
      Alert.alert(t('error', 'Error'), t('purchase_failed', 'Purchase failed.'));
    } finally {
      setPurchasing(false);
      setSelectedProduct(null);
    }
  };

  const copyToClipboard = () => {
    Clipboard.setString(generatedCode);
    Alert.alert(t('copied', 'Copied'), t('code_copied_success', 'Delivery code copied to clipboard!'));
  };

  // Render Skeleton Loader for Products
  const renderSkeletons = () => {
    return (
      <View style={styles.skeletonContainer}>
        {[1, 2, 3, 4].map(idx => (
          <View key={idx} style={styles.skeletonCard}>
            <View style={styles.skeletonImage} />
            <View style={styles.skeletonTitle} />
            <View style={styles.skeletonPrice} />
            <View style={styles.skeletonBtn} />
          </View>
        ))}
      </View>
    );
  };

  return (
    <View style={styles.container}>
      
      {/* Header Banner */}
      <LinearGradient
        colors={['#00B4DB', '#0083B0']}
        start={{ x: 0, y: 0 }}
        end={{ x: 1, y: 1 }}
        style={styles.headerBanner}
      >
        <View style={[styles.headerContent, rowStyle]}>
          <View>
            <Text style={styles.headerTitle}>{t('store', 'Store')}</Text>
            <View style={[styles.balanceRow, rowStyle]}>
              <Text style={styles.balanceVal}>{userCoins.toLocaleString()}</Text>
              <Text style={[styles.balanceLbl, marginStartStyle(6)]}>{t('coins', 'Coins')}</Text>
            </View>
          </View>
          <TouchableOpacity style={[styles.walletBtn, rowStyle]}>
            <Ionicons name="wallet-outline" size={16} color="#FFFFFF" style={marginEndStyle(6)} />
            <Text style={styles.walletBtnText}>{t('my_wallet', 'My Wallet')}</Text>
          </TouchableOpacity>
        </View>
      </LinearGradient>

      {/* Categories Scroller */}
      <View style={styles.categoriesContainer}>
        {isLoading && categories.length === 0 ? (
          <View style={styles.skeletonCategories}>
            {[1, 2, 3].map(idx => (
              <View key={idx} style={styles.skeletonCatItem} />
            ))}
          </View>
        ) : (
          <ScrollView
            horizontal
            showsHorizontalScrollIndicator={false}
            contentContainerStyle={[styles.categoriesScroll, rowStyle]}
          >
            {/* "All" Category */}
            <TouchableOpacity
              style={[
                styles.categoryItem,
                selectedCategoryId === null ? styles.categoryItemActive : null,
                rowStyle
              ]}
              onPress={() => setSelectedCategoryId(null)}
            >
              <MaterialCommunityIcons 
                name="apps" 
                size={18} 
                color={selectedCategoryId === null ? '#FFFFFF' : '#00A896'} 
                style={marginEndStyle(6)}
              />
              <Text style={[styles.categoryText, selectedCategoryId === null ? styles.categoryTextActive : null]}>
                {t('all_categories', 'All')}
              </Text>
            </TouchableOpacity>

            {/* Dynamic Categories */}
            {categories.filter(c => c.active).map(cat => (
              <TouchableOpacity
                key={cat.id}
                style={[
                  styles.categoryItem,
                  selectedCategoryId === cat.id ? styles.categoryItemActive : null,
                  rowStyle
                ]}
                onPress={() => setSelectedCategoryId(cat.id)}
              >
                <Ionicons 
                  name={cat.icon as any} 
                  size={18} 
                  color={selectedCategoryId === cat.id ? '#FFFFFF' : cat.color || '#00A896'} 
                  style={marginEndStyle(6)}
                />
                <Text style={[styles.categoryText, selectedCategoryId === cat.id ? styles.categoryTextActive : null]}>
                  {isRTL ? cat.name_ar : cat.name_en}
                </Text>
              </TouchableOpacity>
            ))}
          </ScrollView>
        )}
      </View>

      {/* Products Display */}
      {isLoading ? (
        renderSkeletons()
      ) : (
        <FlatList
          data={filteredProducts}
          keyExtractor={(item) => item.id}
          numColumns={2}
          columnWrapperStyle={[styles.productsRow, rowStyle]}
          contentContainerStyle={styles.productsScroll}
          showsVerticalScrollIndicator={false}
          ListEmptyComponent={
            <View style={styles.emptyWrapper}>
              <Feather name="shopping-bag" size={48} color="#94A3B8" />
              <Text style={styles.emptyText}>{t('no_products', 'No products available.')}</Text>
            </View>
          }
          renderItem={({ item }) => {
            const isOutOfStock = item.stock <= 0;
            return (
              <View style={[styles.productCard, isOutOfStock ? styles.productCardOOS : null]}>
                
                {/* Badges (VIP / Out of stock) */}
                {item.vip_only && (
                  <View style={styles.vipBadge}>
                    <Text style={styles.vipBadgeText}>VIP</Text>
                  </View>
                )}

                {isOutOfStock && (
                  <View style={styles.oosBadge}>
                    <Text style={styles.oosBadgeText}>{t('out_of_stock', 'Out of Stock')}</Text>
                  </View>
                )}

                {/* Product Image */}
                <Image source={{ uri: item.image }} style={styles.productImage} />
                
                {/* Product Info */}
                <View style={styles.productInfo}>
                  <Text style={[styles.productTitle, textAlignStyle]} numberOfLines={1}>
                    {isRTL ? item.title_ar : item.title_en}
                  </Text>
                  <Text style={[styles.productDesc, textAlignStyle]} numberOfLines={2}>
                    {isRTL ? item.description_ar : item.description_en}
                  </Text>
                  
                  {/* Price Row */}
                  <View style={[styles.priceRow, rowStyle]}>
                    <Text style={styles.priceVal}>{item.price_coins.toLocaleString()}</Text>
                    <Image source={require('../../assets/coins_stack_3d.png')} style={styles.coinIcon} />
                  </View>

                  {/* Buy Button */}
                  <TouchableOpacity
                    style={[
                      styles.buyBtn,
                      isOutOfStock ? styles.buyBtnDisabled : null,
                      item.vip_only ? styles.buyBtnVip : null
                    ]}
                    onPress={() => handlePurchaseInit(item)}
                    disabled={isOutOfStock}
                  >
                    <Text style={styles.buyBtnText}>
                      {isOutOfStock ? t('out_of_stock', 'OOS') : t('buy', 'Buy')}
                    </Text>
                  </TouchableOpacity>
                </View>
              </View>
            );
          }}
        />
      )}

      {/* Loading Overlay */}
      {purchasing && (
        <View style={styles.loadingOverlay}>
          <ActivityIndicator size="large" color="#00A896" />
          <Text style={styles.loadingText}>{t('processing_purchase', 'Processing Transaction...')}</Text>
        </View>
      )}

      {/* Confirmation Modal */}
      <Modal visible={purchaseModalVisible} transparent animationType="fade">
        <View style={styles.modalOverlay}>
          <View style={styles.modalCard}>
            <Text style={styles.modalTitle}>{t('confirm_title', 'Confirm Purchase')}</Text>
            {selectedProduct && (
              <View style={styles.confirmDetails}>
                <Text style={styles.confirmText}>
                  {t('confirm_prompt', 'Are you sure you want to purchase:')}
                </Text>
                <Text style={styles.confirmProdName}>
                  {isRTL ? selectedProduct.title_ar : selectedProduct.title_en}
                </Text>
                <View style={[styles.confirmPriceRow, rowStyle]}>
                  <Text style={styles.confirmPrice}>{selectedProduct.price_coins.toLocaleString()}</Text>
                  <Image source={require('../../assets/coins_stack_3d.png')} style={styles.smallCoin} />
                </View>
              </View>
            )}
            
            <View style={styles.modalActionRow}>
              <TouchableOpacity
                style={[styles.modalBtn, styles.modalBtnCancel]}
                onPress={() => {
                  setPurchaseModalVisible(false);
                  setSelectedProduct(null);
                }}
              >
                <Text style={styles.modalBtnCancelText}>{t('cancel', 'Cancel')}</Text>
              </TouchableOpacity>

              <TouchableOpacity
                style={[styles.modalBtn, styles.modalBtnConfirm]}
                onPress={handleConfirmPurchase}
              >
                <Text style={styles.modalBtnConfirmText}>{t('confirm', 'Confirm')}</Text>
              </TouchableOpacity>
            </View>
          </View>
        </View>
      </Modal>

      {/* Success Modal */}
      <Modal visible={successModalVisible} transparent animationType="slide">
        <View style={styles.modalOverlay}>
          <View style={styles.successCard}>
            <View style={styles.successIconWrapper}>
              <Feather name="check-circle" size={48} color="#FFFFFF" />
            </View>
            
            <Text style={styles.successTitle}>{t('purchase_success_title', 'Purchase Completed!')}</Text>
            <Text style={styles.successSubtitle}>
              {t('purchase_success_desc', 'Use the code below to load your account:')}
            </Text>

            {/* Code Display Box */}
            <View style={styles.codeBox}>
              <Text style={styles.codeText}>{generatedCode}</Text>
              <TouchableOpacity onPress={copyToClipboard} style={styles.copyBtn}>
                <Feather name="copy" size={20} color="#00A896" />
              </TouchableOpacity>
            </View>

            <TouchableOpacity
              style={styles.closeSuccessBtn}
              onPress={() => {
                setSuccessModalVisible(false);
                setGeneratedCode('');
              }}
            >
              <Text style={styles.closeSuccessBtnText}>{t('done', 'Done')}</Text>
            </TouchableOpacity>
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
  headerBanner: {
    paddingTop: 50,
    paddingBottom: 24,
    paddingHorizontal: 20,
    borderBottomLeftRadius: 28,
    borderBottomRightRadius: 28,
  },
  headerContent: {
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  headerTitle: {
    fontSize: 22,
    fontWeight: 'bold',
    color: '#FFFFFF',
    marginBottom: 4,
  },
  balanceRow: {
    alignItems: 'center',
  },
  balanceVal: {
    fontSize: 26,
    fontWeight: '900',
    color: '#FFFFFF',
  },
  balanceLbl: {
    fontSize: 14,
    color: 'rgba(255, 255, 255, 0.85)',
    fontWeight: '600',
  },
  walletBtn: {
    backgroundColor: 'rgba(255, 255, 255, 0.2)',
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.3)',
    paddingVertical: 8,
    paddingHorizontal: 16,
    borderRadius: 16,
    alignItems: 'center',
    justifyContent: 'center',
  },
  walletBtnText: {
    fontSize: 13,
    color: '#FFFFFF',
    fontWeight: '700',
  },
  categoriesContainer: {
    marginTop: 16,
    marginBottom: 8,
  },
  categoriesScroll: {
    paddingHorizontal: 16,
  },
  categoryItem: {
    backgroundColor: '#FFFFFF',
    paddingVertical: 10,
    paddingHorizontal: 16,
    borderRadius: 20,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    alignItems: 'center',
    marginHorizontal: 4,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.02,
    shadowRadius: 6,
    elevation: 1.5,
  },
  categoryItemActive: {
    backgroundColor: '#00A896',
    borderColor: '#00A896',
  },
  categoryText: {
    fontSize: 13,
    fontWeight: '600',
    color: '#64748B',
  },
  categoryTextActive: {
    color: '#FFFFFF',
  },
  productsScroll: {
    paddingHorizontal: 12,
    paddingTop: 8,
    paddingBottom: 100,
  },
  productsRow: {
    justifyContent: 'space-between',
    marginBottom: 12,
  },
  productCard: {
    width: (width - 36) / 2,
    backgroundColor: '#FFFFFF',
    borderRadius: 24,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    padding: 12,
    position: 'relative',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.02,
    shadowRadius: 8,
    elevation: 2,
  },
  productCardOOS: {
    opacity: 0.7,
  },
  vipBadge: {
    position: 'absolute',
    top: 10,
    right: 10,
    backgroundColor: '#FFD700',
    paddingVertical: 4,
    paddingHorizontal: 8,
    borderRadius: 10,
    zIndex: 1,
  },
  vipBadgeText: {
    fontSize: 10,
    fontWeight: 'bold',
    color: '#1E293B',
  },
  oosBadge: {
    position: 'absolute',
    top: '30%',
    left: 10,
    right: 10,
    backgroundColor: 'rgba(255, 90, 95, 0.9)',
    paddingVertical: 6,
    borderRadius: 12,
    zIndex: 2,
    alignItems: 'center',
  },
  oosBadgeText: {
    fontSize: 11,
    fontWeight: 'bold',
    color: '#FFFFFF',
  },
  productImage: {
    width: '100%',
    height: 100,
    borderRadius: 16,
    resizeMode: 'cover',
    marginBottom: 8,
  },
  productInfo: {
    flex: 1,
  },
  productTitle: {
    fontSize: 13,
    fontWeight: 'bold',
    color: '#1E293B',
    marginBottom: 4,
  },
  productDesc: {
    fontSize: 10,
    color: '#64748B',
    height: 28,
    lineHeight: 14,
    marginBottom: 8,
  },
  priceRow: {
    alignItems: 'center',
    marginBottom: 8,
  },
  priceVal: {
    fontSize: 15,
    fontWeight: 'bold',
    color: '#00A896',
  },
  coinIcon: {
    width: 14,
    height: 14,
    resizeMode: 'contain',
    marginLeft: 3,
  },
  buyBtn: {
    backgroundColor: '#FFFFFF',
    borderWidth: 1.5,
    borderColor: '#00A896',
    borderRadius: 14,
    paddingVertical: 8,
    alignItems: 'center',
  },
  buyBtnDisabled: {
    borderColor: '#CBD5E1',
    backgroundColor: '#F1F5F9',
  },
  buyBtnVip: {
    borderColor: '#D4AF37',
  },
  buyBtnText: {
    fontSize: 12,
    fontWeight: 'bold',
    color: '#00A896',
  },
  emptyWrapper: {
    alignItems: 'center',
    paddingVertical: 60,
  },
  emptyText: {
    fontSize: 14,
    color: '#94A3B8',
    marginTop: 12,
  },
  loadingOverlay: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    backgroundColor: 'rgba(255, 255, 255, 0.8)',
    justifyContent: 'center',
    alignItems: 'center',
    zIndex: 10,
  },
  loadingText: {
    marginTop: 12,
    fontSize: 14,
    fontWeight: '600',
    color: '#00A896',
  },
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(15, 23, 42, 0.6)',
    justifyContent: 'center',
    alignItems: 'center',
    padding: 24,
  },
  modalCard: {
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
  modalTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#1E293B',
    marginBottom: 16,
    textAlign: 'center',
  },
  confirmDetails: {
    backgroundColor: '#F8FAFC',
    borderRadius: 18,
    padding: 16,
    alignItems: 'center',
    marginBottom: 20,
  },
  confirmText: {
    fontSize: 13,
    color: '#64748B',
    marginBottom: 8,
  },
  confirmProdName: {
    fontSize: 16,
    fontWeight: 'bold',
    color: '#1E293B',
    textAlign: 'center',
    marginBottom: 8,
  },
  confirmPriceRow: {
    alignItems: 'center',
  },
  confirmPrice: {
    fontSize: 20,
    fontWeight: '900',
    color: '#00A896',
  },
  smallCoin: {
    width: 18,
    height: 18,
    resizeMode: 'contain',
    marginLeft: 4,
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
  modalBtnConfirm: {
    backgroundColor: '#00A896',
    marginLeft: 8,
  },
  modalBtnConfirmText: {
    fontSize: 14,
    color: '#FFFFFF',
    fontWeight: '700',
  },
  successCard: {
    width: '100%',
    backgroundColor: '#FFFFFF',
    borderRadius: 28,
    padding: 24,
    alignItems: 'center',
  },
  successIconWrapper: {
    width: 80,
    height: 80,
    borderRadius: 40,
    backgroundColor: '#00A896',
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 20,
    shadowColor: '#00A896',
    shadowOffset: { width: 0, height: 6 },
    shadowOpacity: 0.3,
    shadowRadius: 10,
  },
  successTitle: {
    fontSize: 20,
    fontWeight: 'bold',
    color: '#1E293B',
    marginBottom: 8,
  },
  successSubtitle: {
    fontSize: 13,
    color: '#64748B',
    textAlign: 'center',
    marginBottom: 24,
  },
  codeBox: {
    width: '100%',
    backgroundColor: '#E6F7F5',
    borderWidth: 1.5,
    borderColor: '#00A896',
    borderRadius: 16,
    paddingVertical: 16,
    paddingHorizontal: 20,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 24,
  },
  codeText: {
    fontSize: 18,
    fontWeight: '800',
    color: '#00A896',
    letterSpacing: 1,
  },
  copyBtn: {
    padding: 6,
  },
  closeSuccessBtn: {
    width: '100%',
    backgroundColor: '#1E293B',
    paddingVertical: 14,
    borderRadius: 16,
    alignItems: 'center',
  },
  closeSuccessBtnText: {
    fontSize: 14,
    color: '#FFFFFF',
    fontWeight: 'bold',
  },
  skeletonContainer: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    paddingHorizontal: 12,
    justifyContent: 'space-between',
  },
  skeletonCard: {
    width: (width - 36) / 2,
    backgroundColor: '#FFFFFF',
    borderRadius: 24,
    padding: 12,
    marginBottom: 12,
    borderWidth: 1,
    borderColor: '#F1F5F9',
  },
  skeletonImage: {
    width: '100%',
    height: 100,
    backgroundColor: '#E2E8F0',
    borderRadius: 16,
    marginBottom: 8,
  },
  skeletonTitle: {
    width: '60%',
    height: 14,
    backgroundColor: '#E2E8F0',
    borderRadius: 4,
    marginBottom: 6,
  },
  skeletonPrice: {
    width: '40%',
    height: 14,
    backgroundColor: '#E2E8F0',
    borderRadius: 4,
    marginBottom: 12,
  },
  skeletonBtn: {
    width: '100%',
    height: 28,
    backgroundColor: '#E2E8F0',
    borderRadius: 12,
  },
  skeletonCategories: {
    flexDirection: 'row',
    paddingHorizontal: 16,
  },
  skeletonCatItem: {
    width: 90,
    height: 36,
    borderRadius: 18,
    backgroundColor: '#E2E8F0',
    marginRight: 8,
  },
});
