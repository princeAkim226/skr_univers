-- Script pour créer le bucket 'product-images' dans Supabase Storage
-- Exécuter ce script dans l'éditeur SQL de Supabase

-- Créer le bucket 'product-images' s'il n'existe pas
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'product-images',
  'product-images',
  true,
  10485760, -- 10MB en bytes
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']
)
ON CONFLICT (id) DO NOTHING;

-- Vérifier que le bucket a été créé
SELECT id, name, public, file_size_limit, created_at 
FROM storage.buckets 
WHERE id = 'product-images';
