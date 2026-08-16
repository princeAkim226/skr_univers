-- Script pour ajouter les tables stories et les centres d'intérêt

-- Ajouter la colonne interests à la table users
ALTER TABLE users ADD COLUMN interests TEXT[] DEFAULT '{}';

-- Créer la table stories
CREATE TABLE IF NOT EXISTS stories (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  merchant_id UUID NOT NULL REFERENCES merchants(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  images TEXT[] DEFAULT '{}',
  video_url TEXT,
  tags TEXT[] DEFAULT '{}',
  location TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
  is_active BOOLEAN DEFAULT true,
  view_count INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Créer la table ads pour les publicités
CREATE TABLE IF NOT EXISTS ads (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  merchant_id UUID NOT NULL REFERENCES merchants(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  image_url TEXT,
  target_url TEXT,
  is_active BOOLEAN DEFAULT true,
  start_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  end_date TIMESTAMP WITH TIME ZONE,
  click_count INTEGER DEFAULT 0,
  view_count INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Ajouter des index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_stories_merchant_id ON stories(merchant_id);
CREATE INDEX IF NOT EXISTS idx_stories_expires_at ON stories(expires_at);
CREATE INDEX IF NOT EXISTS idx_stories_is_active ON stories(is_active);
CREATE INDEX IF NOT EXISTS idx_ads_merchant_id ON ads(merchant_id);
CREATE INDEX IF NOT EXISTS idx_ads_is_active ON ads(is_active);
CREATE INDEX IF NOT EXISTS idx_ads_dates ON ads(start_date, end_date);

-- RLS (Row Level Security) pour les stories
ALTER TABLE stories ENABLE ROW LEVEL SECURITY;

-- Politique pour permettre à tous de lire les stories actives
CREATE POLICY "Stories are viewable by everyone" ON stories
  FOR SELECT USING (is_active = true AND expires_at > NOW());

-- Politique pour permettre aux marchands de gérer leurs propres stories
CREATE POLICY "Merchants can manage their own stories" ON stories
  FOR ALL USING (
    merchant_id IN (
      SELECT id FROM merchants WHERE user_id = auth.uid()
    )
  );

-- RLS pour les publicités
ALTER TABLE ads ENABLE ROW LEVEL SECURITY;

-- Politique pour permettre à tous de lire les publicités actives
CREATE POLICY "Ads are viewable by everyone" ON ads
  FOR SELECT USING (is_active = true AND (end_date IS NULL OR end_date > NOW()));

-- Politique pour permettre aux marchands de gérer leurs propres publicités
CREATE POLICY "Merchants can manage their own ads" ON ads
  FOR ALL USING (
    merchant_id IN (
      SELECT id FROM merchants WHERE user_id = auth.uid()
    )
  );

-- Fonction pour mettre à jour automatiquement updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers pour mettre à jour updated_at
CREATE TRIGGER update_stories_updated_at BEFORE UPDATE ON stories
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_ads_updated_at BEFORE UPDATE ON ads
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Insérer quelques exemples de stories
INSERT INTO stories (merchant_id, title, description, images, tags, expires_at) VALUES
  (
    (SELECT id FROM merchants LIMIT 1),
    'Nouvelle Collection Automne',
    'Découvrez nos nouveaux vêtements pour la saison automne',
    ARRAY['https://via.placeholder.com/400x300'],
    ARRAY['mode', 'automne', 'nouvelle-collection'],
    NOW() + INTERVAL '24 hours'
  ),
  (
    (SELECT id FROM merchants LIMIT 1),
    'Promotion Électronique',
    'Smartphones et tablettes à prix cassés',
    ARRAY['https://via.placeholder.com/400x300'],
    ARRAY['électronique', 'promotion', 'smartphone'],
    NOW() + INTERVAL '48 hours'
  );

-- Insérer quelques exemples de publicités
INSERT INTO ads (merchant_id, title, description, image_url, target_url, end_date) VALUES
  (
    (SELECT id FROM merchants LIMIT 1),
    'Nouvelle Collection Automne',
    'Découvrez nos nouveaux vêtements pour la saison',
    'https://via.placeholder.com/300x200',
    '/customer/products?category=Mode',
    NOW() + INTERVAL '30 days'
  ),
  (
    (SELECT id FROM merchants LIMIT 1),
    'Électronique à Prix Cassés',
    'Smartphones, tablettes et accessoires avec -50%',
    'https://via.placeholder.com/300x200',
    '/customer/products?category=Électronique',
    NOW() + INTERVAL '15 days'
  );
