-- dreon-infra: PostgreSQL init script
-- Runs once on first cluster startup.
-- Creates one database per service.

CREATE DATABASE dreon_auth;
CREATE DATABASE dreon_notification;

GRANT ALL PRIVILEGES ON DATABASE dreon_auth        TO postgres;
GRANT ALL PRIVILEGES ON DATABASE dreon_notification TO postgres;
