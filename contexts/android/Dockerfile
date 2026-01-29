ARG BASE_IMAGE=codex-sandbox-base:latest
FROM ${BASE_IMAGE}

USER root
RUN apt-get update \
  && apt-get install -y openjdk-17-jdk \
  && rm -rf /var/lib/apt/lists/*
RUN mkdir -p /opt/tools \
  && chown -R sandbox:sandbox /opt/tools

# Install toolset (managed via volumes/tools/android)
WORKDIR /opt/tools
COPY --chown=sandbox:sandbox volumes/tools/android/package.json volumes/tools/android/package-lock.json ./
USER sandbox
RUN npm install --omit=dev
