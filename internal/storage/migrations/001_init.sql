CREATE TABLE IF NOT EXISTS schema_version (
    version    INTEGER PRIMARY KEY,
    applied_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS auth_users (
    id TEXT PRIMARY KEY,
    username TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    role TEXT NOT NULL,
    created_at TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS auth_sessions (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL REFERENCES auth_users(id),
    role TEXT NOT NULL,
    expires_at TEXT NOT NULL,
    revoked_at TEXT,
    created_at TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_auth_sessions_expiry ON auth_sessions(expires_at);

INSERT OR IGNORE INTO auth_users(id, username, password_hash, role, created_at) VALUES
 ('u-national-admin','national_admin','25986c10da75ca1df153385627e0963b90f4428bffd23384841d4e3b809b569f','national_admin','2026-01-01T00:00:00Z'),
 ('u-regional-coordinator','regional_coordinator','cfb753d71a9fdfd6cc6b8747b6d89ecb0115ee2e0dce1893fbef2eae88f3b589','regional_coordinator','2026-01-01T00:00:00Z'),
 ('u-community-provider','community_provider','ff1a863f6f0f3504dadd2f82734bc63c1a16f4b414833a2c58b73feb0be20d8f','community_provider','2026-01-01T00:00:00Z'),
 ('u-lab-coordinator','lab_coordinator','f2462d745534c23a3d23233d1339b6441b8cff5c05f2ed5c81410cb8f115d42a','lab_coordinator','2026-01-01T00:00:00Z');

CREATE TABLE IF NOT EXISTS prevention_stations (
 id TEXT PRIMARY KEY, name TEXT NOT NULL, county TEXT NOT NULL DEFAULT '', operator_id TEXT NOT NULL,
 status TEXT NOT NULL, latitude REAL NOT NULL DEFAULT 0, longitude REAL NOT NULL DEFAULT 0,
 created_at TEXT NOT NULL, updated_at TEXT NOT NULL, version INTEGER NOT NULL DEFAULT 1
);
CREATE TABLE IF NOT EXISTS prevention_hazards (
 id TEXT PRIMARY KEY, station_id TEXT NOT NULL REFERENCES prevention_stations(id), kind TEXT NOT NULL,
 severity TEXT NOT NULL DEFAULT 'medium', description TEXT NOT NULL, state TEXT NOT NULL,
 reported_by TEXT NOT NULL, assigned_to TEXT NOT NULL DEFAULT '', due_at TEXT NOT NULL,
 rectified_at TEXT, verified_at TEXT, evidence TEXT NOT NULL DEFAULT '', version INTEGER NOT NULL DEFAULT 1,
 created_at TEXT NOT NULL, updated_at TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_prevention_hazards_station_state ON prevention_hazards(station_id,state);
CREATE INDEX IF NOT EXISTS idx_prevention_hazards_due ON prevention_hazards(due_at,state);
CREATE TABLE IF NOT EXISTS prevention_inspections (
 id TEXT PRIMARY KEY, station_id TEXT NOT NULL REFERENCES prevention_stations(id), inspector_id TEXT NOT NULL,
 checked_at TEXT NOT NULL, extinguishers_ok INTEGER NOT NULL, extinguisher_expiry TEXT NOT NULL,
 crash_barrier_ok INTEGER NOT NULL, signage_ok INTEGER NOT NULL, notes TEXT NOT NULL DEFAULT ''
);

CREATE TABLE IF NOT EXISTS shard_meta (
    shard_id     TEXT PRIMARY KEY,
    date         TEXT NOT NULL,
    route_id     TEXT NOT NULL,
    file_path    TEXT NOT NULL,
    record_count INTEGER NOT NULL DEFAULT 0,
    checksum     TEXT NOT NULL DEFAULT '',
    status       TEXT NOT NULL DEFAULT 'ok',
    data_version INTEGER NOT NULL DEFAULT 1,
    created_at   TEXT NOT NULL,
    updated_at   TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_shard_date ON shard_meta(date);
CREATE INDEX IF NOT EXISTS idx_shard_route ON shard_meta(route_id);
CREATE INDEX IF NOT EXISTS idx_shard_status ON shard_meta(status);

CREATE TABLE IF NOT EXISTS mail_items (
    id             TEXT PRIMARY KEY,
    mail_no        TEXT UNIQUE NOT NULL,
    route_id       TEXT NOT NULL,
    vehicle_no     TEXT,
    state          TEXT NOT NULL,
    handover_id    TEXT,
    disposition_id TEXT,
    origin_station TEXT,
    dest_station   TEXT,
    sender_name    TEXT,
    sender_addr    TEXT,
    receiver_name  TEXT,
    receiver_addr  TEXT,
    responsible    TEXT,
    registered_at  TEXT NOT NULL,
    loaded_at      TEXT,
    in_transit_at  TEXT,
    arrived_at     TEXT,
    signed_at      TEXT,
    completed_at   TEXT,
    version        INTEGER NOT NULL DEFAULT 1,
    shard_id       TEXT NOT NULL,
    data_version   INTEGER NOT NULL DEFAULT 1
);
CREATE INDEX IF NOT EXISTS idx_mail_state ON mail_items(state);
CREATE INDEX IF NOT EXISTS idx_mail_route ON mail_items(route_id);
CREATE INDEX IF NOT EXISTS idx_mail_vehicle ON mail_items(vehicle_no);
CREATE INDEX IF NOT EXISTS idx_mail_handover ON mail_items(handover_id);

CREATE TABLE IF NOT EXISTS handover_forms (
    id                TEXT PRIMARY KEY,
    form_no           TEXT UNIQUE NOT NULL,
    date              TEXT NOT NULL,
    route_id          TEXT NOT NULL,
    vehicle_no        TEXT,
    state             TEXT NOT NULL,
    outbound_station  TEXT,
    outbound_signer   TEXT,
    outbound_signed_at TEXT,
    arrival_station   TEXT,
    arrival_signer    TEXT,
    arrival_signed_at TEXT,
    mail_item_count   INTEGER NOT NULL DEFAULT 0,
    responsible       TEXT,
    registered_at     TEXT NOT NULL,
    updated_at        TEXT NOT NULL,
    version           INTEGER NOT NULL DEFAULT 1,
    shard_id          TEXT NOT NULL,
    data_version      INTEGER NOT NULL DEFAULT 1
);
CREATE INDEX IF NOT EXISTS idx_handover_state ON handover_forms(state);
CREATE INDEX IF NOT EXISTS idx_handover_date ON handover_forms(date);
CREATE INDEX IF NOT EXISTS idx_handover_route ON handover_forms(route_id);

CREATE TABLE IF NOT EXISTS disposition_requests (
    id               TEXT PRIMARY KEY,
    request_no       TEXT UNIQUE NOT NULL,
    mail_id          TEXT NOT NULL,
    mail_no          TEXT NOT NULL,
    type             TEXT NOT NULL,
    target_address   TEXT,
    state            TEXT NOT NULL,
    submitted_by     TEXT NOT NULL,
    submitted_at     TEXT NOT NULL,
    reviewed_by      TEXT,
    reviewed_at      TEXT,
    review_note      TEXT,
    issued_by        TEXT,
    issued_at        TEXT,
    executed_at      TEXT,
    completed_at     TEXT,
    withdrawn_by     TEXT,
    withdrawn_at     TEXT,
    withdrawn_reason TEXT,
    conflict_reason  TEXT,
    lost_at          TEXT,
    version          INTEGER NOT NULL DEFAULT 1,
    shard_id         TEXT NOT NULL,
    data_version     INTEGER NOT NULL DEFAULT 1
);
CREATE INDEX IF NOT EXISTS idx_disp_state ON disposition_requests(state);
CREATE INDEX IF NOT EXISTS idx_disp_mail ON disposition_requests(mail_id);

CREATE TABLE IF NOT EXISTS active_dispositions (
    mail_id        TEXT PRIMARY KEY,
    disposition_id TEXT NOT NULL,
    created_at     TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS batch_records (
    id              TEXT PRIMARY KEY,
    vehicle_no      TEXT NOT NULL,
    date            TEXT NOT NULL,
    route_id        TEXT NOT NULL,
    state           TEXT NOT NULL,
    total_count     INTEGER NOT NULL DEFAULT 0,
    succeeded_count INTEGER NOT NULL DEFAULT 0,
    failed_count    INTEGER NOT NULL DEFAULT 0,
    created_at      TEXT NOT NULL,
    updated_at      TEXT NOT NULL,
    version         INTEGER NOT NULL DEFAULT 1,
    shard_id        TEXT NOT NULL,
    data_version    INTEGER NOT NULL DEFAULT 1
);
CREATE INDEX IF NOT EXISTS idx_batch_state ON batch_records(state);
CREATE INDEX IF NOT EXISTS idx_batch_vehicle ON batch_records(vehicle_no);

CREATE TABLE IF NOT EXISTS batch_items (
    id         TEXT PRIMARY KEY,
    batch_id   TEXT NOT NULL,
    mail_id    TEXT NOT NULL,
    mail_no    TEXT NOT NULL,
    state      TEXT NOT NULL,
    error      TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_batch_item_batch ON batch_items(batch_id);
CREATE INDEX IF NOT EXISTS idx_batch_item_state ON batch_items(state);

CREATE TABLE IF NOT EXISTS ledger_entries (
    id          TEXT PRIMARY KEY,
    date        TEXT NOT NULL,
    route_id    TEXT NOT NULL,
    volume_no   TEXT NOT NULL,
    form_no     TEXT,
    entry_type  TEXT NOT NULL,
    mail_no     TEXT,
    responsible TEXT,
    description TEXT,
    prev_state  TEXT,
    next_state  TEXT,
    created_at  TEXT NOT NULL,
    shard_id    TEXT NOT NULL,
    data_version INTEGER NOT NULL DEFAULT 1
);
CREATE INDEX IF NOT EXISTS idx_ledger_date ON ledger_entries(date);
CREATE INDEX IF NOT EXISTS idx_ledger_route ON ledger_entries(route_id);
CREATE INDEX IF NOT EXISTS idx_ledger_responsible ON ledger_entries(responsible);
CREATE INDEX IF NOT EXISTS idx_ledger_volume ON ledger_entries(volume_no);

CREATE TABLE IF NOT EXISTS events (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    type        TEXT NOT NULL,
    business_key TEXT NOT NULL,
    shard_id    TEXT,
    payload     TEXT NOT NULL,
    created_at  TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_events_type ON events(type);
CREATE INDEX IF NOT EXISTS idx_events_created ON events(created_at);

CREATE TABLE IF NOT EXISTS subscriber_checkpoints (
    id             TEXT PRIMARY KEY,
    type           TEXT NOT NULL,
    name           TEXT,
    last_event_id  INTEGER NOT NULL DEFAULT 0,
    last_active_at TEXT NOT NULL,
    created_at     TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS audit_trail (
    id           INTEGER PRIMARY KEY AUTOINCREMENT,
    actor        TEXT NOT NULL,
    action       TEXT NOT NULL,
    entity_type  TEXT NOT NULL,
    entity_id    TEXT NOT NULL,
    shard_id     TEXT,
    before_state TEXT,
    after_state  TEXT,
    detail       TEXT,
    timestamp    TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_audit_actor ON audit_trail(actor);
CREATE INDEX IF NOT EXISTS idx_audit_entity ON audit_trail(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_audit_timestamp ON audit_trail(timestamp);

CREATE TABLE IF NOT EXISTS permanent_failures (
    id             INTEGER PRIMARY KEY AUTOINCREMENT,
    task_type      TEXT NOT NULL,
    entity_id      TEXT NOT NULL,
    shard_id       TEXT,
    last_error     TEXT,
    attempts       INTEGER NOT NULL DEFAULT 0,
    max_attempts   INTEGER NOT NULL DEFAULT 3,
    last_attempt_at TEXT,
    next_retry_at  TEXT,
    status         TEXT NOT NULL DEFAULT 'pending',
    created_at     TEXT NOT NULL,
    resolved_at    TEXT
);
CREATE INDEX IF NOT EXISTS idx_failure_status ON permanent_failures(status);
CREATE INDEX IF NOT EXISTS idx_failure_task ON permanent_failures(task_type);
