-- build a table of subrecipes and food ingredients (root to leaf)
WITH RECURSIVE recipe_contents AS (
    SELECT
        NULL as recipe_id,
        :recipe_id AS subrecipe_id,
        NULL AS food_unit_id,
        1.0 AS quantity

    UNION ALL

    SELECT
        child.recipe_id,
        child.subrecipe_id,
        child.food_unit_id,
        child.quantity
    FROM
        recipe_ingredients child
    JOIN
        recipe_contents parent ON parent.subrecipe_id = child.recipe_id
),
-- sum up the sodium content for each recipe (leaf to root)
recipe_sodium AS (
    -- base case: food ingredients
    SELECT
        c.recipe_id,
        c.food_unit_id,
        NULL AS subrecipe_id,
        c.quantity,
        c.quantity * f.sodium_mg AS sodium_mg
    FROM
        recipe_contents c
    JOIN
        food_units f ON f.food_unit_id = c.food_unit_id

    UNION ALL
    -- recursive case: intermediate recipes
    SELECT
        c.recipe_id,
        NULL AS food_unit_id,
        c.subrecipe_id,
        c.quantity,
        c.quantity * s.sodium_mg AS sodium_mg
    FROM
        recipe_contents c
    JOIN
        recipe_sodium s ON s.recipe_id = c.subrecipe_id
)
SELECT
    NULL, f.name, ROUND(s.quantity, 2), u.unit, ROUND(s.sodium_mg, 3) AS sodium_mg
FROM
    recipe_sodium s
JOIN
    food_units u ON u.food_unit_id = s.food_unit_id
JOIN
    foods f ON f.food_id = u.food_id
WHERE s.recipe_id = :recipe_id

UNION ALL

SELECT
    r.recipe_id, r.name, ROUND(s.quantity, 2), r.unit, ROUND(SUM(s.sodium_mg), 3) AS sodium_mg
FROM
    recipe_sodium s
JOIN
    recipes r ON r.recipe_id = s.subrecipe_id
WHERE s.recipe_id = :recipe_id
GROUP BY s.subrecipe_id

ORDER BY sodium_mg DESC;
