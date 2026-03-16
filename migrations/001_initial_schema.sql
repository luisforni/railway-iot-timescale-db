CREATE TABLE IF NOT EXISTS zones (
    id          SERIAL PRIMARY KEY,
    name        VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS devices (
    id          SERIAL PRIMARY KEY,
    device_id   VARCHAR(100) NOT NULL UNIQUE,
    zone_id     INTEGER REFERENCES zones(id),
    device_type VARCHAR(50) NOT NULL,
    active      BOOLEAN DEFAULT TRUE,
    created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS sensor_readings (
    time        TIMESTAMPTZ NOT NULL,
    device_id   VARCHAR(100) NOT NULL,
    zone        VARCHAR(100) NOT NULL,
    metric      VARCHAR(50) NOT NULL,
    value       DOUBLE PRECISION NOT NULL,
    unit        VARCHAR(20),
    anomaly     BOOLEAN DEFAULT FALSE
);

SELECT create_hypertable('sensor_readings', 'time', if_not_exists => TRUE);

ALTER TABLE sensor_readings SET (
    timescaledb.compress,
    timescaledb.compress_segmentby = 'device_id,metric',
    timescaledb.compress_orderby   = 'time DESC'
);

SELECT add_compression_policy('sensor_readings', INTERVAL '7 days');

SELECT add_retention_policy('sensor_readings', INTERVAL '1 year');

CREATE INDEX IF NOT EXISTS idx_sensor_readings_device
    ON sensor_readings (device_id, time DESC);

CREATE MATERIALIZED VIEW sensor_hourly_avg
WITH (timescaledb.continuous) AS
SELECT
    time_bucket('1 hour', time) AS bucket,
    device_id,
    metric,
    AVG(value) AS avg_value,
    MAX(value) AS max_value,
    MIN(value) AS min_value
FROM sensor_readings
GROUP BY time_bucket('1 hour', time), device_id, metric
WITH NO DATA;

SELECT add_continuous_aggregate_policy('sensor_hourly_avg',
    start_offset      => INTERVAL '1 month',
    end_offset        => INTERVAL '1 hour',
    schedule_interval => INTERVAL '1 hour'
);
