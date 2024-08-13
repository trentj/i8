from flask import Flask, render_template
import sqlite3

def get_connection() -> sqlite3.Connection:
    CONN = sqlite3.connect("food.db")
    return CONN

app = Flask(__name__)

@app.route("/")
def index():
    db = get_connection()
    with open("../top10.sql") as fp:
        top_10 = [{'name': n, 'quantity': q, 'recipe_id': r, 'sodium_mg': s} for r, q, n, s in db.execute(fp.read())]
    return render_template("items.html", items=top_10, title="Summary")


@app.route("/recipes")
def recipes():
    db = get_connection()
    with open("../recipes.sql") as fp:
        recipes = [
            {'name': n, 'sodium_mg': s, 'quantity': y, 'recipe_id': r} for r, n, y, s in
            db.execute(fp.read())]
    return render_template("items.html", title="Recipes", items=recipes)


@app.route("/recipe/<id>")
def recipe(id):
    db = get_connection()
    (recipe_name,), = db.execute("SELECT name FROM recipes WHERE recipe_id = ?", (id,))
    with open("../recipe_sodium.sql") as fp:
        recipe = [
            {'name': n, 'sodium_mg': s, 'quantity': q, 'unit': u, 'recipe_id': r} for r, n, q, u, s in
            db.execute(fp.read(), {'recipe_id': int(id)})]
    return render_template("items.html", title=recipe_name, items=recipe)
