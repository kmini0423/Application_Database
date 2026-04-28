-- Run this only if you already have the old schema and want to migrate to Stage 2.
-- Otherwise use schema.sql on a fresh database.

USE carmeet_db;

-- 1. Create EventTypes and populate from current Events.event_type
CREATE TABLE IF NOT EXISTS EventTypes (
    type_id INT AUTO_INCREMENT PRIMARY KEY,
    type_name VARCHAR(100) NOT NULL,
    INDEX idx_type_name (type_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO EventTypes (type_name) VALUES
('Car Wash'), ('Cars & Coffee'), ('Night Cruise'), ('Track Day'), ('Show & Shine'), ('Other');

-- 2. Add type_id and created_by to Events (nullable first)
ALTER TABLE Events ADD COLUMN type_id INT NULL AFTER location_id;
ALTER TABLE Events ADD COLUMN created_by INT NULL AFTER type_id;
ALTER TABLE Events ADD COLUMN max_capacity INT NULL AFTER duration;

-- 3. Map existing event_type (enum) to type_id
UPDATE Events e SET e.type_id = (SELECT type_id FROM EventTypes t WHERE t.type_name = e.event_type LIMIT 1) WHERE e.type_id IS NULL;
UPDATE Events SET type_id = (SELECT type_id FROM EventTypes WHERE type_name = 'Other' LIMIT 1) WHERE type_id IS NULL;

-- 4. Drop enum column and add FK
ALTER TABLE Events DROP COLUMN event_type;
ALTER TABLE Events MODIFY type_id INT NOT NULL;
ALTER TABLE Events ADD CONSTRAINT fk_events_type FOREIGN KEY (type_id) REFERENCES EventTypes(type_id);
ALTER TABLE Events ADD CONSTRAINT fk_events_created_by FOREIGN KEY (created_by) REFERENCES Users(user_id);
ALTER TABLE Events ADD INDEX idx_type_id (type_id);
ALTER TABLE Events ADD INDEX idx_created_by (created_by);

-- 5. (Optional) If your Events table had invited_count/accepted_count, remove them:
-- ALTER TABLE Events DROP COLUMN invited_count;
-- ALTER TABLE Events DROP COLUMN accepted_count;
