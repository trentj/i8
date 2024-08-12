WITH RECURSIVE recipe_sodium AS (
    -- Base case: Direct food unit ingredients in the recipe
    SELECT
        r.recipe_id,
        r.name AS recipe_name,
        r.variant,
        rf.recipe_ingredient_id,
        rf.quantity * f.sodium_mg AS sodium_mg
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
        rf.quantity * rs.sodium_mg AS sodium_mg
    FROM
        recipes r
    JOIN
        recipe_ingredients rf ON r.recipe_id = rf.recipe_id
    JOIN
        recipe_sodium rs ON rf.subrecipe_id = rs.recipe_id
)
-- Summing up the sodium content for each recipe
SELECT
    recipe_id,
    recipe_name,
    variant,
    SUM(sodium_mg) AS total_sodium_mg
FROM
    recipe_sodium
GROUP BY
    recipe_id,
    recipe_name,
    variant;
