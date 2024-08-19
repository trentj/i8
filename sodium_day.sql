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
        SUM(sodium_mg) AS total_sodium_mg
    FROM
        recipe_sodium
    GROUP BY
        recipe_id
)
-- Calculate total sodium per day
SELECT
    l.date,
    CAST(ROUND(SUM(
        CASE
            -- Sodium for food units
            WHEN l.food_unit_id IS NOT NULL THEN l.quantity * f.sodium_mg
            -- Sodium for recipes
            WHEN l.recipe_id IS NOT NULL THEN l.quantity * rt.total_sodium_mg
        END
    )) AS INTEGER) AS total_sodium_mg
FROM
    logbook l
LEFT JOIN
    food_units f ON l.food_unit_id = f.food_unit_id
LEFT JOIN
    recipe_totals rt ON l.recipe_id = rt.recipe_id
GROUP BY
    l.date
ORDER BY
    l.date;
