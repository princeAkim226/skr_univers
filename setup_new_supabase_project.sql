-- ============================================================
-- RAAGA - Setup COMPLET projet Supabase VIDE
-- Projet: https://dmmtdmpcguybkshmdhzd.supabase.co
--
-- À exécuter dans: Dashboard Supabase > SQL Editor > New query
-- Puis: Run (une seule fois)
-- ============================================================

-- ============================================================
-- 1) USERS
-- ============================================================
CREATE TABLE IF NOT EXISTS public.users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT,
  first_name TEXT NOT NULL DEFAULT '',
  last_name TEXT NOT NULL DEFAULT '',
  phone_number TEXT,
  user_type TEXT NOT NULL CHECK (user_type IN ('customer', 'merchant')),
  profile_image TEXT,
  interests TEXT[] DEFAULT '{}',
  is_active BOOLEAN DEFAULT TRUE,
  is_admin BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  business_name TEXT,
  business_description TEXT,
  business_address TEXT,
  business_phone TEXT,
  business_email TEXT,
  is_verified BOOLEAN DEFAULT FALSE
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_users_single_admin
ON public.users ((is_admin))
WHERE is_admin = true;

CREATE INDEX IF NOT EXISTS idx_users_phone ON public.users(phone_number);
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);

-- ============================================================
-- 2) CUSTOMERS
-- ============================================================
CREATE TABLE IF NOT EXISTS public.customers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  email TEXT,
  phone VARCHAR(50),
  address TEXT,
  profile_image TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_customers_user_id ON public.customers(user_id);

-- ============================================================
-- 3) MERCHANTS
-- ============================================================
CREATE TABLE IF NOT EXISTS public.merchants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  business_name VARCHAR(255) NOT NULL,
  business_image TEXT,
  business_phone VARCHAR(50),
  business_address TEXT,
  business_description TEXT,
  business_email TEXT,
  business_city TEXT,
  business_country TEXT,
  id_card_front TEXT,
  id_card_back TEXT,
  id_card_type TEXT,
  id_card_upload_date TIMESTAMPTZ,
  id_card_status TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  is_verified BOOLEAN DEFAULT FALSE,
  has_plus_subscription BOOLEAN DEFAULT FALSE,
  plus_subscription_expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_merchants_user_id ON public.merchants(user_id);

-- ============================================================
-- 4) PRODUCTS
-- ============================================================
CREATE TABLE IF NOT EXISTS public.products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  merchant_id UUID NOT NULL REFERENCES public.merchants(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  price NUMERIC(12,2) NOT NULL DEFAULT 0,
  original_price NUMERIC(12,2),
  stock_quantity INTEGER NOT NULL DEFAULT 0,
  category TEXT,
  images TEXT[] DEFAULT '{}',
  tags TEXT[] DEFAULT '{}',
  address TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  property_type TEXT,
  property_rooms INTEGER,
  property_surface DOUBLE PRECISION,
  property_goal TEXT,
  property_city TEXT,
  property_zone TEXT,
  property_quarter TEXT,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  is_featured BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_products_merchant_id ON public.products(merchant_id);
CREATE INDEX IF NOT EXISTS idx_products_category ON public.products(category);
CREATE INDEX IF NOT EXISTS idx_products_active ON public.products(is_active);

-- ============================================================
-- 5) CART
-- ============================================================
CREATE TABLE IF NOT EXISTS public.cart_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID NOT NULL REFERENCES public.customers(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
  quantity INTEGER NOT NULL DEFAULT 1 CHECK (quantity > 0),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_cart_items_customer_product
ON public.cart_items(customer_id, product_id);

-- ============================================================
-- 6) ORDERS
-- ============================================================
CREATE TABLE IF NOT EXISTS public.orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID NOT NULL REFERENCES public.customers(id) ON DELETE CASCADE,
  merchant_id UUID REFERENCES public.merchants(id) ON DELETE SET NULL,
  total_amount NUMERIC(12,2) NOT NULL DEFAULT 0,
  subtotal_amount NUMERIC(12,2),
  discount_amount NUMERIC(12,2) DEFAULT 0,
  final_amount NUMERIC(12,2),
  promo_code_id UUID,
  status TEXT NOT NULL DEFAULT 'pending',
  shipping_address TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.order_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  product_id UUID REFERENCES public.products(id) ON DELETE SET NULL,
  quantity INTEGER NOT NULL DEFAULT 1,
  price NUMERIC(12,2) NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID REFERENCES public.orders(id) ON DELETE SET NULL,
  amount NUMERIC(12,2) NOT NULL DEFAULT 0,
  payment_method TEXT,
  phone_number TEXT,
  status TEXT DEFAULT 'pending',
  transaction_id TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 7) PROMO CODES
-- ============================================================
CREATE TABLE IF NOT EXISTS public.promo_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code TEXT NOT NULL UNIQUE,
  merchant_id UUID NOT NULL REFERENCES public.merchants(id) ON DELETE CASCADE,
  discount_type TEXT NOT NULL CHECK (discount_type IN ('percent', 'fixed')),
  discount_value NUMERIC(12,2) NOT NULL CHECK (discount_value > 0),
  min_order_amount NUMERIC(12,2) DEFAULT 0,
  max_discount_amount NUMERIC(12,2),
  starts_at TIMESTAMPTZ,
  ends_at TIMESTAMPTZ,
  usage_limit_total INTEGER,
  usage_limit_per_customer INTEGER,
  used_count INTEGER NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_by_admin_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.orders
  DROP CONSTRAINT IF EXISTS orders_promo_code_id_fkey;
ALTER TABLE public.orders
  ADD CONSTRAINT orders_promo_code_id_fkey
  FOREIGN KEY (promo_code_id) REFERENCES public.promo_codes(id) ON DELETE SET NULL;

CREATE TABLE IF NOT EXISTS public.promo_code_redemptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  promo_code_id UUID NOT NULL REFERENCES public.promo_codes(id) ON DELETE CASCADE,
  customer_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  order_id UUID REFERENCES public.orders(id) ON DELETE SET NULL,
  discount_amount NUMERIC(12,2) NOT NULL DEFAULT 0,
  redeemed_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_unique_redemption_by_order
ON public.promo_code_redemptions(promo_code_id, order_id)
WHERE order_id IS NOT NULL;

-- ============================================================
-- 8) MESSAGING
-- ============================================================
CREATE TABLE IF NOT EXISTS public.conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  merchant_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  last_message_at TIMESTAMPTZ DEFAULT NOW(),
  last_message_content TEXT,
  customer_unread_count INTEGER DEFAULT 0,
  merchant_unread_count INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(customer_id, merchant_id)
);

CREATE TABLE IF NOT EXISTS public.messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  receiver_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  message_type VARCHAR(20) DEFAULT 'text',
  is_read BOOLEAN DEFAULT FALSE,
  read_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_messages_conversation_id ON public.messages(conversation_id);

CREATE OR REPLACE VIEW public.messages_with_sender
WITH (security_invoker = true) AS
SELECT
  m.*,
  s.id AS sender_user_id,
  s.first_name AS sender_first_name,
  s.last_name AS sender_last_name,
  s.business_name AS sender_business_name,
  s.user_type AS sender_user_type,
  COALESCE(s.profile_image, mer.business_image, cust.profile_image) AS sender_profile_image
FROM public.messages m
JOIN public.users s ON m.sender_id = s.id
LEFT JOIN public.merchants mer ON mer.user_id = s.id
LEFT JOIN public.customers cust ON cust.user_id = s.id;

CREATE OR REPLACE VIEW public.customer_conversations
WITH (security_invoker = true) AS
SELECT
  c.*,
  u.id AS merchant_user_id,
  u.first_name AS merchant_first_name,
  u.last_name AS merchant_last_name,
  COALESCE(u.business_name, mer.business_name) AS business_name,
  COALESCE(u.business_description, mer.business_description) AS business_description,
  COALESCE(u.profile_image, mer.business_image) AS merchant_profile_image,
  COALESCE(u.phone_number, mer.business_phone) AS merchant_phone,
  mer.business_image
FROM public.conversations c
JOIN public.users u ON c.merchant_id = u.id
LEFT JOIN public.merchants mer ON mer.user_id = u.id;

CREATE OR REPLACE VIEW public.merchant_conversations
WITH (security_invoker = true) AS
SELECT
  c.*,
  u.id AS customer_user_id,
  u.first_name AS customer_first_name,
  u.last_name AS customer_last_name,
  COALESCE(u.profile_image, cust.profile_image) AS customer_profile_image,
  COALESCE(u.phone_number, cust.phone) AS customer_phone
FROM public.conversations c
JOIN public.users u ON c.customer_id = u.id
LEFT JOIN public.customers cust ON cust.user_id = u.id;

-- ============================================================
-- 9) STORIES + SUBSCRIPTIONS + ADS
-- ============================================================
CREATE TABLE IF NOT EXISTS public.stories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  merchant_id UUID NOT NULL REFERENCES public.merchants(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  images TEXT[] DEFAULT '{}',
  video_url TEXT,
  tags TEXT[] DEFAULT '{}',
  location TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  expires_at TIMESTAMPTZ NOT NULL,
  is_active BOOLEAN DEFAULT TRUE,
  view_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.customer_subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  merchant_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(customer_id, merchant_id)
);

CREATE TABLE IF NOT EXISTS public.merchant_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  merchant_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  plan_type VARCHAR(50) NOT NULL DEFAULT 'basic',
  is_plus BOOLEAN DEFAULT FALSE,
  price NUMERIC(10,2) DEFAULT 0,
  start_date TIMESTAMPTZ DEFAULT NOW(),
  end_date TIMESTAMPTZ,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(merchant_id)
);

CREATE TABLE IF NOT EXISTS public.ads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  merchant_id UUID NOT NULL REFERENCES public.merchants(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  image_url TEXT,
  target_url TEXT,
  start_date TIMESTAMPTZ DEFAULT NOW(),
  end_date TIMESTAMPTZ,
  is_active BOOLEAN DEFAULT TRUE,
  is_default BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.ad_subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  merchant_id UUID NOT NULL REFERENCES public.merchants(id) ON DELETE CASCADE,
  is_active BOOLEAN DEFAULT TRUE,
  start_date TIMESTAMPTZ DEFAULT NOW(),
  end_date TIMESTAMPTZ,
  price NUMERIC(12,2) DEFAULT 25000,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 10) RLS ENABLE
-- ============================================================
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.merchants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cart_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.promo_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.promo_code_redemptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.customer_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.merchant_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ads ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ad_subscriptions ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- 11) POLICIES USERS / CUSTOMERS / MERCHANTS
-- ============================================================
DROP POLICY IF EXISTS "Public can read users for login" ON public.users;
DROP POLICY IF EXISTS "Users manage own profile" ON public.users;
DROP POLICY IF EXISTS "Users insert own profile" ON public.users;
DROP POLICY IF EXISTS "Users update own profile" ON public.users;

CREATE POLICY "Public can read users for login"
ON public.users FOR SELECT TO anon, authenticated USING (true);

CREATE POLICY "Users insert own profile"
ON public.users FOR INSERT TO authenticated WITH CHECK (auth.uid() = id);

CREATE POLICY "Users update own profile"
ON public.users FOR UPDATE TO authenticated
USING (auth.uid() = id OR EXISTS (SELECT 1 FROM public.users u WHERE u.id = auth.uid() AND u.is_admin = true))
WITH CHECK (auth.uid() = id OR EXISTS (SELECT 1 FROM public.users u WHERE u.id = auth.uid() AND u.is_admin = true));

DROP POLICY IF EXISTS "Customers read own" ON public.customers;
DROP POLICY IF EXISTS "Customers insert own" ON public.customers;
DROP POLICY IF EXISTS "Customers update own" ON public.customers;
DROP POLICY IF EXISTS "Authenticated can read customers" ON public.customers;

CREATE POLICY "Authenticated can read customers"
ON public.customers FOR SELECT TO authenticated USING (true);

CREATE POLICY "Customers insert own"
ON public.customers FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Customers update own"
ON public.customers FOR UPDATE TO authenticated USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Authenticated can read merchants" ON public.merchants;
DROP POLICY IF EXISTS "Merchants insert own" ON public.merchants;
DROP POLICY IF EXISTS "Merchants update own" ON public.merchants;

CREATE POLICY "Authenticated can read merchants"
ON public.merchants FOR SELECT TO authenticated USING (true);

CREATE POLICY "Merchants insert own"
ON public.merchants FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Merchants update own"
ON public.merchants FOR UPDATE TO authenticated USING (auth.uid() = user_id);

-- ============================================================
-- 12) POLICIES PRODUCTS / CART / ORDERS
-- ============================================================
DROP POLICY IF EXISTS "Anyone can read active products" ON public.products;
DROP POLICY IF EXISTS "Merchants manage own products" ON public.products;

CREATE POLICY "Anyone can read active products"
ON public.products FOR SELECT TO anon, authenticated USING (is_active = true OR merchant_id IN (
  SELECT id FROM public.merchants WHERE user_id = auth.uid()
));

CREATE POLICY "Merchants manage own products"
ON public.products FOR ALL TO authenticated
USING (merchant_id IN (SELECT id FROM public.merchants WHERE user_id = auth.uid()))
WITH CHECK (merchant_id IN (SELECT id FROM public.merchants WHERE user_id = auth.uid()));

DROP POLICY IF EXISTS "Customers read own cart" ON public.cart_items;
DROP POLICY IF EXISTS "Customers insert own cart" ON public.cart_items;
DROP POLICY IF EXISTS "Customers update own cart" ON public.cart_items;
DROP POLICY IF EXISTS "Customers delete own cart" ON public.cart_items;

CREATE POLICY "Customers read own cart"
ON public.cart_items FOR SELECT TO authenticated
USING (customer_id IN (SELECT id FROM public.customers WHERE user_id = auth.uid()));

CREATE POLICY "Customers insert own cart"
ON public.cart_items FOR INSERT TO authenticated
WITH CHECK (customer_id IN (SELECT id FROM public.customers WHERE user_id = auth.uid()));

CREATE POLICY "Customers update own cart"
ON public.cart_items FOR UPDATE TO authenticated
USING (customer_id IN (SELECT id FROM public.customers WHERE user_id = auth.uid()));

CREATE POLICY "Customers delete own cart"
ON public.cart_items FOR DELETE TO authenticated
USING (customer_id IN (SELECT id FROM public.customers WHERE user_id = auth.uid()));

DROP POLICY IF EXISTS "Customers manage own orders" ON public.orders;
DROP POLICY IF EXISTS "Merchants read own orders" ON public.orders;
DROP POLICY IF EXISTS "Order items by participants" ON public.order_items;
DROP POLICY IF EXISTS "Payments by authenticated" ON public.payments;

CREATE POLICY "Customers manage own orders"
ON public.orders FOR ALL TO authenticated
USING (customer_id IN (SELECT id FROM public.customers WHERE user_id = auth.uid()))
WITH CHECK (customer_id IN (SELECT id FROM public.customers WHERE user_id = auth.uid()));

CREATE POLICY "Merchants read own orders"
ON public.orders FOR SELECT TO authenticated
USING (merchant_id IN (SELECT id FROM public.merchants WHERE user_id = auth.uid()));

CREATE POLICY "Order items by participants"
ON public.order_items FOR ALL TO authenticated
USING (
  order_id IN (
    SELECT o.id FROM public.orders o
    WHERE o.customer_id IN (SELECT id FROM public.customers WHERE user_id = auth.uid())
       OR o.merchant_id IN (SELECT id FROM public.merchants WHERE user_id = auth.uid())
  )
)
WITH CHECK (
  order_id IN (
    SELECT o.id FROM public.orders o
    WHERE o.customer_id IN (SELECT id FROM public.customers WHERE user_id = auth.uid())
  )
);

CREATE POLICY "Payments by authenticated"
ON public.payments FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- ============================================================
-- 13) POLICIES PROMO / MESSAGING / STORIES / ADS
-- ============================================================
DROP POLICY IF EXISTS "Promo codes readable" ON public.promo_codes;
DROP POLICY IF EXISTS "Admins manage promo codes" ON public.promo_codes;
DROP POLICY IF EXISTS "Users read own redemptions" ON public.promo_code_redemptions;
DROP POLICY IF EXISTS "Users insert own redemptions" ON public.promo_code_redemptions;

CREATE POLICY "Promo codes readable"
ON public.promo_codes FOR SELECT TO authenticated USING (true);

CREATE POLICY "Admins manage promo codes"
ON public.promo_codes FOR ALL TO authenticated
USING (EXISTS (SELECT 1 FROM public.users u WHERE u.id = auth.uid() AND u.is_admin = true))
WITH CHECK (EXISTS (SELECT 1 FROM public.users u WHERE u.id = auth.uid() AND u.is_admin = true));

CREATE POLICY "Users read own redemptions"
ON public.promo_code_redemptions FOR SELECT TO authenticated
USING (customer_user_id = auth.uid());

CREATE POLICY "Users insert own redemptions"
ON public.promo_code_redemptions FOR INSERT TO authenticated
WITH CHECK (customer_user_id = auth.uid());

DROP POLICY IF EXISTS "Participants manage conversations" ON public.conversations;
DROP POLICY IF EXISTS "Participants manage messages" ON public.messages;

CREATE POLICY "Participants manage conversations"
ON public.conversations FOR ALL TO authenticated
USING (customer_id = auth.uid() OR merchant_id = auth.uid())
WITH CHECK (customer_id = auth.uid() OR merchant_id = auth.uid());

CREATE POLICY "Participants manage messages"
ON public.messages FOR ALL TO authenticated
USING (sender_id = auth.uid() OR receiver_id = auth.uid())
WITH CHECK (sender_id = auth.uid() OR receiver_id = auth.uid());

DROP POLICY IF EXISTS "Stories viewable" ON public.stories;
DROP POLICY IF EXISTS "Merchants manage stories" ON public.stories;

CREATE POLICY "Stories viewable"
ON public.stories FOR SELECT TO anon, authenticated
USING (is_active = true AND expires_at > NOW());

CREATE POLICY "Merchants manage stories"
ON public.stories FOR ALL TO authenticated
USING (merchant_id IN (SELECT id FROM public.merchants WHERE user_id = auth.uid()))
WITH CHECK (merchant_id IN (SELECT id FROM public.merchants WHERE user_id = auth.uid()));

DROP POLICY IF EXISTS "Subscriptions manage own" ON public.customer_subscriptions;
DROP POLICY IF EXISTS "Plans readable" ON public.merchant_plans;
DROP POLICY IF EXISTS "Merchants manage plans" ON public.merchant_plans;
DROP POLICY IF EXISTS "Ads readable" ON public.ads;
DROP POLICY IF EXISTS "Merchants manage ads" ON public.ads;
DROP POLICY IF EXISTS "Ad subscriptions readable" ON public.ad_subscriptions;
DROP POLICY IF EXISTS "Merchants manage ad subscriptions" ON public.ad_subscriptions;

CREATE POLICY "Subscriptions manage own"
ON public.customer_subscriptions FOR ALL TO authenticated
USING (customer_id = auth.uid() OR merchant_id = auth.uid())
WITH CHECK (customer_id = auth.uid() OR merchant_id = auth.uid());

CREATE POLICY "Plans readable"
ON public.merchant_plans FOR SELECT TO authenticated USING (true);

CREATE POLICY "Merchants manage plans"
ON public.merchant_plans FOR ALL TO authenticated
USING (merchant_id = auth.uid())
WITH CHECK (merchant_id = auth.uid());

CREATE POLICY "Ads readable"
ON public.ads FOR SELECT TO anon, authenticated USING (is_active = true);

CREATE POLICY "Merchants manage ads"
ON public.ads FOR ALL TO authenticated
USING (merchant_id IN (SELECT id FROM public.merchants WHERE user_id = auth.uid()))
WITH CHECK (merchant_id IN (SELECT id FROM public.merchants WHERE user_id = auth.uid()));

CREATE POLICY "Ad subscriptions readable"
ON public.ad_subscriptions FOR SELECT TO authenticated USING (true);

CREATE POLICY "Merchants manage ad subscriptions"
ON public.ad_subscriptions FOR ALL TO authenticated
USING (merchant_id IN (SELECT id FROM public.merchants WHERE user_id = auth.uid()))
WITH CHECK (merchant_id IN (SELECT id FROM public.merchants WHERE user_id = auth.uid()));

-- ============================================================
-- 14) PROMO FUNCTIONS
-- ============================================================
CREATE OR REPLACE FUNCTION public.validate_promo_code(
  p_code TEXT,
  p_merchant_id UUID,
  p_order_amount NUMERIC
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_code RECORD;
  v_now TIMESTAMPTZ := NOW();
  v_user_id UUID := auth.uid();
  v_customer_used_count INTEGER := 0;
  v_discount NUMERIC := 0;
  v_final_total NUMERIC := p_order_amount;
BEGIN
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object('is_valid', false, 'message', 'Utilisateur non connecté');
  END IF;

  SELECT * INTO v_code
  FROM public.promo_codes
  WHERE UPPER(code) = UPPER(TRIM(p_code))
    AND merchant_id = p_merchant_id
  LIMIT 1;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('is_valid', false, 'message', 'Code promo invalide');
  END IF;

  IF NOT v_code.is_active THEN
    RETURN jsonb_build_object('is_valid', false, 'message', 'Code promo inactif');
  END IF;

  IF v_code.starts_at IS NOT NULL AND v_now < v_code.starts_at THEN
    RETURN jsonb_build_object('is_valid', false, 'message', 'Code promo pas encore actif');
  END IF;

  IF v_code.ends_at IS NOT NULL AND v_now > v_code.ends_at THEN
    RETURN jsonb_build_object('is_valid', false, 'message', 'Code promo expiré');
  END IF;

  IF v_code.usage_limit_total IS NOT NULL AND v_code.used_count >= v_code.usage_limit_total THEN
    RETURN jsonb_build_object('is_valid', false, 'message', 'Code promo épuisé');
  END IF;

  SELECT COUNT(*) INTO v_customer_used_count
  FROM public.promo_code_redemptions
  WHERE promo_code_id = v_code.id AND customer_user_id = v_user_id;

  IF v_code.usage_limit_per_customer IS NOT NULL
     AND v_customer_used_count >= v_code.usage_limit_per_customer THEN
    RETURN jsonb_build_object('is_valid', false, 'message', 'Limite d''utilisation atteinte');
  END IF;

  IF p_order_amount < COALESCE(v_code.min_order_amount, 0) THEN
    RETURN jsonb_build_object('is_valid', false, 'message', 'Montant minimum non atteint');
  END IF;

  IF v_code.discount_type = 'percent' THEN
    v_discount := (p_order_amount * v_code.discount_value) / 100.0;
  ELSE
    v_discount := v_code.discount_value;
  END IF;

  IF v_code.max_discount_amount IS NOT NULL THEN
    v_discount := LEAST(v_discount, v_code.max_discount_amount);
  END IF;

  v_discount := LEAST(v_discount, p_order_amount);
  v_final_total := GREATEST(p_order_amount - v_discount, 0);

  RETURN jsonb_build_object(
    'is_valid', true,
    'message', 'Code promo appliqué',
    'promo_code_id', v_code.id,
    'code', v_code.code,
    'discount_amount', v_discount,
    'final_total', v_final_total
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.redeem_promo_code(
  p_promo_code_id UUID,
  p_order_id UUID,
  p_discount_amount NUMERIC
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID := auth.uid();
BEGIN
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'message', 'Utilisateur non connecté');
  END IF;

  INSERT INTO public.promo_code_redemptions(
    promo_code_id, customer_user_id, order_id, discount_amount
  ) VALUES (
    p_promo_code_id, v_user_id, p_order_id, COALESCE(p_discount_amount, 0)
  )
  ON CONFLICT (promo_code_id, order_id) WHERE order_id IS NOT NULL DO NOTHING;

  UPDATE public.promo_codes
  SET used_count = used_count + 1, updated_at = NOW()
  WHERE id = p_promo_code_id;

  RETURN jsonb_build_object('success', true, 'message', 'Code promo consommé');
END;
$$;

-- ============================================================
-- 15) STORAGE BUCKETS
-- ============================================================
INSERT INTO storage.buckets (id, name, public)
VALUES ('product-images', 'product-images', true)
ON CONFLICT (id) DO UPDATE SET public = true;

INSERT INTO storage.buckets (id, name, public)
VALUES ('profile-images', 'profile-images', true)
ON CONFLICT (id) DO UPDATE SET public = true;

DROP POLICY IF EXISTS "Public read product images" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated upload product images" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated update product images" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated delete product images" ON storage.objects;
DROP POLICY IF EXISTS "Public read profile images" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated upload profile images" ON storage.objects;

CREATE POLICY "Public read product images"
ON storage.objects FOR SELECT
USING (bucket_id = 'product-images');

CREATE POLICY "Authenticated upload product images"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'product-images');

CREATE POLICY "Authenticated update product images"
ON storage.objects FOR UPDATE TO authenticated
USING (bucket_id = 'product-images');

CREATE POLICY "Authenticated delete product images"
ON storage.objects FOR DELETE TO authenticated
USING (bucket_id = 'product-images');

CREATE POLICY "Public read profile images"
ON storage.objects FOR SELECT
USING (bucket_id = 'profile-images');

CREATE POLICY "Authenticated upload profile images"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'profile-images');

-- ============================================================
-- 16) VERIFY
-- ============================================================
SELECT 'Setup RAAGA terminé ✅' AS status;
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_type = 'BASE TABLE'
ORDER BY table_name;
