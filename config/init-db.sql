-- Initialize Snaproom Database
-- This script runs when the PostgreSQL container starts for the first time

-- Create additional databases if needed
-- CREATE DATABASE snaproom_test;

-- Grant permissions
GRANT ALL PRIVILEGES ON DATABASE snaproom TO snaproom;

-- Create extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Log initialization
DO $$
BEGIN
    RAISE NOTICE 'Snaproom database initialized successfully';
END $$;