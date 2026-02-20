# Docker Setup Guide

This project supports Docker for both the Backend API and the Mobile App build environment.

## Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) installed on your machine.

## 1. Backend & Database (Docker Compose)

To run the Backend API and SQL Server database together:

1.  Open a terminal in the project root (where `docker-compose.yml` is located).
2.  Run the following command:
    ```bash
    docker-compose up --build
    ```
3.  The services will start:
    - **Database**: Port `1433`
    - **API**: Port `5000` (accessible at `http://localhost:5000/api`)

### Connection Strings
The `docker-compose.yml` automatically configures the API to connect to the SQL Server container. No manual change in `appsettings.json` is needed.

## 2. Mobile App Build Environment

To build the mobile app without installing Flutter/Android SDKs locally, use the provided Dockerfile.

1.  Navigate to the mobile app directory:
    ```bash
    cd mobile/marketplace_app
    ```
2.  Build the Docker image:
    ```bash
    docker build -t marketplace-mobile-build .
    ```
3.  Run the container to build the APK:
    ```bash
    docker run --rm -v "$(pwd):/app" marketplace-mobile-build flutter build apk --release
    ```
    - The built APK will be available in `build/app/outputs/flutter-apk/app-release.apk`.

### Interactive Shell
To access the container shell for running other commands (like `flutter doctor`):
```bash
docker run --rm -it -v "$(pwd):/app" marketplace-mobile-build bash
```
