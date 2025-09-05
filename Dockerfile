# Multi-stage build for smaller images
FROM python:3.11-slim AS builder
WORKDIR /app
ENV PYTHONDONTWRITEBYTECODE=1     PYTHONUNBUFFERED=1

RUN apt-get update && apt-get install -y --no-install-recommends gcc build-essential     && rm -rf /var/lib/apt/lists/*

COPY app/requirements.txt .
RUN pip install --upgrade pip
RUN pip install --prefix=/install -r requirements.txt

FROM python:3.11-slim
WORKDIR /app
COPY --from=builder /install /usr/local
COPY app/ .

# create non-root user
RUN groupadd --gid 1000 appgroup     && useradd --uid 1000 --gid appgroup --shell /bin/bash --create-home appuser     && chown -R appuser:appgroup /app

USER appuser

EXPOSE 8080
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]
