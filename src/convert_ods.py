import argparse
import pathlib
import shlex

from python_calamine import CalamineWorkbook

if __name__ == "__main__":
    parser = argparse.ArgumentParser("convert_ods")
    parser.add_argument("filename", type=pathlib.Path)
    args = parser.parse_args()
    wb = CalamineWorkbook.from_path(args.filename)
    for name, unit, sodium in wb.get_sheet_by_name("Ingredients").iter_rows():
        if unit.startswith("1 "):
            unit = unit[2:]
        if unit == "n/a":
            unit = "any"
        print("food", shlex.quote(name), shlex.quote(unit), sodium)

    state = None
    for name, ingredient, unit, quantity, _sodium in wb.get_sheet_by_name("Recipes").iter_rows():
        if not ingredient: break
        if name:
            state = name
            print("recipe", '\\')
        else:
            name = state
        if ingredient == "total":
            if unit.startswith("1 "):
                unit = unit[2:]
            print("   ", shlex.quote(name), shlex.quote(unit))
        else:
            print("    -a", shlex.quote(ingredient), quantity, '\\')

    last_date = None
    for date, name, _unit, number, _sodium in wb.get_sheet_by_name("Sodium").iter_rows():
        if not name:
            break
        if not date:
            date = last_date
        if name.startswith("Daily total"): continue
        print("log", "-d", date, name, number)
