-- Run this if you already have Locations table without LocationTypes.
-- Then: add column location_type_id to Locations.
USE carmeet_db;

CREATE TABLE IF NOT EXISTS LocationTypes (
    location_type_id INT AUTO_INCREMENT PRIMARY KEY,
    type_name VARCHAR(100) NOT NULL,
    INDEX idx_type_name (type_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT IGNORE INTO LocationTypes (type_name) VALUES
('Parking Lot'), ('Coffee Shop'), ('Car Wash'), ('Race Track'), ('Cafe'), ('Garage'), ('Restaurant'), ('Rest Stop'), ('Other');

-- If Locations has no location_type_id column yet, run:
-- ALTER TABLE Locations ADD COLUMN location_type_id INT NULL AFTER description;
-- ALTER TABLE Locations ADD CONSTRAINT fk_locations_type FOREIGN KEY (location_type_id) REFERENCES LocationTypes(location_type_id) ON DELETE SET NULL;
-- ALTER TABLE Locations ADD INDEX idx_location_type (location_type_id);
