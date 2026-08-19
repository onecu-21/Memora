CREATE TABLE users (id TEXT PRIMARY KEY, email TEXT NOT NULL UNIQUE, created_at INTEGER NOT NULL);
CREATE TABLE otp_codes (id TEXT PRIMARY KEY, email TEXT NOT NULL, code_hash TEXT NOT NULL, expires_at INTEGER NOT NULL, attempts INTEGER NOT NULL DEFAULT 0, used INTEGER NOT NULL DEFAULT 0, created_at INTEGER NOT NULL);
CREATE INDEX otp_email_created ON otp_codes(email, created_at);
CREATE TABLE sessions (id TEXT PRIMARY KEY, user_id TEXT NOT NULL, token_hash TEXT NOT NULL UNIQUE, expires_at INTEGER NOT NULL, created_at INTEGER NOT NULL);
CREATE TABLE devices (id TEXT PRIMARY KEY, user_id TEXT NOT NULL, name TEXT NOT NULL, updated_at INTEGER NOT NULL);
CREATE TABLE entities (id TEXT NOT NULL, user_id TEXT NOT NULL, entity_type TEXT NOT NULL, payload_json TEXT NOT NULL, revision INTEGER NOT NULL, updated_at INTEGER NOT NULL, deleted_at INTEGER, user_confirmed INTEGER NOT NULL DEFAULT 0, PRIMARY KEY(user_id, entity_type, id));
