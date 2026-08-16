-- Script pour créer les buckets de stockage Supabase
-- Exécuter ce script dans l'éditeur SQL de Supabase

-- Créer le bucket pour les images de produits
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'product-images',
  'product-images',
  true,
  5242880, -- 5MB en bytes
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']
) ON CONFLICT (id) DO NOTHING;

-- Créer le bucket pour les images de profil
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'profile-images',
  'profile-images',
  true,
  2097152, -- 2MB en bytes
  ARRAY['image/jpeg', 'image/png', 'image/webp']
) ON CONFLICT (id) DO NOTHING;

-- Créer le bucket pour les pièces d'identité (privé)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'merchant-id-cards',
  'merchant-id-cards',
  false, -- Privé pour la sécurité
  5242880, -- 5MB en bytes
  ARRAY['image/jpeg', 'image/png', 'image/webp']
) ON CONFLICT (id) DO NOTHING;

-- Politiques RLS pour le bucket product-images
DROP POLICY IF EXISTS "Public Access" ON storage.objects;
CREATE POLICY "Public Access" ON storage.objects
FOR SELECT USING (bucket_id = 'product-images');

DROP POLICY IF EXISTS "Authenticated users can upload" ON storage.objects;
CREATE POLICY "Authenticated users can upload" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'product-images' 
  AND auth.role() = 'authenticated'
);

DROP POLICY IF EXISTS "Users can update their own images" ON storage.objects;
CREATE POLICY "Users can update their own images" ON storage.objects
FOR UPDATE USING (
  bucket_id = 'product-images' 
  AND auth.role() = 'authenticated'
);

DROP POLICY IF EXISTS "Users can delete their own images" ON storage.objects;
CREATE POLICY "Users can delete their own images" ON storage.objects
FOR DELETE USING (
  bucket_id = 'product-images' 
  AND auth.role() = 'authenticated'
);

-- Politiques RLS pour le bucket profile-images
DROP POLICY IF EXISTS "Public Access Profile" ON storage.objects;
CREATE POLICY "Public Access Profile" ON storage.objects
FOR SELECT USING (bucket_id = 'profile-images');

DROP POLICY IF EXISTS "Authenticated users can upload profile images" ON storage.objects;
CREATE POLICY "Authenticated users can upload profile images" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'profile-images' 
  AND auth.role() = 'authenticated'
);

DROP POLICY IF EXISTS "Users can update their own profile images" ON storage.objects;
CREATE POLICY "Users can update their own profile images" ON storage.objects
FOR UPDATE USING (
  bucket_id = 'profile-images' 
  AND auth.role() = 'authenticated'
);

-- Politiques RLS pour le bucket merchant-id-cards (privé)
DROP POLICY IF EXISTS "Merchants can upload their own ID cards" ON storage.objects;
CREATE POLICY "Merchants can upload their own ID cards" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'merchant-id-cards' 
  AND auth.role() = 'authenticated'
);

DROP POLICY IF EXISTS "Merchants can view their own ID cards" ON storage.objects;
CREATE POLICY "Merchants can view their own ID cards" ON storage.objects
FOR SELECT USING (
  bucket_id = 'merchant-id-cards' 
  AND auth.role() = 'authenticated'
);

DROP POLICY IF EXISTS "Merchants can update their own ID cards" ON storage.objects;
CREATE POLICY "Merchants can update their own ID cards" ON storage.objects
FOR UPDATE USING (
  bucket_id = 'merchant-id-cards' 
  AND auth.role() = 'authenticated'
);

-- Vérifier que les buckets ont été créés
SELECT id, name, public, file_size_limit, created_at 
FROM storage.buckets 
WHERE id IN ('product-images', 'profile-images', 'merchant-id-cards');
