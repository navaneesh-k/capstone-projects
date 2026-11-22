from flask import Flask

app = Flask(__name__)

@app.route("/")
def home():
    return """
    <h1>Project 8: Docker Application</h1>
    <p>Successfully deployed using Docker!</p>
    <p>Environment: Local Ubuntu VM</p>
    """

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
