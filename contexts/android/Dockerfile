ARG BASE_IMAGE=codex-sandbox-base:latest
FROM ${BASE_IMAGE}

ARG ANDROID_CMDLINE_TOOLS_ZIP=commandlinetools-linux-14742923_latest.zip
ARG ANDROID_CMDLINE_TOOLS_SHA256=04453066b540409d975c676d781da1477479dde3761310f1a7eb92a1dfb15af7
ARG ANDROID_SDK_TOOLS_ARM64_URL=https://github.com/lzhiyong/android-sdk-tools/releases/download/35.0.2/android-sdk-tools-static-aarch64.zip
ARG ANDROID_SDK_TOOLS_ARM64_SHA256=db1cea2c4454d5f9c5a802646b2d1cf560b4ee7badbe23e51ab8e1881bb50fc2
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
  && if [ "$(uname -m)" = "aarch64" ]; then \
    curl -fsSLo /tmp/android-sdk-tools-static-aarch64.zip "${ANDROID_SDK_TOOLS_ARM64_URL}" \
      && echo "${ANDROID_SDK_TOOLS_ARM64_SHA256}  /tmp/android-sdk-tools-static-aarch64.zip" | sha256sum -c - \
      && mkdir -p /tmp/android-sdk-tools-arm64 \
      && unzip -q /tmp/android-sdk-tools-static-aarch64.zip -d /tmp/android-sdk-tools-arm64 \
      && install -m 0755 /tmp/android-sdk-tools-arm64/build-tools/aapt /opt/android-sdk/build-tools/${ANDROID_BUILD_TOOLS_VERSION}/aapt \
      && install -m 0755 /tmp/android-sdk-tools-arm64/build-tools/aapt2 /opt/android-sdk/build-tools/${ANDROID_BUILD_TOOLS_VERSION}/aapt2 \
      && install -m 0755 /tmp/android-sdk-tools-arm64/build-tools/aidl /opt/android-sdk/build-tools/${ANDROID_BUILD_TOOLS_VERSION}/aidl \
      && install -m 0755 /tmp/android-sdk-tools-arm64/build-tools/dexdump /opt/android-sdk/build-tools/${ANDROID_BUILD_TOOLS_VERSION}/dexdump \
      && install -m 0755 /tmp/android-sdk-tools-arm64/build-tools/zipalign /opt/android-sdk/build-tools/${ANDROID_BUILD_TOOLS_VERSION}/zipalign \
      && install -m 0755 /tmp/android-sdk-tools-arm64/build-tools/split-select /opt/android-sdk/build-tools/${ANDROID_BUILD_TOOLS_VERSION}/split-select \
      && install -m 0755 /tmp/android-sdk-tools-arm64/platform-tools/adb /opt/android-sdk/platform-tools/adb \
      && install -m 0755 /tmp/android-sdk-tools-arm64/platform-tools/fastboot /opt/android-sdk/platform-tools/fastboot \
      && rm -rf /tmp/android-sdk-tools-arm64 /tmp/android-sdk-tools-static-aarch64.zip; \
  fi \
  && chown -R sandbox:sandbox /opt/android-sdk

# Install toolset (managed via volumes/tools/android)
WORKDIR /opt/tools
COPY --chown=sandbox:sandbox volumes/tools/android/package.json volumes/tools/android/package-lock.json ./
USER sandbox
RUN npm install --omit=dev
