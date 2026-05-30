# dreon-infra

Local Kubernetes infrastructure for the Dreon platform, running on [k3d](https://k3d.io) (k3s in Docker).

## Architecture

```
macOS
└── Docker Desktop
    └── k3d: dreon-local
        ├── dreon-system
        │   ├── Kong Gateway       ← API gateway (NodePort 30080 → host :80)
        │   ├── PostgreSQL         ← shared DB (dreon_auth, dreon_notification, dreon_api)
        │   ├── Redis              ← cache / session
        │   └── RabbitMQ          ← async events
        │
        └── dreon-dev
            ├── dreon-auth         → api.dreon.local/api/v1/auth
            ├── dreon-notification → api.dreon.local/api/v1/notifications
            └── dreon-api         → api.dreon.local/api/v1
```

## Prerequisites

| Tool | Install |
|------|---------|
| Docker Desktop | https://www.docker.com/products/docker-desktop |
| k3d ≥ 5.x | `brew install k3d` |
| kubectl | `brew install kubectl` |
| helm ≥ 3.x | `brew install helm` |
| openssl | pre-installed on macOS |

## Expected Directory Layout

This repo expects sibling service repos at the same level:

```
Personal/
├── dreon-infra/          ← this repo
├── dreon-auth/
├── dreon-notification/
└── dreon-api/
```

## Quick Start

### 1. Add `api.dreon.local` to `/etc/hosts`

```bash
make setup-hosts
```

This runs `sudo tee -a /etc/hosts` — your password will be prompted once.

### 2. Generate RS256 keypair

```bash
make gen-keys
```

Copy the printed keys into your secret files (see step 4).

### 3. Create the cluster

```bash
make local-up
```

### 4. Populate secrets

Copy the examples and fill in real values:

```bash
cp secrets/dev/dreon-auth.secret.example.yaml         secrets/dev/dreon-auth.secret.yaml
cp secrets/dev/dreon-notification.secret.example.yaml secrets/dev/dreon-notification.secret.yaml
cp secrets/dev/dreon-api.secret.example.yaml         secrets/dev/dreon-api.secret.yaml
```

Edit each file:
- Paste the RSA **private key** into `dreon-auth.secret.yaml` → `JWT_PRIVATE_KEY`
- Paste the RSA **public key** into `dreon-auth.secret.yaml` → `JWT_PUBLIC_KEY`
- Paste the **same public key** into `dreon-api.secret.yaml` → `JWT_PUBLIC_KEY`
- Add your `GEMINI_API_KEY` to `dreon-api.secret.yaml`
- Leave Twilio/Resend empty locally (mock clients will be used)

> **Passwords** in the example files already match the local Helm values — no change needed for local.

### 5. Install platform services

```bash
make platform-install
```

Installs Kong, PostgreSQL, Redis, and RabbitMQ. Takes ~2–3 minutes.

### 6. Build and deploy apps

```bash
make build-local    # docker build + k3d image import (~3–5 min first run)
make apps-deploy    # apply secrets + deploy all workloads
```

### 7. Verify

```bash
make status

# Health checks
curl http://api.dreon.local/api/v1/auth/health
curl http://api.dreon.local/api/v1/notifications/health

# dreon-api requires a JWT — expects 401
curl http://api.dreon.local/api/v1/conversation
```

## Available Commands

```bash
make help              # Full command list
make local-up          # Create cluster + namespaces
make platform-install  # Install platform via Helm
make gen-keys          # Generate RS256 keypair
make build-local       # Build images + k3d import
make apps-deploy       # Deploy all services
make status            # Pod + ingress status
make logs-auth         # Tail dreon-auth logs
make logs-notification # Tail dreon-notification logs
make logs-api          # Tail dreon-api logs
make kong-admin        # Port-forward Kong Admin → localhost:8001
make rmq-ui            # Port-forward RabbitMQ UI → localhost:15672
make pg-connect        # Open psql shell
make local-down        # Destroy cluster
```

## Kong Routing

| External URL | Upstream |
|---|---|
| `api.dreon.local/api/v1/auth/*` | `dreon-auth:8080` |
| `api.dreon.local/api/v1/notifications/*` | `dreon-notification:8080` |
| `api.dreon.local/api/v1/*` | `dreon-api:8080` |

Kong uses **path-length priority** — more specific paths (`/auth`, `/notifications`) take precedence over the catch-all (`/api/v1`).

## Secrets

Real secret files are **gitignored**. Only `*.secret.example.yaml` files are committed.

```
secrets/dev/
├── dreon-auth.secret.example.yaml         ← committed
├── dreon-auth.secret.yaml                 ← gitignored (your local copy)
├── dreon-notification.secret.example.yaml ← committed
├── dreon-notification.secret.yaml         ← gitignored
├── dreon-api.secret.example.yaml         ← committed
└── dreon-api.secret.yaml                 ← gitignored
```

## Teardown

```bash
make local-down
```
