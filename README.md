# railway-iot-timescale-db

TimescaleDB schema, migrations and data retention for **railway-iot-platform**.

---

## Responsibilities

- TimescaleDB hypertable for sensor readings (time-series optimized)
- Schema initialization via Django migrations
- Data compression policy (auto-compress after 7 days)
- Data retention policy (drop chunks older than 1 year)
- Seed data for development environment

---

## Stack

| Component | Version |
|---|---|
| PostgreSQL | 16 |
| TimescaleDB | 2.14.x |

---

## Schema

The primary time-series table is managed by Django ORM and promoted to a TimescaleDB hypertable:

### `telemetry_sensorreading`

| Column | Type | Description |
|---|---|---|
| `id` | `bigserial` | Primary key |
| `device_id` | `varchar(64)` | Sensor device identifier |
| `zone` | `varchar(64)` | Zone identifier |
| `metric` | `varchar(32)` | Metric name (e.g., `temperature`) |
| `value` | `double precision` | Sensor reading value |
| `timestamp` | `timestamptz` | Reading timestamp (hypertable partition key) |

### `alerts_alert`

| Column | Type | Description |
|---|---|---|
| `id` | `bigserial` | Primary key |
| `device_id` | `varchar(64)` | Source device |
| `zone` | `varchar(64)` | Zone |
| `metric` | `varchar(32)` | Affected metric |
| `value` | `double precision` | Trigger value |
| `severity` | `varchar(16)` | `low`, `medium`, `high`, `critical` |
| `acknowledged` | `boolean` | Whether the alert was acknowledged |
| `created_at` | `timestamptz` | Alert creation time |

---

## TimescaleDB Features

### Hypertable
`telemetry_sensorreading` is partitioned by `timestamp` into 1-week chunks for efficient time-range queries.

### Compression Policy
Chunks older than **7 days** are automatically compressed, reducing storage by 90–95% for time-series data.

### Retention Policy
Chunks older than **1 year** are automatically dropped.

---

## Connection

```bash
# Connect to database via Docker
docker compose exec db psql -U railway -d railway_db

# Check hypertable chunks
SELECT * FROM timescaledb_information.chunks WHERE hypertable_name = 'telemetry_sensorreading';

# Check compression status
SELECT * FROM timescaledb_information.compressed_chunk_stats;
```

---

## Migrations

Django manages the schema via migrations:

```bash
docker compose exec api python manage.py migrate
```
