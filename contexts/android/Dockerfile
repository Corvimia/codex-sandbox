ARG BASE_IMAGE=codex-sandbox-base:latest
FROM ${BASE_IMAGE}

USER root
RUN apt-get update \
  && apt-get install -y openjdk-17-jdk \
  && rm -rf /var/lib/apt/lists/*
USER sandbox

# Install toolset (managed via volumes/tools/android)
WORKDIR /opt/tools
COPY volumes/tools/android/package.json volumes/tools/android/package-lock.json ./
RUN npm install --omit=dev
