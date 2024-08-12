import argparse
import pathlib
import shlex
import sys

from python_calamine import CalamineWorkbook

if __name__ == "__main__":
    parser = argparse.ArgumentParser("convert_ods")
    parser.add_argument("filename", type=pathlib.Path)
    parser.add_argument("-o", "--output", type=pathlib.Path)
    args = parser.parse_args()

    if args.output:
        out = open(args.output, "w")
    else:
        out = sys.stdout

    wb = CalamineWorkbook.from_path(args.filename)
    for name, unit, sodium in wb.get_sheet_by_name("Ingredients").iter_rows():
        if unit.startswith("1 "):
            unit = unit[2:]
        if unit == "n/a":
            unit = "any"
        print("food", shlex.quote(name), shlex.quote(unit), sodium, file=out)

    state = None
    for name, ingredient, unit, quantity, _sodium in wb.get_sheet_by_name("Recipes").iter_rows():
        if not ingredient: break
        if name:
            state = name
            print("recipe", '\\', file=out)
        else:
            name = state
        if ingredient == "total":
            if unit.startswith("1 "):
                unit = unit[2:]
            print("   ", shlex.quote(name), shlex.quote(unit), file=out)
        else:
            print("    -a", shlex.quote(ingredient), quantity, '\\', file=out)

    last_date = None
    for date, name, _unit, number, _sodium in wb.get_sheet_by_name("Sodium").iter_rows():
        if not name:
            break
        if date:
            last_date = date
        else:
            date = last_date
        if name.startswith("Daily total"): continue
        print("log", "-d", date, shlex.quote(name), number, file=out)
