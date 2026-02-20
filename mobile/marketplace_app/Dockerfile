FROM ubuntu:22.04

# Prerequisites
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    openjdk-17-jdk \
    wget \
    clang \
    cmake \
    ninja-build \
    pkg-config \
    libgtk-3-dev \
    && rm -rf /var/lib/apt/lists/*

# Set up new user
USER root

# Android SDK
ENV ANDROID_SDK_ROOT /opt/android-sdk
ENV PATH ${PATH}:${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:${ANDROID_SDK_ROOT}/platform-tools

RUN mkdir -p ${ANDROID_SDK_ROOT}/cmdline-tools

# Download Android SDK Command Line Tools
# Check https://developer.android.com/studio#command-tools for latest version
RUN wget -q https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip -O android_tools.zip \
    && unzip -q android_tools.zip -d ${ANDROID_SDK_ROOT}/cmdline-tools \
    && mv ${ANDROID_SDK_ROOT}/cmdline-tools/cmdline-tools ${ANDROID_SDK_ROOT}/cmdline-tools/latest \
    && rm android_tools.zip

# Accept licenses
RUN yes | sdkmanager --licenses

# Install Android SDK components
# Adjust android version as needed (34 is Android 14)
RUN sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"

# Flutter SDK
ENV FLUTTER_ROOT /opt/flutter
ENV PATH ${PATH}:${FLUTTER_ROOT}/bin

# Download Flutter SDK
RUN git clone https://github.com/flutter/flutter.git ${FLUTTER_ROOT}
RUN flutter config --no-analytics
RUN flutter doctor

WORKDIR /app
# Copy the app code to the container
COPY . .

# Check dependencies
RUN flutter pub get

# Build APK (default command, can be overridden)
CMD ["flutter", "build", "apk", "--release"]
