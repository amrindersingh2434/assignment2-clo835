from flask import Flask, render_template, request
from pymysql import connections
import os
import random
import argparse

app = Flask(__name__)

DBHOST = os.environ.get("DBHOST", "mysql")
DBUSER = os.environ.get("DBUSER", "root")
DBPWD = os.environ.get("DBPWD", "password")
DATABASE = os.environ.get("DATABASE", "employees")
DBPORT = int(os.environ.get("DBPORT", 3306))

COLOR_FROM_ENV = os.environ.get("APP_COLOR")

color_codes = {
    "red": "#e74c3c",
    "green": "#16a085",
    "blue": "#89CFF0",
    "blue2": "#30336b",
    "pink": "#f4c2c2",
    "darkblue": "#130f40",
    "lime": "#C1FF9C",
}

SUPPORTED_COLORS = ",".join(color_codes.keys())
COLOR = random.choice(list(color_codes.keys()))

try:
    db_conn = connections.Connection(
        host=DBHOST,
        port=DBPORT,
        user=DBUSER,
        password=DBPWD,
        db=DATABASE
    )
except Exception as e:
    print("Database connection failed:", e)
    db_conn = None


@app.route("/")
def home():
    return render_template("addemp.html", color=color_codes[COLOR])


@app.route("/about")
def about():
    return render_template("about.html", color=color_codes[COLOR])


@app.route("/addemp", methods=["POST"])
def add_emp():
    cursor = db_conn.cursor()
    try:
        cursor.execute(
            "INSERT INTO employee VALUES (%s,%s,%s,%s,%s)",
            (
                request.form["emp_id"],
                request.form["first_name"],
                request.form["last_name"],
                request.form["primary_skill"],
                request.form["location"],
            ),
        )
        db_conn.commit()
    finally:
        cursor.close()

    return render_template("addempoutput.html",
                           name=request.form["first_name"],
                           color=color_codes[COLOR])


@app.route("/getemp")
def get_emp():
    return render_template("getemp.html", color=color_codes[COLOR])


@app.route("/fetchdata", methods=["POST"])
def fetch_data():
    cursor = db_conn.cursor()
    cursor.execute(
        "SELECT emp_id, first_name, last_name, primary_skill, location FROM employee WHERE emp_id=%s",
        (request.form["emp_id"],)
    )
    result = cursor.fetchone()
    cursor.close()

    if not result:
        return "Employee not found", 404

    return render_template(
        "getempoutput.html",
        id=result[0],
        fname=result[1],
        lname=result[2],
        interest=result[3],
        location=result[4],
        color=color_codes[COLOR],
    )


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--color")
    args = parser.parse_args()

    if args.color:
        COLOR = args.color
    elif COLOR_FROM_ENV:
        COLOR = COLOR_FROM_ENV

    if COLOR not in color_codes:
        print(f"Unsupported color {COLOR}. Use one of {SUPPORTED_COLORS}")
        exit(1)

    app.run(host="0.0.0.0", port=8080)
