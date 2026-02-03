# Inception – User Documentation

## Overview

This project deploys a WordPress website using Docker Compose.
It includes Nginx with HTTPS, WordPress, and MariaDB.

All services are started automatically with a single command.

---

## Requirements

- Docker
- Docker Compose
- Linux or Linux-based VM
- OpenSSL available in Docker images

---

## Setup Instructions

### 1. Clone the repository

```bash
git clone <repository_url>
cd inception
```

### 2. Create secrets

Create a `secrets` directory at the project root:

```bash
mkdir secrets
```

Create the following files:
```bash
echo "root_password" > secrets/db_root_password.txt
echo "db_password" > secrets/db_password.txt
echo "admin_password" > secrets/wp_admin_password.txt
echo "user_password" > secrets/wp_user_password.txt
```

Set permissions:
```bash
chmod 600 secrets/*.txt
```

### 3. Configure environment variables

Edit the `.env` file and set values as needed.

Required variables:
```bash
- DOMAIN_NAME
- MYSQL_DATABASE
- MYSQL_USER
- WP_TITLE
- WP_ADMIN_USER
- WP_ADMIN_EMAIL
- WP_USER
- WP_USER_EMAIL
```

### 4. Start the services
```bash
make up
```
Docker Compose will:
```bash
- Build images
- Create containers
- Initialize the database
- Install WordPress automatically
```

## Accessing the Website
Open a browser and go to:
```bash
https://<DOMAIN_NAME>
```
Since a self-signed certificate is used, the browser may show a security warning.

## Managing the Project
Stop containers
```bash
make down
```

Stop and remove containers, images, and volumes
```bash
make fclean
```
## Data Persistence
- WordPress files and database data are persistent
- Data remains even after restarting containers
- Running `make fclean` removes all stored data

## Notes
- Do not use `admin` or similar words for the WordPress admin username
- Secrets must exist before running `make up`
- HTTPS is always enforced

## Troubleshooting
- Missing secrets will prevent container startup
- If database initialization fails, remove volumes and restart
- Check logs with:
```bash
docker compose logs
```