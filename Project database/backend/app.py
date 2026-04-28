from flask import Flask, request, jsonify
from flask_cors import CORS
from dotenv import load_dotenv
import os
import pymysql

load_dotenv()

app = Flask(__name__)
CORS(app)  # Flutter/웹에서 요청 허용 (개발용)

DB_HOST = os.getenv("DB_HOST", "localhost")
DB_USER = os.getenv("DB_USER", "carapp")
DB_PASSWORD = os.getenv("DB_PASSWORD", "")
DB_NAME = os.getenv("DB_NAME", "carclub")

def get_conn():
    return pymysql.connect(
        host=DB_HOST,
        user=DB_USER,
        password=DB_PASSWORD,
        database=DB_NAME,
        cursorclass=pymysql.cursors.DictCursor,
        autocommit=True
    )

@app.get("/health")
def health():
    return {"ok": True}

@app.get("/events")
def list_events():
    conn = get_conn()
    with conn.cursor() as cur:
        cur.execute("""
            SELECT event_id, title, event_time, location, created_by
            FROM Events
            ORDER BY event_time DESC
        """)
        rows = cur.fetchall()
    conn.close()
    return jsonify(rows), 200

@app.post("/events")
def create_event():
    data = request.get_json(force=True)

    title = data.get("title")
    event_time = data.get("event_time")  # "YYYY-MM-DD HH:MM:SS"
    location = data.get("location")
    created_by = data.get("created_by", 1)

    if not title or not event_time or not location:
        return {"error": "missing fields: title/event_time/location"}, 400

    conn = get_conn()
    with conn.cursor() as cur:
        cur.execute(
            "INSERT INTO Events(title, event_time, location, created_by) VALUES (%s,%s,%s,%s)",
            (title, event_time, location, created_by)
        )
        new_id = cur.lastrowid
    conn.close()

    return {"event_id": new_id}, 201

@app.put("/events/<int:event_id>")
def update_event(event_id):
    data = request.get_json(force=True)

    title = data.get("title")
    event_time = data.get("event_time")
    location = data.get("location")

    if not title or not event_time or not location:
        return {"error": "missing fields: title/event_time/location"}, 400

    conn = get_conn()
    with conn.cursor() as cur:
        cur.execute(
            "UPDATE Events SET title=%s, event_time=%s, location=%s WHERE event_id=%s",
            (title, event_time, location, event_id)
        )
        affected = cur.rowcount
    conn.close()

    if affected == 0:
        return {"error": "event not found"}, 404
    return {"ok": True}, 200

@app.delete("/events/<int:event_id>")
def delete_event(event_id):
    conn = get_conn()
    with conn.cursor() as cur:
        cur.execute("DELETE FROM Events WHERE event_id=%s", (event_id,))
        affected = cur.rowcount
    conn.close()

    if affected == 0:
        return {"error": "event not found"}, 404
    return {"ok": True}, 200

if __name__ == "__main__":
    host = os.getenv("FLASK_HOST", "127.0.0.1")
    port = int(os.getenv("FLASK_PORT", "5000"))
    app.run(host=host, port=port, debug=True)
