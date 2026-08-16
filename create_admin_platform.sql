-- ============================================================
-- Business Place — Plateforme admin
-- Droits de lecture/écriture pour les comptes is_admin
-- À exécuter dans: Dashboard Supabase > SQL Editor > Run
-- ============================================================

-- Produits
DROP POLICY IF EXISTS "Admins manage products" ON public.products;
CREATE POLICY "Admins manage products"
ON public.products FOR ALL TO authenticated
USING (EXISTS (SELECT 1 FROM public.users u WHERE u.id = auth.uid() AND u.is_admin = true))
WITH CHECK (EXISTS (SELECT 1 FROM public.users u WHERE u.id = auth.uid() AND u.is_admin = true));

-- Pubs boutiques
DROP POLICY IF EXISTS "Admins manage merchant ads" ON public.ads;
CREATE POLICY "Admins manage merchant ads"
ON public.ads FOR ALL TO authenticated
USING (EXISTS (SELECT 1 FROM public.users u WHERE u.id = auth.uid() AND u.is_admin = true))
WITH CHECK (EXISTS (SELECT 1 FROM public.users u WHERE u.id = auth.uid() AND u.is_admin = true));

-- Boutiques
DROP POLICY IF EXISTS "Admins manage merchants" ON public.merchants;
CREATE POLICY "Admins manage merchants"
ON public.merchants FOR ALL TO authenticated
USING (EXISTS (SELECT 1 FROM public.users u WHERE u.id = auth.uid() AND u.is_admin = true))
WITH CHECK (EXISTS (SELECT 1 FROM public.users u WHERE u.id = auth.uid() AND u.is_admin = true));
