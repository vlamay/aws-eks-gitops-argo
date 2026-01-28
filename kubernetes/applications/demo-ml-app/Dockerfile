FROM python:3.9-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY train_model.py .
COPY serve_model.py .

# Create models directory
RUN mkdir -p models

# Environment variables
ENV MODEL_DIR=models

# Default command
CMD ["python", "serve_model.py"]
