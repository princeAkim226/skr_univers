-- =========================================================
-- RAAGA - Création de la table cart_items
-- Corrige: Could not find the table 'public.cart_items'
-- =========================================================

CREATE TABLE IF NOT EXISTS public.cart_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID NOT NULL REFERENCES public.customers(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
  quantity INTEGER NOT NULL DEFAULT 1 CHECK (quantity > 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Un produit ne doit apparaître qu'une fois par client dans le panier
CREATE UNIQUE INDEX IF NOT EXISTS ux_cart_items_customer_product
ON public.cart_items(customer_id, product_id);

CREATE INDEX IF NOT EXISTS idx_cart_items_customer_id
ON public.cart_items(customer_id);

CREATE INDEX IF NOT EXISTS idx_cart_items_product_id
ON public.cart_items(product_id);

ALTER TABLE public.cart_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Customers can read own cart items" ON public.cart_items;
DROP POLICY IF EXISTS "Customers can insert own cart items" ON public.cart_items;
DROP POLICY IF EXISTS "Customers can update own cart items" ON public.cart_items;
DROP POLICY IF EXISTS "Customers can delete own cart items" ON public.cart_items;

CREATE POLICY "Customers can read own cart items"
ON public.cart_items
FOR SELECT
TO authenticated
USING (
  customer_id IN (
    SELECT c.id FROM public.customers c WHERE c.user_id = auth.uid()
  )
);

CREATE POLICY "Customers can insert own cart items"
ON public.cart_items
FOR INSERT
TO authenticated
WITH CHECK (
  customer_id IN (
    SELECT c.id FROM public.customers c WHERE c.user_id = auth.uid()
  )
);

CREATE POLICY "Customers can update own cart items"
ON public.cart_items
FOR UPDATE
TO authenticated
USING (
  customer_id IN (
    SELECT c.id FROM public.customers c WHERE c.user_id = auth.uid()
  )
)
WITH CHECK (
  customer_id IN (
    SELECT c.id FROM public.customers c WHERE c.user_id = auth.uid()
  )
);

CREATE POLICY "Customers can delete own cart items"
ON public.cart_items
FOR DELETE
TO authenticated
USING (
  customer_id IN (
    SELECT c.id FROM public.customers c WHERE c.user_id = auth.uid()
  )
);
