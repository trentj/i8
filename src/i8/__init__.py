import argparse
import datetime
import pathlib
import shlex
import sqlite3


class ItemNotFound(Exception):
    pass


class I8:
    def __init__(self, db_path: pathlib.Path = "food.db"):
        self.db = sqlite3.connect(db_path)

    def _food_parser(self, parser: argparse.ArgumentParser) -> argparse.ArgumentParser:
        parser.add_argument("name", type=str, help="Name of food item")
        parser.add_argument("-v", "--variant", "--variety", type=str, help="Food variety or subtype")
        parser.add_argument("-f", "--format", type=str, help="Food form factor (e.g. canned)")
        parser.add_argument("-s", "--source", type=str, help="Source or brand")
        parser.add_argument("-n", "--number", type=float, default=1, help="Number of units per serving")
        parser.add_argument("unit", type=str, help="Unit of serving measurement")
        parser.add_argument("sodium", type=float, help="Sodium content (mg)")
        parser.set_defaults(fn=self.food)
        return parser

    def food(self, args: argparse.Namespace):
        cur = self.db.cursor()
        res = cur.execute("""
        SELECT food_id FROM foods
        WHERE
            name = ? AND
            variant IS IFNULL(?, variant) AND
            format IS IFNULL(?, format) AND
            source IS IFNULL(?, source)
        """, (args.name, args.variant, args.format, args.source))
        for (food_id,) in res:
            break
        else:
            cur.execute("INSERT INTO foods (name, variant, format, source)"
                        "VALUES (?, ?, ?, ?)",
                        (args.name, args.variant, args.format, args.source))
            food_id = cur.lastrowid
        cur.execute("INSERT INTO food_units (food_id, unit, sodium_mg) VALUES (?, ?, ?)",
                    (food_id, args.unit, args.sodium / args.number))
        self.db.commit()

    def _log_parser(self, parser: argparse.ArgumentParser):
        parser.add_argument("item", type=str, help="Name of food or recipe eaten")
        parser.add_argument("quantity", type=float, default=1, help="Number of units per serving")
        parser.add_argument("-d", "--date", type=datetime.date.fromisoformat, help="Date to enter")
        parser.add_argument("-v", "--variant", "--variety", type=str, help="Food or recipe variant")
        parser.set_defaults(fn=self.log)
        return parser

    @staticmethod
    def _food_or_recipe(cur: sqlite3.Cursor, itemname: str, variant: str | None = None) -> (int | None, int | None, str):
            # look up food or recipe unit
        food_units = cur.execute("""
        SELECT itemname, food_unit_id, recipe_id, unit FROM (
            SELECT foods.name AS itemname, food_unit_id, NULL AS recipe_id, food_units.unit AS unit, variant
            FROM food_units JOIN foods ON food_units.food_id = foods.food_id
          UNION
            SELECT recipes.name AS itemname, NULL AS food_unit_id, recipe_id, recipes.unit AS unit, variant
            FROM recipes
        ) WHERE itemname = ? AND variant IS IFNULL(?, variant)""", (itemname, variant))
        for itemname, food_unit_id, recipe_id, itemunit in food_units:
            break
        else:
            raise ItemNotFound(f"No such food or recipe {itemname}")
        return food_unit_id, recipe_id, f"{itemunit} {itemname}"

    def log(self, args: argparse.Namespace):
        cur = self.db.cursor()
        food_unit_id, recipe_id, item_name = self._food_or_recipe(cur, args.item, args.variant)
        cur.execute("INSERT INTO logbook (date, food_unit_id, recipe_id, quantity) VALUES (IFNULL(?, DATE()), ?, ?, ?)",
                    (args.date and args.date.isoformat(), food_unit_id, recipe_id, args.quantity))
        print(f"[{cur.lastrowid}] Recorded {args.quantity} {item_name} {args.date or 'today'}")
        self.db.commit()

    def _foods_parser(self, parser: argparse.ArgumentParser):
        parser.add_argument("pattern", type=str, nargs="?", default="")
        parser.set_defaults(fn=self.foods)
        return parser

    def foods(self, args: argparse.Namespace):
        cur = self.db.cursor()
        res = cur.execute("""
        SELECT CONCAT(
            name, ':',
            IFNULL(variant, ''), ':',
            IFNULL(format, ''), ':',
            IFNULL(source, ''), ':',
            food_units.unit)
        FROM foods JOIN food_units ON foods.food_id = food_units.food_id""")
        for key, in res:
            print(f"{shlex.quote(key)}")
        res = cur.execute("SELECT CONCAT(name, ':', IFNULL(variant, ''), ':', unit) FROM recipes")
        for key, in res:
            print(f"{shlex.quote(key)}")

    def _fixunits_parser(self, parser: argparse.ArgumentParser) -> argparse.ArgumentParser:
        parser.add_argument("food", type=str, help="Name of food")
        parser.add_argument("old_unit", type=str)
        parser.add_argument("-n", "--number", type=float, default=1.0, help="Number of old units in the new unit")
        parser.add_argument("-d", "--denominator", type=float, default=1.0)
        parser.add_argument("new_unit", type=str)
        parser.set_defaults(fn=self.fix_units)
        return parser

    def fix_units(self, args: argparse.Namespace):
        cur = self.db.cursor()
        food_id, _recipe_id, _n = self._food_or_recipe(cur, args.food)
        if food_id is None:
            raise NotImplementedError("fix_units for recipes")
        res = cur.execute("SELECT food_unit_id, sodium_mg FROM food_units WHERE food_id = ? AND unit = ?",
                                        (food_id, args.old_unit,))
        for old_unit_id, sodium_mg in res:
            break
        else:
            raise Exception(f"Not found: {args.old_unit}")
        cur.execute("INSERT INTO food_units (food_id, unit, sodium_mg) VALUES (?, ?, ?)",
                    (food_id, args.new_unit, int(sodium_mg * args.number / args.denominator)))
        new_unit_id = cur.lastrowid
        cur.execute("""
        UPDATE logbook
        SET
            food_unit_id = ?,
            quantity = quantity * ? / ?
        WHERE
            food_unit_id = ?""",
                    (new_unit_id, args.denominator, args.number, old_unit_id))
        cur.execute("""
        UPDATE recipe_ingredients
        SET
            food_unit_id = ?,
            quantity = quantity * ? / ?
        WHERE
            food_unit_id = ?""",
                    (new_unit_id, args.denominator, args.number, old_unit_id))
        cur.execute("DELETE FROM food_units WHERE food_unit_id = ?", (old_unit_id,))
        self.db.commit()

    def _recipe_parser(self, parser: argparse.ArgumentParser) -> argparse.ArgumentParser:
        parser.add_argument("name", type=str, help="Name of recipe")
        parser.add_argument("-v", "--variant", "--variety", type=str, help="Recipe variant")
        # parser.add_argument("-i", "--interactive", action="store_true", help="Run interactively")
        parser.add_argument("-a", "--add_ingredient", nargs=2, action="append", help="Add ingredient")
        # parser.add_argument("-s", "--source", type=str, help="Source or brand")
        parser.add_argument("-n", "--number", type=float, default=1, help="Recipe yield")
        parser.add_argument("unit", type=str, help="Unit of yield")
        parser.set_defaults(fn=self.recipe)
        return parser

    def recipe(self, args: argparse.Namespace):
        cur = self.db.cursor()
        if not args.add_ingredient:
            raise Exception("interactive mode")
        cur.execute("INSERT INTO recipes (name, variant, unit) VALUES (?, ?, ?)",
                    (args.name, args.variant, args.unit))
        recipe_id = cur.lastrowid
        print(f"Created recipe [{recipe_id}] {args.name}, {args.variant} (per {args.unit})")
        try:
            for n, (item, quantity) in enumerate(args.add_ingredient):
                q = float(quantity)
                food_unit_id, subrecipe_id, item_name = self._food_or_recipe(cur, item)
                cur.execute("""
                INSERT INTO recipe_ingredients (recipe_id, food_unit_id, subrecipe_id, quantity)
                VALUES (?, ?, ?, ?)""",
                            (recipe_id, food_unit_id, subrecipe_id, q / args.number))
                print(f"{n + 1:2}. {q} {item_name}")
        except ItemNotFound:
            self.db.rollback()
            raise
        self.db.commit()

    def _read_parser(self, parser: argparse.ArgumentParser) -> argparse.ArgumentParser:
        parser.add_argument("filename", type=pathlib.Path)
        parser.set_defaults(fn=self.read_file)

    def read_file(self, args: argparse.Namespace):
        with open(args.filename) as fp:
            last_line = ""
            for line in fp:
                if line.rstrip().endswith("\\"):
                    last_line += line[:line.rfind("\\")]
                    continue
                else:
                    line = last_line + line
                last_line = ""
                argv = shlex.split(line)
                args = self.get_parser().parse_args(argv)
                args.fn(args)

    def get_parser(self) -> argparse.ArgumentParser:
        parser = argparse.ArgumentParser("i8")
        parsers = parser.add_subparsers()
        self._foods_parser(parsers.add_parser("foods", description="List foods and recipes"))
        self._food_parser(parsers.add_parser("food", description="Add food items to the database"))
        self._log_parser(parsers.add_parser("log", description="Record items eaten"))
        self._recipe_parser(parsers.add_parser("recipe", description="Define a new recipe"))
        self._read_parser(parsers.add_parser("read", description="Read commands from file"))
        self._fixunits_parser(parsers.add_parser("fix_units", description="Fix units"))

        return parser
