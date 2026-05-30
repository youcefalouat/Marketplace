# Docker Setup Guide

This project supports Docker for both the Backend API and the Mobile App build environment.

## Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) installed on your machine.

## 1. Backend & Database (Docker Compose)

To run the Backend API and SQL Server database together:

1.  Open a terminal in the project root (where `docker-compose.yml` is located).
2.  Create your local environment file:
    ```bash
    cp .env.example .env
    ```
3.  Update `.env` with your database password, JWT secret, and optional Twilio / Azure values.
4.  Run the following command:
    ```bash
    docker compose up --build
    ```
5.  The services will start:
    - **Database**: Port from `MARKETPLACE_DB_PORT`
    - **API**: Port from `MARKETPLACE_API_PORT`

### Connection Strings
The `docker-compose.yml` automatically configures the API to connect to the SQL Server container through environment variables. No manual change in `appsettings.json` is needed when you move to another machine or VPS.

### Local image storage without Azure
If `AZURE_STORAGE_CONNECTION_STRING` is empty, uploaded annonce images are stored locally under:

```bash
backend/MarketplaceApi/wwwroot/images/YYYY/MM/
```

Thumbnails are stored in the matching `thumbs` subfolder. In Docker, these folders are bind-mounted to `/app/wwwroot/images` and `/app/wwwroot/uploads` inside the API container so uploads remain visible on the VPS and survive container rebuilds.

On a VPS deployment from the project root, you can check uploaded files with:

```bash
ls -lah backend/MarketplaceApi/wwwroot/images
docker exec -it marketplace-api ls -lah /app/wwwroot/images
docker logs marketplace-api --tail 100
```

If the API was already running without these bind mounts, copy any existing container-only uploads before recreating the container:

```bash
mkdir -p backend/MarketplaceApi/wwwroot
docker cp marketplace-api:/app/wwwroot/images backend/MarketplaceApi/wwwroot/
docker cp marketplace-api:/app/wwwroot/uploads backend/MarketplaceApi/wwwroot/ 2>/dev/null || true
```

Then recreate the API container:

```bash
docker compose up -d --build marketplace-api
```

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
