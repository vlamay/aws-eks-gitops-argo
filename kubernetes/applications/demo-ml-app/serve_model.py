from flask import Flask, request, jsonify
import joblib
import numpy as np
import os

app = Flask(__name__)
MODEL_DIR = os.environ.get('MODEL_DIR', 'models')
MODEL_PATH = os.path.join(MODEL_DIR, "iris_model.pkl")

# Load model
try:
    if os.path.exists(MODEL_PATH):
        model = joblib.load(MODEL_PATH)
        print(f"Model loaded from {MODEL_PATH}")
    else:
        print("Model not found. Please train first.")
        model = None
except Exception as e:
    print(f"Error loading model: {e}")
    model = None

@app.route('/predict', methods=['POST'])
def predict():
    if not model:
        return jsonify({'error': 'Model not loaded'}), 503
    
    try:
        data = request.get_json(force=True)
        features = np.array(data['features']).reshape(1, -1)
        prediction = model.predict(features)
        return jsonify({'prediction': int(prediction[0])})
    except Exception as e:
        return jsonify({'error': str(e)}), 400

@app.route('/health', methods=['GET'])
def health():
    return jsonify({'status': 'healthy', 'model_loaded': model is not None})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
