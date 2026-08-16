-- =========================================================
-- RAAGA - Setup accès admin unique
-- Objectif:
-- 1) Ajouter le flag is_admin dans public.users
-- 2) Garantir qu'il n'existe qu'UN seul admin (global)
-- 3) Fournir une commande simple pour promouvoir un compte
-- =========================================================

-- 1) Colonne admin (idempotent)
ALTER TABLE public.users
ADD COLUMN IF NOT EXISTS is_admin BOOLEAN NOT NULL DEFAULT false;

-- 2) Un seul admin global autorisé
-- Si un index équivalent existe déjà, cette commande est sans danger.
CREATE UNIQUE INDEX IF NOT EXISTS ux_users_single_admin
ON public.users ((is_admin))
WHERE is_admin = true;

-- 3) Mettre tout le monde en non-admin (optionnel)
-- UPDATE public.users SET is_admin = false;

-- 4) Promouvoir UN compte admin (choisir une seule méthode)
-- 4a) Par numéro de téléphone:
-- UPDATE public.users
-- SET is_admin = true, updated_at = NOW()
-- WHERE phone_number = '226XXXXXXXX';

-- 4b) Par email:
-- UPDATE public.users
-- SET is_admin = true, updated_at = NOW()
-- WHERE email = 'admin@raaga.com';

-- 5) Vérification
SELECT id, phone_number, email, user_type, is_admin
FROM public.users
WHERE is_admin = true;
