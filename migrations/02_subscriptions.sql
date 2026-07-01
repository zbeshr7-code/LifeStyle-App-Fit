-- Create subscription_plans table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.subscription_plans (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name_en TEXT NOT NULL,
    name_ar TEXT NOT NULL,
    description_en TEXT,
    description_ar TEXT,
    price DECIMAL NOT NULL,
    duration_days INTEGER NOT NULL, -- e.g., 30 for 1 month
    features_en JSONB, -- Array of strings
    features_ar JSONB,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.subscription_plans ENABLE ROW LEVEL SECURITY;

-- Policy to allow everyone to view active plans
DO $$ BEGIN
    CREATE POLICY "Allow anyone to view active plans"
    ON public.subscription_plans
    FOR SELECT
    USING (is_active = true);
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Insert default plans if the table is empty
INSERT INTO public.subscription_plans (name_en, name_ar, description_en, description_ar, price, duration_days, features_en, features_ar)
SELECT 'Basic Plan', 'الخطة الأساسية', 'Get started with your fitness journey', 'ابدأ رحلتك الرياضية مع الخطة الأساسية', 189.00, 30,
       '["Custom Workout Plan", "General Diet Advice", "Step Tracking"]'::jsonb,
       '["جدول تمارين مخصص", "نصائح غذائية عامة", "تتبع الخطوات"]'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM public.subscription_plans WHERE name_en = 'Basic Plan');

INSERT INTO public.subscription_plans (name_en, name_ar, description_en, description_ar, price, duration_days, features_en, features_ar)
SELECT 'Pro Plan', 'الخطة الاحترافية', 'Full coaching and private chat', 'تدريب كامل ودردشة خاصة مع المدرب', 375.00, 30,
       '["Custom Workout Plan", "Personalized Meal Plan", "Private Chat with Trainer", "Progress Tracking"]'::jsonb,
       '["جدول تمارين مخصص", "نظام غذائي مخصص", "دردشة خاصة مع المدرب", "متابعة التطور"]'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM public.subscription_plans WHERE name_en = 'Pro Plan');

INSERT INTO public.subscription_plans (name_en, name_ar, description_en, description_ar, price, duration_days, features_en, features_ar)
SELECT 'Elite Plan', 'الخطة المميزة', 'Elite experience for 3 months', 'تجربة مميزة لمدة 3 أشهر', 935.00, 90,
       '["Everything in Pro", "Weekly Video Call", "Supplement Guide", "24/7 Support"]'::jsonb,
       '["كل ما في الخطة الاحترافية", "اتصال فيديو أسبوعي", "دليل المكملات", "دعم على مدار الساعة"]'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM public.subscription_plans WHERE name_en = 'Elite Plan');
