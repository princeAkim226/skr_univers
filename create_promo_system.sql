-- ============================================================
-- Système de codes promo (Admin -> E-commerçant -> Client)
-- Projet: RAAGA
-- ============================================================

-- 1) Tables principales
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
  usage_limit_total INT,
  usage_limit_per_customer INT DEFAULT 1,
  used_count INT NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_by_admin_id UUID,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.promo_code_redemptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  promo_code_id UUID NOT NULL REFERENCES public.promo_codes(id) ON DELETE CASCADE,
  customer_id UUID NOT NULL REFERENCES public.customers(id) ON DELETE CASCADE,
  order_id UUID REFERENCES public.orders(id) ON DELETE SET NULL,
  discount_amount NUMERIC(12,2) NOT NULL DEFAULT 0,
  redeemed_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_promo_codes_code ON public.promo_codes(code);
CREATE INDEX IF NOT EXISTS idx_promo_codes_merchant ON public.promo_codes(merchant_id);
CREATE INDEX IF NOT EXISTS idx_promo_redemptions_code ON public.promo_code_redemptions(promo_code_id);
CREATE INDEX IF NOT EXISTS idx_promo_redemptions_customer ON public.promo_code_redemptions(customer_id);

-- 2) Colonnes optionnelles sur orders pour traçabilité remise
ALTER TABLE public.orders
  ADD COLUMN IF NOT EXISTS promo_code_id UUID REFERENCES public.promo_codes(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS promo_code TEXT,
  ADD COLUMN IF NOT EXISTS discount_amount NUMERIC(12,2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS subtotal_amount NUMERIC(12,2);

-- 3) RLS
ALTER TABLE public.promo_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.promo_code_redemptions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Promo codes readable by authenticated" ON public.promo_codes;
DROP POLICY IF EXISTS "Merchants manage own promo codes" ON public.promo_codes;
DROP POLICY IF EXISTS "Redemptions visible to owner" ON public.promo_code_redemptions;

-- Les clients authentifiés peuvent lire pour validation via app.
CREATE POLICY "Promo codes readable by authenticated"
ON public.promo_codes
FOR SELECT
TO authenticated
USING (is_active = true);

-- Les marchands peuvent gérer leurs propres codes.
CREATE POLICY "Merchants manage own promo codes"
ON public.promo_codes
FOR ALL
TO authenticated
USING (merchant_id IN (SELECT id FROM public.merchants WHERE user_id = auth.uid()))
WITH CHECK (merchant_id IN (SELECT id FROM public.merchants WHERE user_id = auth.uid()));

-- Visibilité des redemptions: client propriétaire ou marchand propriétaire.
CREATE POLICY "Redemptions visible to owner"
ON public.promo_code_redemptions
FOR SELECT
TO authenticated
USING (
  customer_id IN (SELECT id FROM public.customers WHERE user_id = auth.uid())
  OR promo_code_id IN (
    SELECT p.id
    FROM public.promo_codes p
    JOIN public.merchants m ON m.id = p.merchant_id
    WHERE m.user_id = auth.uid()
  )
);

-- 4) Fonction RPC: validation sécurisée
CREATE OR REPLACE FUNCTION public.validate_promo_code(
  p_code TEXT,
  p_merchant_id UUID,
  p_order_total NUMERIC
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_now TIMESTAMPTZ := NOW();
  v_customer_id UUID;
  v_code public.promo_codes%ROWTYPE;
  v_customer_uses INT := 0;
  v_discount NUMERIC(12,2) := 0;
  v_final_total NUMERIC(12,2) := 0;
BEGIN
  -- Client connecté requis
  SELECT c.id INTO v_customer_id
  FROM public.customers c
  WHERE c.user_id = auth.uid()
  LIMIT 1;

  IF v_customer_id IS NULL THEN
    RETURN jsonb_build_object('valid', false, 'message', 'Profil client introuvable');
  END IF;

  SELECT * INTO v_code
  FROM public.promo_codes
  WHERE lower(code) = lower(trim(p_code))
    AND merchant_id = p_merchant_id
    AND is_active = true
  LIMIT 1;

  IF v_code.id IS NULL THEN
    RETURN jsonb_build_object('valid', false, 'message', 'Code promo invalide');
  END IF;

  IF v_code.starts_at IS NOT NULL AND v_now < v_code.starts_at THEN
    RETURN jsonb_build_object('valid', false, 'message', 'Code promo pas encore actif');
  END IF;
  IF v_code.ends_at IS NOT NULL AND v_now > v_code.ends_at THEN
    RETURN jsonb_build_object('valid', false, 'message', 'Code promo expiré');
  END IF;

  IF COALESCE(v_code.usage_limit_total, 0) > 0 AND v_code.used_count >= v_code.usage_limit_total THEN
    RETURN jsonb_build_object('valid', false, 'message', 'Limite globale du code atteinte');
  END IF;

  SELECT COUNT(*) INTO v_customer_uses
  FROM public.promo_code_redemptions
  WHERE promo_code_id = v_code.id
    AND customer_id = v_customer_id;

  IF COALESCE(v_code.usage_limit_per_customer, 0) > 0
     AND v_customer_uses >= v_code.usage_limit_per_customer THEN
    RETURN jsonb_build_object('valid', false, 'message', 'Code déjà utilisé (limite client atteinte)');
  END IF;

  IF p_order_total < COALESCE(v_code.min_order_amount, 0) THEN
    RETURN jsonb_build_object(
      'valid', false,
      'message', 'Montant minimum non atteint',
      'min_order_amount', v_code.min_order_amount
    );
  END IF;

  IF v_code.discount_type = 'percent' THEN
    v_discount := (p_order_total * v_code.discount_value) / 100.0;
  ELSE
    v_discount := v_code.discount_value;
  END IF;

  IF v_code.max_discount_amount IS NOT NULL THEN
    v_discount := LEAST(v_discount, v_code.max_discount_amount);
  END IF;
  v_discount := LEAST(v_discount, p_order_total);
  v_final_total := p_order_total - v_discount;

  RETURN jsonb_build_object(
    'valid', true,
    'message', 'Code promo appliqué',
    'promo_code_id', v_code.id,
    'code', v_code.code,
    'discount_amount', v_discount,
    'final_total', v_final_total
  );
END;
$$;

