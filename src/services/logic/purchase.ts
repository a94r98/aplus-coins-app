import { DatabaseAPI, Product, Purchase, WalletTransaction } from '../api';

export interface PurchaseResult {
  success: boolean;
  error?: 'insufficient_coins' | 'out_of_stock' | 'product_not_found' | 'transaction_failed';
  deliveryCode?: string;
  newCoinsBalance?: number;
}

// Generate a random uppercase alphanumeric delivery code: XXXX-XXXX-XXXX
function generateDeliveryCode(): string {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  const segment = () => Array.from({ length: 4 }, () => chars[Math.floor(Math.random() * chars.length)]).join('');
  return `STORE-${segment()}-${segment()}`;
}

export const PurchaseEngine = {
  /**
   * Safe server-side simulated transaction for purchasing a product.
   * Runs in the API/Logic layer, protecting against tampering.
   */
  executePurchase: async (productId: string): Promise<PurchaseResult> => {
    try {
      // 1. Fetch latest data (Simulates locking the database tables)
      const products = await DatabaseAPI.getProducts();
      const productIndex = products.findIndex(p => p.id === productId);
      
      if (productIndex === -1) {
        return { success: false, error: 'product_not_found' };
      }

      const product = products[productIndex];

      // 2. Validate stock
      if (product.stock <= 0) {
        return { success: false, error: 'out_of_stock' };
      }

      // 3. Validate user balance
      const currentCoins = await DatabaseAPI.getUserCoins();
      if (currentCoins < product.price_coins) {
        return { success: false, error: 'insufficient_coins' };
      }

      // -------------------------------------------------------------
      // BEGIN TRANSACTION SIMULATION
      // -------------------------------------------------------------
      
      // A. Calculate new values
      const updatedProduct: Product = {
        ...product,
        stock: product.stock - 1
      };

      // B. Save updated product stock
      await DatabaseAPI.updateProduct(updatedProduct);

      // C. Generate purchase IDs & snapshot USD values
      const purchaseId = Math.random().toString(36).substring(2, 11);
      const walletSettings = await DatabaseAPI.getWalletSettings();
      const usdVal = product.price_coins / walletSettings.exchange_rate;

      // Generate sequence number
      const ledgerTxs = await DatabaseAPI.getWalletTransactions();
      const lastSeq = ledgerTxs.length > 0 ? Math.max(...ledgerTxs.map(t => t.sequence_number || 0)) : 0;
      const nextSeq = lastSeq + 1;

      // D. Log SPEND Ledger Transaction (Idempotent and Immutable)
      const spendTx: WalletTransaction = {
        id: 'tx_' + Math.random().toString(36).substring(2, 11),
        user_id: 'u1', // Ahmed
        type: 'SPEND',
        coins: -product.price_coins, // debit is signed negative
        usd_snapshot: -usdVal, // USD snapshot negative
        reference_id: purchaseId,
        idempotency_key: `purchase_${purchaseId}`,
        sequence_number: nextSeq,
        created_at: new Date().toISOString()
      };

      await DatabaseAPI.saveWalletTransaction(spendTx);

      // E. Rebuild Cache balance atomicity
      const newCoinsBalance = await DatabaseAPI.rebuildUserBalanceFromLedger('u1');

      // F. Generate delivery code
      const deliveryCode = generateDeliveryCode();

      // G. Create purchase record
      const newPurchase: Purchase = {
        id: purchaseId,
        product_id: productId,
        price_coins: product.price_coins,
        status: 'delivered',
        delivery_code: deliveryCode,
        created_at: new Date().toISOString()
      };
      await DatabaseAPI.savePurchase(newPurchase);

      // H. Send notification
      await DatabaseAPI.sendNotification('u1', {
        title_ar: 'شراء ناجح',
        title_en: 'Purchase Successful',
        message_ar: `لقد اشتريت "${product.title_ar}" بنجاح مقابل ${product.price_coins} عملة. كود الاستلام: ${deliveryCode}`,
        message_en: `You have successfully purchased "${product.title_en}" for ${product.price_coins} coins. Delivery code: ${deliveryCode}`,
        type: 'SPEND'
      });

      // F. Log admin/audit event
      await DatabaseAPI.logAdminAction(
        `User purchased: "${product.title_en}" for ${product.price_coins} Coins. Code generated.`
      );

      // -------------------------------------------------------------
      // COMMIT TRANSACTION
      // -------------------------------------------------------------
      return {
        success: true,
        deliveryCode,
        newCoinsBalance
      };

    } catch (error) {
      console.error('Transaction execution failed:', error);
      return { success: false, error: 'transaction_failed' };
    }
  }
};
