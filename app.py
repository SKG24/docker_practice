from flask import Flask, jsonify

app = Flask(__name__)

@app.get("/")
def index():
    return jsonify(message="Hello from Flask in Docker!")

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8000)