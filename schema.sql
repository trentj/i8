-- Enable foreign key support in SQLite
PRAGMA foreign_keys = ON;

-- Table for storing different foods
CREATE TABLE foods (
    food_id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    variant TEXT,
    format TEXT,
    source TEXT
);

-- Table for storing units and sodium content for each food entry
CREATE TABLE food_units (
    food_unit_id INTEGER PRIMARY KEY AUTOINCREMENT,
    food_id INTEGER NOT NULL,
    unit TEXT NOT NULL,
    sodium_mg INTEGER NOT NULL, -- Sodium amount in milligrams
    FOREIGN KEY (food_id) REFERENCES foods(food_id)
);

-- Table for storing recipes with an associated unit
CREATE TABLE recipes (
    recipe_id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    variant TEXT,
    yield REAL NOT NULL, -- recipe yield (e.g. 1)
    unit TEXT NOT NULL -- Unit of measurement for the recipe (e.g., "sandwich")
);

-- Table for storing food ingredients in recipes
CREATE TABLE recipe_ingredients (
    recipe_ingredient_id INTEGER PRIMARY KEY AUTOINCREMENT,
    recipe_id INTEGER NOT NULL,
    food_unit_id INTEGER,
    subrecipe_id INTEGER,
    quantity REAL NOT NULL, -- Quantity of the food unit in the recipe
    FOREIGN KEY (recipe_id) REFERENCES recipes(recipe_id),
    FOREIGN KEY (subrecipe_id) REFERENCES recipes(recipe_id),
    FOREIGN KEY (food_unit_id) REFERENCES food_units(food_unit_id)
    CHECK (food_unit_id IS NOT NULL OR subrecipe_id IS NOT NULL)
);

-- Table for storing logbook entries
CREATE TABLE logbook (
    logbook_id INTEGER PRIMARY KEY AUTOINCREMENT,
    date DATE NOT NULL,
    food_unit_id INTEGER,
    recipe_id INTEGER,
    quantity REAL NOT NULL, -- Quantity of food or recipe consumed
    FOREIGN KEY (food_unit_id) REFERENCES food_units(food_unit_id),
    FOREIGN KEY (recipe_id) REFERENCES recipes(recipe_id),
    CHECK (food_unit_id IS NOT NULL OR recipe_id IS NOT NULL)
);
