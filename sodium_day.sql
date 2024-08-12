WITH food_sodium AS (
    -- Calculate total sodium consumed from individual food units
    SELECT
        l.date,
        SUM(fu.sodium_mg * l.quantity) AS total_sodium
    FROM
        logbook l
    JOIN
        food_units fu ON l.food_unit_id = fu.food_unit_id
    WHERE
        l.food_unit_id IS NOT NULL
    GROUP BY
        l.date
),
recipe_sodium AS (
    -- Calculate total sodium consumed from recipes
    SELECT
        l.date,
        SUM(
            ri.quantity * fu.sodium_mg
        ) AS total_sodium
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
        l.date
),
combined_sodium AS (
    -- Combine sodium from both food units and recipes
    SELECT
        date,
        SUM(total_sodium) AS total_sodium
    FROM (
        SELECT date, total_sodium FROM food_sodium
        UNION ALL
        SELECT date, total_sodium FROM recipe_sodium
    )
    GROUP BY date
)
-- Final output
SELECT
    date,
    total_sodium
FROM
    combined_sodium
ORDER BY
    date;
