WITH food_sodium AS (
    -- Calculate total sodium consumed from individual food units
    SELECT
        fu.food_unit_id,
        f.name AS item_name,
        fu.unit,
        SUM(fu.sodium_mg * l.quantity) AS total_sodium
    FROM
        logbook l
    JOIN
        food_units fu ON l.food_unit_id = fu.food_unit_id
    JOIN
        foods f ON fu.food_id = f.food_id
    WHERE
        l.food_unit_id IS NOT NULL
    GROUP BY
        fu.food_unit_id, f.name, fu.unit
),
recipe_sodium AS (
    -- Calculate total sodium consumed from recipes
    SELECT
        r.recipe_id AS food_unit_id,
        r.name AS item_name,
        r.unit,
        SUM(ri.quantity * fu.sodium_mg) AS total_sodium
    FROM
        logbook l
    JOIN
        recipes r ON l.recipe_id = r.recipe_id
    JOIN
        recipe_ingredients ri ON r.recipe_id = ri.recipe_id
    JOIN
        food_units fu ON ri.food_unit_id = fu.food_unit_id
    WHERE
        l.recipe_id IS NOT NULL
    GROUP BY
        r.recipe_id, r.name, r.unit
),
combined_sodium AS (
    -- Combine sodium from both food units and recipes
    SELECT
        item_name,
        unit,
        SUM(total_sodium) AS total_sodium
    FROM (
        SELECT item_name, unit, total_sodium FROM food_sodium
        UNION ALL
        SELECT item_name, unit, total_sodium FROM recipe_sodium
    )
    GROUP BY item_name, unit
)
-- Final output
SELECT
    item_name,
    unit,
    total_sodium
FROM
    combined_sodium
ORDER BY
    total_sodium DESC
LIMIT 10;
