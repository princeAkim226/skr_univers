-- =========================================================
-- Fix RLS promo_codes pour accès admin
-- Erreur corrigée:
-- "new row violates row-level security policy for table promo_codes"
-- =========================================================

ALTER TABLE public.promo_codes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins can manage all promo codes" ON public.promo_codes;

CREATE POLICY "Admins can manage all promo codes"
ON public.promo_codes
FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.users u
    WHERE u.id = auth.uid()
      AND u.is_admin = true
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM public.users u
    WHERE u.id = auth.uid()
      AND u.is_admin = true
  )
);

-- Vérification rapide: le compte courant est-il admin ?
SELECT id, user_type, is_admin
FROM public.users
WHERE id = auth.uid();
