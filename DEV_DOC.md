# Inception – Developer Documentation

## Project Overview

This project sets up a complete WordPress infrastructure using Docker Compose.
The stack is composed of three isolated services:

- Nginx (reverse proxy with TLS)
- WordPress (PHP-FPM + WP-CLI)
- MariaDB (database)

Each service runs in its own container and communicates through a dedicated Docker bridge network.

The goal of this design is to follow containerization best practices:
one process per container, explicit dependencies, and secure secret management.

---

## Architecture Design

### Services

- **Nginx**
  - Acts as a reverse proxy
  - Terminates TLS (HTTPS only)
  - Forwards PHP requests to the WordPress container via FastCGI

- **WordPress**
  - Runs PHP-FPM 8.2
  - Uses WP-CLI for automated installation and configuration
  - Connects to MariaDB through the internal Docker network

- **MariaDB**
  - Provides the database backend
  - Initializes database and users at first startup
  - Persists data through a bind-mounted volume

---

## Network Design

A custom Docker bridge network named `inception` is used.

Reasons:
- Containers can resolve each other by service name
- Services are isolated from the host network
- No database or PHP port is exposed to the host

Only Nginx exposes port `443`.

---

## Volume and Data Persistence

Two persistent volumes are defined:

- `mariadb_data` → `/var/lib/mysql`
- `wordpress_files` → `/var/www/html`

These volumes are bind-mounted to the host filesystem.
This ensures data persistence even if containers are stopped or rebuilt.

---

## Secrets Management

Sensitive data is never stored in `.env` or hardcoded.

Docker secrets are used for:
- MariaDB root password
- MariaDB user password
- WordPress admin password
- WordPress user password

Each entrypoint script supports both:
- `VAR=value`
- `VAR_FILE=/run/secrets/...`

This is handled by a shared `read_secret` function.

---

## MariaDB Container Design

### Dockerfile

- Uses Alpine Linux for minimal footprint
- Installs `mariadb` and `mariadb-client`
- Runs as non-root user (`mysql`)

### Entrypoint Logic

On first startup:
1. Initialize database directory
2. Start MariaDB temporarily without networking
3. Create database and user
4. Set root password
5. Shut down temporary server

On subsequent startups:
- Skip initialization
- Start MariaDB normally

This ensures idempotent behavior.

---

## WordPress Container Design

### Dockerfile

- Uses Alpine Linux
- Installs PHP 8.2, required extensions, and WP-CLI
- PHP-FPM listens on `0.0.0.0:9000`

### Entrypoint Logic

1. Validate required environment variables
2. Download WordPress core if missing
3. Generate `wp-config.php`
4. Wait for MariaDB readiness
5. Install WordPress via WP-CLI
6. Create a non-admin user
7. Start PHP-FPM in foreground mode

This allows full automation with no manual web setup.

---

## Nginx Container Design

### TLS Handling

- Generates a self-signed certificate on first startup
- Certificate is based on `DOMAIN_NAME`
- TLS versions limited to 1.2 and 1.3

### Configuration

- Uses a template file with `envsubst`
- PHP requests are forwarded to `wordpress:9000`
- Static files are served directly

---

## Design Decisions Summary

- One service per container
- No credentials in images or `.env`
- No `latest` tags
- HTTPS enforced
- Persistent data stored outside containers
- Automated, reproducible deployment

This design follows Docker and 42 project guidelines while remaining simple and maintainable.
