-- Get the amount of sodium contributed to a recipe by each ingredient.
-- First, filter down to only the ingredients contained in this recipe, root to leaf.
WITH RECURSIVE tree AS (
    SELECT
        NULL AS food_unit_id,
        :recipe_id AS subrecipe_id

    UNION ALL

    SELECT
        child.food_unit_id,
        child.subrecipe_id
    FROM
        recipe_ingredients child
    JOIN
        tree parent ON child.recipe_id = parent.subrecipe_id
),
-- Next, calculate all the sodium contributed to each recipe by each ingredient...
unit_sodium AS (
    SELECT
        i.recipe_id,
        i.food_unit_id,
        i.subrecipe_id,
        ff.name AS item_name,
        f.unit AS unit_name,
        i.quantity,
        f.sodium_mg * i.quantity AS unit_sodium_mg
    FROM
        tree
    JOIN
        recipe_ingredients i ON i.food_unit_id = tree.food_unit_id
    JOIN
        food_units f ON f.food_unit_id = i.food_unit_id
    JOIN
        foods ff ON ff.food_id = f.food_id

    UNION ALL

    SELECT
        i.recipe_id,
        i.food_unit_id,
        i.subrecipe_id,
        rr.name AS item_name,
        rr.unit AS unit_name,
        i.quantity,
        s.unit_sodium_mg / rr.yield * i.quantity AS unit_sodium_mg
    FROM
        tree
    JOIN
        recipe_ingredients i ON i.subrecipe_id = tree.subrecipe_id
    JOIN
        unit_sodium s ON s.recipe_id = i.subrecipe_id
    JOIN
        recipes rr ON rr.recipe_id = i.subrecipe_id
),
total_sodium AS (
    SELECT
        subrecipe_id,
        item_name,
        unit_name,
        quantity,
        SUM(unit_sodium_mg) AS sodium_mg
    FROM
        unit_sodium
    WHERE
        recipe_id = :recipe_id
    GROUP BY
        subrecipe_id, food_unit_id
    ORDER BY sodium_mg DESC
)
SELECT
    subrecipe_id,
    item_name,
    quantity,
    unit_name,
    sodium_mg
FROM
    total_sodium

UNION ALL

SELECT
    NULL,
    'Total',
    recipes.yield,
    recipes.unit,
    SUM(sodium_mg)
FROM total_sodium, recipes
WHERE recipes.recipe_id = :recipe_id;