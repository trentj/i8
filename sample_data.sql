-- Insert foods with more variety
INSERT INTO foods (name, variant, format, source) VALUES
('Asparagus', NULL, 'fresh', 'Generic Brand'),
('Lettuce', 'Romaine', 'fresh', 'Kirkland'),
('Chicken Breast', NULL, 'cooked', 'Tyson'),
('Bread', NULL, 'sliced', 'Wonder Bread'),
('Cheese', 'Cheddar', 'sliced', 'Kraft'),
('Apple', NULL, 'fresh', 'Generic Brand'),
('Carrot', NULL, 'raw', 'Organic Farm'),
('Rice', NULL, 'cooked', 'Uncle Ben''s'),
('Orange Juice', NULL, 'bottle', 'Tropicana'),
('Coffee', NULL, 'cup', 'Starbucks');

-- Insert food units with sodium content
INSERT INTO food_units (food_id, unit, sodium_mg) VALUES
(1, '1 spear', 1),          -- Asparagus
(1, '100 g', 2),            -- Asparagus
(2, '1 cup', 10),           -- Lettuce
(2, '100 g', 15),           -- Lettuce
(3, '100 g', 60),           -- Chicken Breast
(4, '1 slice', 150),        -- Bread
(5, '1 slice', 200),        -- Cheese
(6, '1 apple', 2),          -- Apple
(7, '1 carrot', 45),        -- Carrot
(8, '1 cup', 0),            -- Rice (negligible sodium)
(9, '1 cup', 5),            -- Orange Juice
(10, '1 cup', 10);          -- Coffee

-- Insert recipes with additional variety
INSERT INTO recipes (name, unit) VALUES
('Chicken Sandwich', '1 sandwich'),
('Chicken Salad', '1 bowl'),
('Rice Bowl', '1 bowl'),
('Fruit Salad', '1 bowl');

-- Insert recipe ingredients
INSERT INTO recipe_ingredients (recipe_id, food_unit_id, quantity) VALUES
(1, 4, 2),    -- Chicken Sandwich: 2 slices of Bread
(1, 3, 100),  -- Chicken Sandwich: 100 g of Chicken Breast
(1, 5, 1),    -- Chicken Sandwich: 1 slice of Cheese
(2, 2, 1),    -- Chicken Salad: 1 cup of Lettuce
(2, 3, 150),  -- Chicken Salad: 150 g of Chicken Breast
(3, 8, 1),    -- Rice Bowl: 1 cup of Rice
(3, 3, 100),  -- Rice Bowl: 100 g of Chicken Breast
(4, 6, 1),    -- Fruit Salad: 1 Apple
(4, 7, 1);    -- Fruit Salad: 1 Carrot

-- Insert logbook entries with drinks and more variety
INSERT INTO logbook (date, food_unit_id, quantity) VALUES
('2024-08-10', 1, 3),          -- Consumed 3 spears of Asparagus
('2024-08-10', 6, 1),          -- Consumed 1 Apple
('2024-08-10', 7, 1),          -- Consumed 1 Carrot
('2024-08-10', 8, 1),          -- Consumed 1 cup of Rice
('2024-08-10', 9, 1),          -- Consumed 1 cup of Orange Juice
('2024-08-10', 10, 1),         -- Consumed 1 cup of Coffee
('2024-08-10', 4, 1),          -- Consumed 1 slice of Bread
('2024-08-10', 7, 1),          -- Consumed 1 slice of Cheese
('2024-08-10', 3, 100),        -- Consumed 100 g of Chicken Breast
('2024-08-10', 10, 1),         -- Consumed 1 Chicken Sandwich (Recipe)
('2024-08-11', 1, 2),          -- Consumed 2 spears of Asparagus
('2024-08-11', 6, 1),          -- Consumed 1 Apple
('2024-08-11', 4, 1),          -- Consumed 1 slice of Bread
('2024-08-11', 3, 150),        -- Consumed 150 g of Chicken Breast
('2024-08-11', 9, 1),          -- Consumed 1 cup of Orange Juice
('2024-08-11', 10, 1),         -- Consumed 1 cup of Coffee
('2024-08-11', 4, 1),          -- Consumed 1 slice of Bread
('2024-08-11', 12, 1);         -- Consumed 1 Rice Bowl (Recipe)

