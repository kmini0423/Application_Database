-- Add optional place/spot description to Events (used in Create Event form)
-- Run once; if column already exists, ignore the error.
USE carmeet_db;

ALTER TABLE Events
ADD COLUMN location_description VARCHAR(500) NULL
COMMENT 'Place/spot description (e.g. address or landmark)'
AFTER location_id;
