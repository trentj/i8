-- Get the amount of sodium contributed to a recipe by each ingredient.
-- First, calculate all the sodium contributed to each recipe by each ingredient...
WITH RECURSIVE unit_sodium AS (
    SELECT
        i.recipe_id,
        i.food_unit_id,
        i.subrecipe_id,
        ff.name AS item_name,
        f.unit AS unit_name,
        i.quantity,
        f.sodium_mg * i.quantity AS unit_sodium_mg
    FROM
        recipe_ingredients i
    JOIN
        food_units f ON f.food_unit_id = i.food_unit_id
    JOIN
        foods ff ON ff.food_id = f.food_id

    UNION ALL

    SELECT
        i.recipe_id,
        i.food_unit_id,
        i.subrecipe_id,
        r.name AS item_name,
        r.unit AS unit_name,
        i.quantity,
        s.unit_sodium_mg / r.yield * i.quantity AS unit_sodium_mg
    FROM
        recipe_ingredients i
    JOIN
        unit_sodium s ON s.recipe_id = i.subrecipe_id
    JOIN
        recipes r ON r.recipe_id = i.subrecipe_id
),
total_sodium AS (
    SELECT
        recipe_id,
        SUM(unit_sodium_mg) AS sodium_mg
    FROM
        unit_sodium
    GROUP BY
        recipe_id
    --ORDER BY sodium_mg DESC
)
SELECT
    r.recipe_id,
    r.name,
    r.yield,
    r.unit,
    sodium_mg
FROM
    total_sodium
JOIN
    recipes r ON r.recipe_id = total_sodium.recipe_id;