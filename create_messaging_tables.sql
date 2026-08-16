-- Script pour créer les tables de messagerie et d'abonnements
-- SANS affecter les tables existantes

-- 1. Table pour les abonnements des clients aux e-commerçants
CREATE TABLE IF NOT EXISTS customer_subscriptions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    customer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    merchant_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(customer_id, merchant_id)
);

-- 2. Table pour les plans des e-commerçants (abonnement plus)
CREATE TABLE IF NOT EXISTS merchant_plans (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    merchant_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    plan_type VARCHAR(50) NOT NULL DEFAULT 'basic', -- 'basic' ou 'plus'
    is_plus BOOLEAN DEFAULT FALSE,
    price DECIMAL(10,2) DEFAULT 0.00,
    start_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    end_date TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(merchant_id)
);

-- 3. Table pour les conversations
CREATE TABLE IF NOT EXISTS conversations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    customer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    merchant_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    last_message_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_message_content TEXT,
    customer_unread_count INTEGER DEFAULT 0,
    merchant_unread_count INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(customer_id, merchant_id)
);

-- 4. Table pour les messages
CREATE TABLE IF NOT EXISTS messages (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    receiver_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    message_type VARCHAR(20) DEFAULT 'text', -- 'text', 'image', 'file'
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. Table pour les notifications push
CREATE TABLE IF NOT EXISTS push_notifications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    body TEXT NOT NULL,
    type VARCHAR(50) DEFAULT 'message', -- 'message', 'story', 'order'
    data JSONB,
    is_read BOOLEAN DEFAULT FALSE,
    sent_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    read_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. Ajouter une colonne pour l'abonnement plus dans la table merchants existante
ALTER TABLE merchants ADD COLUMN IF NOT EXISTS has_plus_subscription BOOLEAN DEFAULT FALSE;
ALTER TABLE merchants ADD COLUMN IF NOT EXISTS plus_subscription_expires_at TIMESTAMP WITH TIME ZONE;

-- 7. Créer les index pour optimiser les performances
CREATE INDEX IF NOT EXISTS idx_customer_subscriptions_customer_id ON customer_subscriptions(customer_id);
CREATE INDEX IF NOT EXISTS idx_customer_subscriptions_merchant_id ON customer_subscriptions(merchant_id);
CREATE INDEX IF NOT EXISTS idx_merchant_plans_merchant_id ON merchant_plans(merchant_id);
CREATE INDEX IF NOT EXISTS idx_merchant_plans_is_plus ON merchant_plans(is_plus);
CREATE INDEX IF NOT EXISTS idx_conversations_customer_id ON conversations(customer_id);
CREATE INDEX IF NOT EXISTS idx_conversations_merchant_id ON conversations(merchant_id);
CREATE INDEX IF NOT EXISTS idx_messages_conversation_id ON messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender_id ON messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_receiver_id ON messages(receiver_id);
CREATE INDEX IF NOT EXISTS idx_push_notifications_user_id ON push_notifications(user_id);

-- 8. Activer RLS (Row Level Security) pour les nouvelles tables
ALTER TABLE customer_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE merchant_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE push_notifications ENABLE ROW LEVEL SECURITY;

-- 9. Créer les politiques RLS
-- Politiques pour customer_subscriptions
CREATE POLICY "Users can view their own subscriptions" ON customer_subscriptions
    FOR SELECT USING (customer_id = auth.uid() OR merchant_id = auth.uid());

CREATE POLICY "Users can create subscriptions" ON customer_subscriptions
    FOR INSERT WITH CHECK (customer_id = auth.uid());

-- Politiques pour merchant_plans
CREATE POLICY "Merchants can view their own plans" ON merchant_plans
    FOR SELECT USING (merchant_id = auth.uid());

CREATE POLICY "Merchants can update their own plans" ON merchant_plans
    FOR UPDATE USING (merchant_id = auth.uid());

-- Politiques pour conversations
CREATE POLICY "Users can view their own conversations" ON conversations
    FOR SELECT USING (customer_id = auth.uid() OR merchant_id = auth.uid());

CREATE POLICY "Users can create conversations" ON conversations
    FOR INSERT WITH CHECK (customer_id = auth.uid() OR merchant_id = auth.uid());

-- Politiques pour messages
CREATE POLICY "Users can view messages in their conversations" ON messages
    FOR SELECT USING (
        conversation_id IN (
            SELECT id FROM conversations 
            WHERE customer_id = auth.uid() OR merchant_id = auth.uid()
        )
    );

CREATE POLICY "Users can send messages" ON messages
    FOR INSERT WITH CHECK (sender_id = auth.uid());

-- Politiques pour push_notifications
CREATE POLICY "Users can view their own notifications" ON push_notifications
    FOR SELECT USING (user_id = auth.uid());

-- 10. Créer des fonctions utiles
CREATE OR REPLACE FUNCTION update_conversation_last_message()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE conversations 
    SET 
        last_message_at = NEW.created_at,
        last_message_content = NEW.content,
        updated_at = NOW()
    WHERE id = NEW.conversation_id;
    
    -- Mettre à jour le compteur de messages non lus
    IF NEW.sender_id != (SELECT customer_id FROM conversations WHERE id = NEW.conversation_id) THEN
        UPDATE conversations 
        SET customer_unread_count = customer_unread_count + 1
        WHERE id = NEW.conversation_id;
    ELSE
        UPDATE conversations 
        SET merchant_unread_count = merchant_unread_count + 1
        WHERE id = NEW.conversation_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 11. Créer le trigger pour mettre à jour les conversations
CREATE TRIGGER trigger_update_conversation_last_message
    AFTER INSERT ON messages
    FOR EACH ROW
    EXECUTE FUNCTION update_conversation_last_message();

-- 12. Vérifier que les tables ont été créées
SELECT 'Tables créées avec succès' as status;
