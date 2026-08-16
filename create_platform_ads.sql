-- ============================================================
-- Business Place — Publicités propriétaires (plateforme)
-- Distinctes des publicités e-commerçants (table public.ads)
--
-- À exécuter dans: Dashboard Supabase > SQL Editor > Run
-- ============================================================

CREATE TABLE IF NOT EXISTS public.platform_ads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT,
  image_url TEXT,
  target_url TEXT,
  placement VARCHAR(50) DEFAULT 'home_banner',
  start_date TIMESTAMPTZ DEFAULT NOW(),
  end_date TIMESTAMPTZ,
  is_active BOOLEAN DEFAULT TRUE,
  created_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_platform_ads_active
  ON public.platform_ads (is_active, start_date, end_date);

ALTER TABLE public.platform_ads ENABLE ROW LEVEL SECURITY;

GRANT SELECT ON TABLE public.platform_ads TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON TABLE public.platform_ads TO authenticated;
GRANT ALL ON TABLE public.platform_ads TO service_role;

DROP POLICY IF EXISTS "platform_ads_public_read" ON public.platform_ads;
CREATE POLICY "platform_ads_public_read"
  ON public.platform_ads
  FOR SELECT
  USING (
    is_active = TRUE
    AND start_date <= NOW()
    AND (end_date IS NULL OR end_date >= NOW())
  );

DROP POLICY IF EXISTS "platform_ads_admin_all" ON public.platform_ads;
CREATE POLICY "platform_ads_admin_all"
  ON public.platform_ads
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.id = auth.uid() AND u.is_admin = TRUE
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.users u
      WHERE u.id = auth.uid() AND u.is_admin = TRUE
    )
  );

-- Temps réel : messages + conversations + pubs plateforme
DO $$
BEGIN
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
  EXCEPTION WHEN duplicate_object THEN NULL;
  END;
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.conversations;
  EXCEPTION WHEN duplicate_object THEN NULL;
  END;
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.platform_ads;
  EXCEPTION WHEN duplicate_object THEN NULL;
  END;
END $$;

NOTIFY pgrst, 'reload schema';
