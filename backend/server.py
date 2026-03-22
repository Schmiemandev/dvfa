# DVFA Mock Backend Server
# Run (Local): pip install flask && python server.py
# Run (Docker): docker compose up -d
from flask import Flask, jsonify

app = Flask(__name__)

@app.route('/v1/balance', methods=['GET'])
def get_balance():
    response = {
        "status": "success",
        "balance": "$12,450.00",
        "message": "Plaintext traffic intercepted"
    }
    return jsonify(response), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
