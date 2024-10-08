WITH RECURSIVE recipe_sodium AS (
    -- Base case: Direct food unit ingredients in the recipe
    SELECT
        r.recipe_id,
        r.name AS recipe_name,
        r.variant,
        rf.recipe_ingredient_id,
        rf.quantity * f.sodium_mg / r.yield AS sodium_mg
    FROM
        recipes r
    JOIN
        recipe_ingredients rf ON r.recipe_id = rf.recipe_id
    JOIN
        food_units f ON rf.food_unit_id = f.food_unit_id

    UNION ALL

    -- Recursive case: Ingredients that are sub-recipes
    SELECT
        r.recipe_id,
        r.name AS recipe_name,
        r.variant,
        rf.recipe_ingredient_id,
        rf.quantity * rs.sodium_mg / r.yield AS sodium_mg
    FROM
        recipes r
    JOIN
        recipe_ingredients rf ON r.recipe_id = rf.recipe_id
    JOIN
        recipe_sodium rs ON rf.subrecipe_id = rs.recipe_id
),
-- Summing up the sodium content for each recipe
recipe_totals AS (
    SELECT
        recipe_id,
        recipe_name,
        variant,
        SUM(sodium_mg) AS unit_sodium_mg
    FROM
        recipe_sodium
    GROUP BY
        recipe_id, recipe_name, variant
),
-- Calculate sodium content for each logbook entry
logbook_sodium AS (
    SELECT
        l.logbook_id,
        l.recipe_id,
        l.quantity,
        l.date,
        COALESCE(ff.name, rt.recipe_name || COALESCE(' (' || rt.variant || ')', '')) AS item_name,
        l.quantity * COALESCE(f.sodium_mg, rt.unit_sodium_mg) AS total_sodium_mg
    FROM
        logbook l
    LEFT JOIN
        food_units f ON l.food_unit_id = f.food_unit_id
    LEFT JOIN
        recipe_totals rt ON l.recipe_id = rt.recipe_id
    LEFT JOIN
        foods ff on f.food_id = ff.food_id
)
-- Select the top 10 highest sodium food items
SELECT
    recipe_id,
    ROUND(quantity, 2),
    item_name,
    CAST(total_sodium_mg AS INTEGER)
FROM
    logbook_sodium
ORDER BY
    total_sodium_mg DESC
LIMIT 10;
