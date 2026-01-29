ARG BASE_IMAGE=codex-sandbox-base:latest
FROM ${BASE_IMAGE}

ARG ANDROID_CMDLINE_TOOLS_ZIP=commandlinetools-linux-14742923_latest.zip
ARG ANDROID_CMDLINE_TOOLS_SHA256=48833c34b761c10cb20bcd16582129395d121b27
ARG ANDROID_BUILD_TOOLS_VERSION=36.0.0
ARG ANDROID_PLATFORM_VERSION=36

ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV ANDROID_HOME=/opt/android-sdk
ENV PATH=$PATH:/opt/android-sdk/platform-tools:/opt/android-sdk/cmdline-tools/latest/bin

USER root
RUN apt-get update \
  && apt-get install -y openjdk-17-jdk curl unzip ca-certificates \
  && rm -rf /var/lib/apt/lists/*
RUN mkdir -p /opt/tools /opt/android-sdk/cmdline-tools \
  && chown -R sandbox:sandbox /opt/tools
RUN curl -fsSLo /tmp/${ANDROID_CMDLINE_TOOLS_ZIP} \
    https://dl.google.com/android/repository/${ANDROID_CMDLINE_TOOLS_ZIP} \
  && echo "${ANDROID_CMDLINE_TOOLS_SHA256}  /tmp/${ANDROID_CMDLINE_TOOLS_ZIP}" | sha256sum -c - \
  && unzip -q /tmp/${ANDROID_CMDLINE_TOOLS_ZIP} -d /opt/android-sdk/cmdline-tools \
  && mv /opt/android-sdk/cmdline-tools/cmdline-tools /opt/android-sdk/cmdline-tools/latest \
  && rm -f /tmp/${ANDROID_CMDLINE_TOOLS_ZIP} \
  && yes | sdkmanager --licenses >/dev/null \
  && sdkmanager \
    "platform-tools" \
    "platforms;android-${ANDROID_PLATFORM_VERSION}" \
    "build-tools;${ANDROID_BUILD_TOOLS_VERSION}" \
  && yes | sdkmanager --licenses >/dev/null \
  && chown -R sandbox:sandbox /opt/android-sdk

# Install toolset (managed via volumes/tools/android)
WORKDIR /opt/tools
COPY --chown=sandbox:sandbox volumes/tools/android/package.json volumes/tools/android/package-lock.json ./
USER sandbox
RUN npm install --omit=dev
