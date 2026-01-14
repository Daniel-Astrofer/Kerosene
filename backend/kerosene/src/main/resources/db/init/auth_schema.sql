CREATE SCHEMA IF NOT EXISTS auth AUTHORIZATION api_system;

-- Users credentials table
CREATE TABLE IF NOT EXISTS auth.users_credentials (
    id BIGSERIAL PRIMARY KEY,
    username VARCHAR(150) NOT NULL UNIQUE,
    passphrase VARCHAR(255) NOT NULL,
    totp_secret VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE auth.users_credentials OWNER TO api_system;
