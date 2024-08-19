WITH RECURSIVE recipe_sodium AS (
    -- Base case: Direct food unit ingredients in the recipe
    SELECT
        rf.recipe_id,
        rf.recipe_ingredient_id,
        rf.quantity * u.sodium_mg AS sodium_mg
    FROM
        recipe_ingredients rf
    JOIN
        food_units u ON rf.food_unit_id = u.food_unit_id

    UNION ALL

    -- Recursive case: Ingredients that are sub-recipes
    SELECT
        rf.recipe_id,
        rf.recipe_ingredient_id,
        rf.quantity * rs.sodium_mg / r.yield AS sodium_mg
    FROM
        recipe_ingredients rf
    JOIN
        recipe_sodium rs ON rf.subrecipe_id = rs.recipe_id
    JOIN
        recipes r ON rf.subrecipe_id = r.recipe_id
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
),
-- Calculate total sodium per day
item_sodium AS (
    SELECT
        NULL,
        f.name,
        l.quantity,
        u.unit,
        ROUND(l.quantity * u.sodium_mg, 3) AS total_sodium_mg
    FROM
        logbook l
    JOIN
        food_units u ON l.food_unit_id = u.food_unit_id
    JOIN
        foods f ON u.food_id = f.food_id
    WHERE
        l.date = :isodate

    UNION ALL

    SELECT
        rt.recipe_id,
        r.name,
        l.quantity,
        r.unit,
        ROUND(l.quantity * rt.total_sodium_mg / r.yield, 3) AS total_sodium_mg
    FROM
        logbook l
    JOIN
        recipe_totals rt ON l.recipe_id = rt.recipe_id
    JOIN
        recipes r ON rt.recipe_id = r.recipe_id
    WHERE
        l.date = :isodate
    ORDER BY
        total_sodium_mg DESC
)
SELECT * FROM item_sodium

UNION ALL

SELECT
    NULL,
    "Total",
    NULL,
    "",
    ROUND(SUM(item_sodium.total_sodium_mg), 3)
FROM item_sodium;