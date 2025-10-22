FROM python:3.9-slim

RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Installer kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && chmod +x kubectl \
    && mv kubectl /usr/local/bin/

# Installer les dépendances Python
RUN pip install prometheus-client

COPY k8sgpt-exporter.py /app/k8sgpt-exporter.py

WORKDIR /app

EXPOSE 8080

CMD ["python", "k8sgpt-exporter.py"]
