-- =============================================
-- Seed data for Oraiopoli Supermarket
-- Runs after Hibernate creates/updates schema
-- All INSERTs are idempotent (ON CONFLICT DO NOTHING)
-- =============================================

-- ── Admin user (password: admin123) ──
INSERT INTO users (full_name, email, phone, password, role, enabled, created_at, updated_at)
VALUES ('Super Admin', 'admin@oraiopoli.com', '+30 000 000 0000',
        '$2b$10$5.nVNC6ftsMsYQZvMpLcHusxsPBPqPa65JtUYeandI.vbqApuMNBe',
        'SUPER_ADMIN', true, NOW(), NOW())
ON CONFLICT (email) DO NOTHING;

-- password: 123456
INSERT INTO users (full_name, email, phone, password, role, enabled, created_at, updated_at)
VALUES ('Chris Tsi', 'tsi@oraiopoli.com', '+30 000 000 0000',
        '$2b$10$L/1hzYvr1kdePpIodJJ/N.olKKZJqXP6RBiybW6ZRpgkyhrf.EUpy',
        'CUSTOMER', true, NOW(), NOW())
ON CONFLICT (email) DO UPDATE SET password = EXCLUDED.password;

-- ── Address for Chris Tsi ──
INSERT INTO addresses (label, address_line, city, postal_code, country, is_default, latitude, longitude, user_id, created_at, updated_at)
SELECT 'Σπίτι', 'Asklipiou 33', 'Καλλιθέα', '17674', 'Ελλάδα', true, 37.94606005661072, 23.687834807587645, u.id, NOW(), NOW()
FROM users u WHERE u.email = 'tsi@oraiopoli.com'
  AND NOT EXISTS (SELECT 1 FROM addresses a WHERE a.user_id = u.id AND a.label = 'Σπίτι');


/*
-- ── Brands ──
INSERT INTO brands (name, slug, description, active, created_at, updated_at) VALUES
    ('ΔΕΛΤΑ',        'delta',        'Greek dairy & juice company',           true, NOW(), NOW()),
    ('ΦΑΓΕ',         'fage',         'Premium Greek yogurt & dairy',          true, NOW(), NOW()),
    ('ΜΕΒΓΑΛ',       'mevgal',       'Northern Greece dairy products',        true, NOW(), NOW()),
    ('Παπαδοπούλου', 'papadopoulou', 'Greek biscuits & bakery products',      true, NOW(), NOW()),
    ('ΙΟΝ',          'ion',          'Greek chocolate & confectionery',       true, NOW(), NOW()),
    ('Barilla',       'barilla',      'Italian pasta & sauces',               true, NOW(), NOW()),
    ('Coca-Cola',     'coca-cola',    'Beverages & soft drinks',              true, NOW(), NOW()),
    ('Κρι Κρι',      'kri-kri',      'Greek dairy & ice cream',              true, NOW(), NOW())
ON CONFLICT (slug) DO NOTHING;

-- ── Categories ──
INSERT INTO categories (name, slug, description, display_order, active, parent_id, created_at, updated_at) VALUES
    ('Γαλακτοκομικά',      'dairy',              'Milk, yogurt, cheese & eggs',            1,  true, NULL, NOW(), NOW()),
    ('Φρούτα & Λαχανικά',  'fruits-vegetables',  'Fresh fruits and vegetables',            2,  true, NULL, NOW(), NOW()),
    ('Κρέας & Ψάρι',       'meat-seafood',       'Fresh meat, poultry & seafood',          3,  true, NULL, NOW(), NOW()),
    ('Αρτοποιήματα',       'bakery',             'Bread, pastries & baked goods',          4,  true, NULL, NOW(), NOW()),
    ('Ποτά',               'beverages',          'Water, juices, soft drinks & coffee',    5,  true, NULL, NOW(), NOW()),
    ('Σνακ & Γλυκά',       'snacks-sweets',      'Chips, biscuits, chocolate & candy',     6,  true, NULL, NOW(), NOW()),
    ('Βασικά Τρόφιμα',     'pantry',             'Pasta, rice, oil, canned goods',         7,  true, NULL, NOW(), NOW()),
    ('Κατεψυγμένα',        'frozen',             'Frozen meals, vegetables & desserts',    8,  true, NULL, NOW(), NOW()),
    ('Καθαριότητα',        'cleaning',           'Household cleaning supplies',            9,  true, NULL, NOW(), NOW()),
    ('Προσωπική Φροντίδα', 'personal-care',      'Hygiene & personal care products',       10, true, NULL, NOW(), NOW())
ON CONFLICT (slug) DO NOTHING;

-- ── Products ──
-- Dairy
INSERT INTO products (name, slug, sku, description, price, discount_price, unit, active, featured, category_id, brand_id, created_at, updated_at)
VALUES
    ('ΔΕΛΤΑ Γάλα Πλήρες 1L',        'delta-gala-plires-1l',     'DAI-001', 'Fresh full-fat milk 3.5%',                          1.89, NULL, 'piece', true, true,
        (SELECT id FROM categories WHERE slug = 'dairy'), (SELECT id FROM brands WHERE slug = 'delta'), NOW(), NOW()),
    ('ΦΑΓΕ Total 2% 200g',          'fage-total-2-200g',        'DAI-002', 'Strained yogurt 2% fat',                            1.65, 1.39, 'piece', true, true,
        (SELECT id FROM categories WHERE slug = 'dairy'), (SELECT id FROM brands WHERE slug = 'fage'), NOW(), NOW()),
    ('Κρι Κρι Στραγγιστό 1kg',      'kri-kri-straggisto-1kg',   'DAI-003', 'Greek strained yogurt 2%',                          3.49, NULL, 'piece', true, false,
        (SELECT id FROM categories WHERE slug = 'dairy'), (SELECT id FROM brands WHERE slug = 'kri-kri'), NOW(), NOW()),
    ('ΜΕΒΓΑΛ Φέτα ΠΟΠ 400g',        'mevgal-feta-pop-400g',     'DAI-004', 'Traditional Greek PDO feta cheese',                  4.99, 4.49, 'piece', true, false,
        (SELECT id FROM categories WHERE slug = 'dairy'), (SELECT id FROM brands WHERE slug = 'mevgal'), NOW(), NOW())
ON CONFLICT (slug) DO NOTHING;

-- Fruits & Vegetables
INSERT INTO products (name, slug, sku, description, price, discount_price, unit, active, featured, category_id, brand_id, created_at, updated_at)
VALUES
    ('Μπανάνες Chiquita',            'bananes-chiquita',         'FRU-001', 'Premium bananas, approx 1kg',                       2.19, NULL, 'kg',    true, false,
        (SELECT id FROM categories WHERE slug = 'fruits-vegetables'), NULL, NOW(), NOW()),
    ('Ντομάτες Βιολογικές',          'ntomates-viologikes',      'FRU-002', 'Organic vine tomatoes',                             3.29, 2.79, 'kg',    true, true,
        (SELECT id FROM categories WHERE slug = 'fruits-vegetables'), NULL, NOW(), NOW()),
    ('Πατάτες Ελληνικές',            'patates-ellinikes',        'FRU-003', 'Greek potatoes, 2kg bag',                           2.99, NULL, 'piece', true, false,
        (SELECT id FROM categories WHERE slug = 'fruits-vegetables'), NULL, NOW(), NOW())
ON CONFLICT (slug) DO NOTHING;

-- Bakery
INSERT INTO products (name, slug, sku, description, price, discount_price, unit, active, featured, category_id, brand_id, created_at, updated_at)
VALUES
    ('Παπαδοπούλου Φρυγανιές Σίτου', 'papadopoulou-fryganies-sitou', 'BAK-001', 'Whole wheat rusks 240g',                       1.89, NULL, 'piece', true, false,
        (SELECT id FROM categories WHERE slug = 'bakery'), (SELECT id FROM brands WHERE slug = 'papadopoulou'), NOW(), NOW()),
    ('Ψωμί Ολικής Άλεσης 500g',     'psomi-olikis-alesis-500g', 'BAK-002', 'Whole grain bread loaf',                            1.49, NULL, 'piece', true, false,
        (SELECT id FROM categories WHERE slug = 'bakery'), NULL, NOW(), NOW())
ON CONFLICT (slug) DO NOTHING;

-- Beverages
INSERT INTO products (name, slug, sku, description, price, discount_price, unit, active, featured, category_id, brand_id, created_at, updated_at)
VALUES
    ('Coca-Cola 1.5L',               'coca-cola-1-5l',           'BEV-001', 'Coca-Cola original taste 1.5L',                     1.79, 1.49, 'piece', true, true,
        (SELECT id FROM categories WHERE slug = 'beverages'), (SELECT id FROM brands WHERE slug = 'coca-cola'), NOW(), NOW()),
    ('ΔΕΛΤΑ Χυμός Πορτοκάλι 1L',    'delta-xymos-portokali-1l', 'BEV-002', '100% natural orange juice',                         2.49, NULL, 'piece', true, false,
        (SELECT id FROM categories WHERE slug = 'beverages'), (SELECT id FROM brands WHERE slug = 'delta'), NOW(), NOW()),
    ('Νερό Ζαγόρι 1.5L (6 τεμ)',    'nero-zagori-6pack',        'BEV-003', 'Natural mineral water 6-pack',                      2.99, NULL, 'piece', true, false,
        (SELECT id FROM categories WHERE slug = 'beverages'), NULL, NOW(), NOW())
ON CONFLICT (slug) DO NOTHING;

-- Snacks & Sweets
INSERT INTO products (name, slug, sku, description, price, discount_price, unit, active, featured, category_id, brand_id, created_at, updated_at)
VALUES
    ('ΙΟΝ Σοκολάτα Γάλακτος 100g',  'ion-sokolata-galaktos-100g','SNK-001', 'Classic milk chocolate bar',                       1.59, NULL, 'piece', true, true,
        (SELECT id FROM categories WHERE slug = 'snacks-sweets'), (SELECT id FROM brands WHERE slug = 'ion'), NOW(), NOW()),
    ('ΙΟΝ Αμυγδάλου 100g',          'ion-amygdalou-100g',       'SNK-002', 'Dark chocolate with almonds',                       1.79, NULL, 'piece', true, false,
        (SELECT id FROM categories WHERE slug = 'snacks-sweets'), (SELECT id FROM brands WHERE slug = 'ion'), NOW(), NOW()),
    ('Παπαδοπούλου Μιράντα 250g',    'papadopoulou-miranda-250g','SNK-003', 'Classic Greek biscuits',                            1.99, 1.69, 'piece', true, false,
        (SELECT id FROM categories WHERE slug = 'snacks-sweets'), (SELECT id FROM brands WHERE slug = 'papadopoulou'), NOW(), NOW())
ON CONFLICT (slug) DO NOTHING;

-- Pantry
INSERT INTO products (name, slug, sku, description, price, discount_price, unit, active, featured, category_id, brand_id, created_at, updated_at)
VALUES
    ('Barilla Spaghetti No.5 500g',  'barilla-spaghetti-no5-500g','PAN-001', 'Classic Italian spaghetti',                        1.69, NULL, 'piece', true, false,
        (SELECT id FROM categories WHERE slug = 'pantry'), (SELECT id FROM brands WHERE slug = 'barilla'), NOW(), NOW()),
    ('Barilla Penne Rigate 500g',    'barilla-penne-rigate-500g','PAN-002', 'Penne pasta',                                       1.69, NULL, 'piece', true, false,
        (SELECT id FROM categories WHERE slug = 'pantry'), (SELECT id FROM brands WHERE slug = 'barilla'), NOW(), NOW()),
    ('Ελαιόλαδο Εξαιρ. Παρθένο 1L', 'elaiolado-exairetiko-1l', 'PAN-003', 'Extra virgin olive oil, 1 litre',                   8.99, 7.99, 'piece', true, true,
        (SELECT id FROM categories WHERE slug = 'pantry'), NULL, NOW(), NOW())
ON CONFLICT (slug) DO NOTHING;

-- ── Inventory (stock for every product) ──
INSERT INTO inventory (product_id, quantity, low_stock_threshold, created_at, updated_at)
SELECT p.id, stock.qty, stock.threshold, NOW(), NOW()
FROM (VALUES
    ('DAI-001', 120, 15),
    ('DAI-002',  85, 10),
    ('DAI-003',  60, 10),
    ('DAI-004',  45, 10),
    ('FRU-001', 200, 20),
    ('FRU-002',  75, 10),
    ('FRU-003', 150, 20),
    ('BAK-001',  90, 15),
    ('BAK-002', 100, 15),
    ('BEV-001', 300, 30),
    ('BEV-002', 100, 15),
    ('BEV-003', 180, 20),
    ('SNK-001', 150, 15),
    ('SNK-002', 120, 15),
    ('SNK-003',  80, 10),
    ('PAN-001', 200, 20),
    ('PAN-002', 180, 20),
    ('PAN-003',  50, 10)
) AS stock(sku, qty, threshold)
JOIN products p ON p.sku = stock.sku
WHERE NOT EXISTS (SELECT 1 FROM inventory i WHERE i.product_id = p.id);*/

-- ── Banners ──
INSERT INTO banners (title, subtitle, image_url, link_url, display_order, active, start_date, end_date, created_at, updated_at)
SELECT v.title, v.subtitle, v.image_url, v.link_url, v.display_order, v.active, v.start_date, v.end_date, NOW(), NOW()
FROM (VALUES
    ('Καλοκαιρινές Προσφορές!',  'Έως 40% έκπτωση σε επιλεγμένα προϊόντα',
     'https://images.unsplash.com/photo-1542838132-92c53300491e?w=1200', '/promotions',
     1, true, TIMESTAMP '2026-03-01 00:00:00', TIMESTAMP '2026-12-31 23:59:59'),
    ('Δωρεάν Παράδοση',          'Για παραγγελίες άνω των 30€',
     'https://images.unsplash.com/photo-1604719312566-8912e9227c6a?w=1200', NULL,
     2, true, NULL::timestamp, NULL::timestamp),
    ('Φρέσκα Φρούτα & Λαχανικά', 'Κάθε μέρα από τοπικούς παραγωγούς',
     'https://images.unsplash.com/photo-1488459716781-31db52582fe9?w=1200', '/categories/fruits-vegetables',
     3, true, NULL::timestamp, NULL::timestamp)
) AS v(title, subtitle, image_url, link_url, display_order, active, start_date, end_date)
WHERE NOT EXISTS (SELECT 1 FROM banners b WHERE b.title = v.title);

-- ── Promotions ──
INSERT INTO promotions (title, description, code, discount_percentage, discount_amount, min_order_amount, image_url, active, start_date, end_date, created_at, updated_at) VALUES
    ('Καλοκαίρι 2026 – 15% Έκπτωση', 'Χρησιμοποιήστε τον κωδικό SUMMER15 για 15% έκπτωση σε όλη την παραγγελία σας!',
     'SUMMER15', 15.00, NULL, 20.00,
     'https://images.unsplash.com/photo-1607082349566-187342175e2f?w=800',
     true, '2026-03-01 00:00:00', '2026-09-30 23:59:59', NOW(), NOW()),
    ('Έκπτωση 5€ στην πρώτη παραγγελία', 'Κάνε εγγραφή και πάρε 5€ έκπτωση στην πρώτη σου παραγγελία.',
     'WELCOME5', NULL, 5.00, 15.00,
     'https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?w=800',
     true, NULL, NULL, NOW(), NOW()),
    ('Αγόρασε 2 πλήρωσε 1 – Γαλακτοκομικά', 'Ειδική προσφορά σε επιλεγμένα γαλακτοκομικά ΔΕΛΤΑ & ΦΑΓΕ. Ισχύει κάθε Τετάρτη!',
     'DAIRY2FOR1', 50.00, NULL, NULL,
     'https://images.unsplash.com/photo-1628088062854-d1870b4553da?w=800',
     true, '2026-01-01 00:00:00', '2026-12-31 23:59:59', NOW(), NOW())
ON CONFLICT (code) DO NOTHING;

-- ── Store Settings ──
INSERT INTO store_settings (setting_key, setting_value, description, created_at, updated_at) VALUES
    ('store_name',             'Ωραιόπολη Supermarket',    'Display name of the store',                     NOW(), NOW()),
    ('store_phone',            '+30 2310 123 456',         'Store contact phone number',                    NOW(), NOW()),
    ('store_email',            'info@oraiopoli.com',       'Store contact email',                           NOW(), NOW()),
    ('store_address',          'Ωραιόπολη, Καλλιθέα',  'Physical store address',                        NOW(), NOW()),
    ('delivery_fee',           '2.50',                     'Default delivery fee in euros',                  NOW(), NOW()),
    ('free_delivery_threshold','30.00',                    'Order amount for free delivery (euros)',         NOW(), NOW()),
    ('min_order_amount',       '10.00',                    'Minimum order amount in euros',                  NOW(), NOW()),
    ('store_hours',            '08:00 - 21:00',            'Daily operating hours',                         NOW(), NOW()),
    ('currency',               'EUR',                      'Store currency code',                           NOW(), NOW()),
    ('order_confirmation_msg', 'Ευχαριστούμε για την παραγγελία σας! Θα επικοινωνήσουμε σύντομα μαζί σας.', 'Message shown after order placement', NOW(), NOW()),
    ('store_latitude',         '37.95480244560913',                  'Store latitude for distance calculation',       NOW(), NOW()),
    ('store_longitude',        '23.704514585017858',                  'Store longitude for distance calculation',      NOW(), NOW()),
    ('max_delivery_km',        '3',                       'Maximum delivery distance in kilometers',       NOW(), NOW()),
    ('express_delivery_fee',   '1.00',                    'Express delivery surcharge in euros',           NOW(), NOW()),
    ('plastic_bag_fee_per_10', '0.10',                    'Plastic bag fee per €10 of order value',        NOW(), NOW())
ON CONFLICT (setting_key) DO NOTHING;


