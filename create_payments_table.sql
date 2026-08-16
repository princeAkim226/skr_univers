-- Script pour créer la table des paiements
-- Exécuter dans l'éditeur SQL de Supabase

-- 1. Créer la table des paiements
CREATE TABLE IF NOT EXISTS payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
  amount DECIMAL(10,2) NOT NULL,
  payment_method VARCHAR(50) NOT NULL, -- 'mobile_money', 'card', 'cash'
  phone_number VARCHAR(20), -- Pour Mobile Money
  card_last_four VARCHAR(4), -- Pour les cartes bancaires
  status VARCHAR(50) DEFAULT 'pending', -- 'pending', 'completed', 'failed', 'refunded'
  transaction_id VARCHAR(255), -- ID de transaction externe
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Créer des index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_payments_order_id ON payments(order_id);
CREATE INDEX IF NOT EXISTS idx_payments_status ON payments(status);
CREATE INDEX IF NOT EXISTS idx_payments_created_at ON payments(created_at);

-- 3. Activer RLS sur la table payments
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;

-- 4. Créer les politiques RLS pour les paiements
CREATE POLICY "Customers can view their own payments" ON payments
    FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM orders 
            WHERE orders.id = payments.order_id 
            AND orders.customer_id IN (
                SELECT id FROM customers WHERE user_id = auth.uid()
            )
        )
    );

CREATE POLICY "Merchants can view payments for their orders" ON payments
    FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM orders 
            WHERE orders.id = payments.order_id 
            AND orders.merchant_id IN (
                SELECT id FROM merchants WHERE user_id = auth.uid()
            )
        )
    );

-- 5. Créer un trigger pour mettre à jour updated_at
CREATE TRIGGER update_payments_updated_at BEFORE UPDATE ON payments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 6. Vérifier la structure de la table
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'payments' 
ORDER BY ordinal_position;
