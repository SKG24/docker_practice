# syntax=docker/dockerfile:1.7
#this is used to specify the version of dockerfile
#-----------------------------------------
# First : Standard Ubuntu 
#--------------------------------------------------
FROM ubuntu:24.04 AS ubuntu-fat
# fat is standard -> heavy -> full linux distribution -> pre-installed packages
# slim -> lightweight distribution

# Reduce interactive prompts in apt
ENV DEBIAN_FRONTEND=noninteractive

# Multiple RUN layers
RUN apt-get update
RUN apt-get install -y --no-install-recommends python3 python3-pip python3-venv ca-certificates curl
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/*

# Create a user (separate RUN -> extra layer)
RUN useradd -m -u 10001 appuser

# Set working directory
WORKDIR /app

# Copy requirements separately to leverage Docker layer caching
COPY requirements.txt .

# Install Python deps (separate RUN -> extra layer)
RUN python3 -m pip install --no-cache-dir --upgrade pip && \
    python3 -m pip install --no-cache-dir -r requirements.txt

# Copy app source (another layer)
COPY . .

# Switch to non-root user
USER appuser

EXPOSE 8000
CMD ["gunicorn", "-b", "0.0.0.0:8000", "app:app"]


#---------------------------------------------
# Second : Alpine Best Practices 
#--------------------------------------------------
FROM python:3.12-alpine AS alpine-slim

# Build-time args
ARG APP_HOME=/app
ARG VENV_PATH=/venv
ARG USER_ID=10001
ARG GROUP_ID=10001
ARG PORT=8000

# could also parameterize Python version if want to switch base dynamically:
# ARG PYTHON_VERSION=3.12

# Runtime environment (persists in final image)
# Promote selected ARGs to ENV where appropriate
ENV APP_HOME="${APP_HOME}" \
    PATH="${VENV_PATH}/bin:${PATH}" \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PORT="${PORT}"


WORKDIR ${APP_HOME}

# Create non-root user, venv, and prep build deps in a single RUN
RUN set -eux; \
    addgroup -S -g "${GROUP_ID}" app && adduser -S -G app -u "${USER_ID}" app; \
    python -m venv "${VENV_PATH}"; \
    apk add --no-cache --virtual .build-deps build-base

# Copy requirements first for better caching
COPY requirements.txt ./

# Install Python deps and remove build deps in the same layer
RUN set -eux; \
    pip install --upgrade pip; \
    pip install -r requirements.txt; \
    apk del .build-deps

# Copy the rest of the app
COPY . .

# Drop privileges
USER app

EXPOSE ${PORT}
CMD ["sh", "-c", "gunicorn -b 0.0.0.0:${PORT} app:app"]
