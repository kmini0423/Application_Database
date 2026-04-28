-- Migrate existing Locations to generic names (anywhere-usable).
-- Run this if your DB still has old names like "Downtown Parking Lot", "Indianapolis Motor Speedway", "Speedway Coffee Shop".
-- Exact spot is set via Add Location / map in the app.

USE carmeet_db;

-- Ensure LocationTypes exist (for new location rows)
INSERT IGNORE INTO LocationTypes (type_name) VALUES
('Parking Lot'), ('Coffee Shop'), ('Car Wash'), ('Race Track'), ('Cafe'), ('Garage'), ('Restaurant'), ('Rest Stop'), ('Other');

-- Update existing locations to generic names (by id; keeps Events.location_id references valid)
UPDATE Locations SET name = 'Parking Lot', address = '', city = '', state = '', zip_code = '', description = 'Exact spot: add address or use map when creating a location' WHERE location_id = 1;
UPDATE Locations SET name = 'Coffee Shop', address = '', city = '', state = '', zip_code = '', description = 'Exact spot: add address or use map when creating a location' WHERE location_id = 2;
UPDATE Locations SET name = 'Garage', address = '', city = '', state = '', zip_code = '', description = 'Exact spot: add address or use map when creating a location' WHERE location_id = 3;

-- Add more generic options if they don't exist
INSERT INTO Locations (name, address, city, state, zip_code, capacity, description, location_type_id)
SELECT 'Restaurant', '', '', '', '', 40, 'Exact spot: add address or use map when creating a location', (SELECT location_type_id FROM LocationTypes WHERE type_name = 'Restaurant' LIMIT 1)
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM Locations WHERE name = 'Restaurant');

INSERT INTO Locations (name, address, city, state, zip_code, capacity, description, location_type_id)
SELECT 'Rest Stop', '', '', '', '', 80, 'Exact spot: add address or use map when creating a location', (SELECT location_type_id FROM LocationTypes WHERE type_name = 'Rest Stop' LIMIT 1)
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM Locations WHERE name = 'Rest Stop');

INSERT INTO Locations (name, address, city, state, zip_code, capacity, description, location_type_id)
SELECT 'Car Wash', '', '', '', '', 20, 'Exact spot: add address or use map when creating a location', (SELECT location_type_id FROM LocationTypes WHERE type_name = 'Car Wash' LIMIT 1)
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM Locations WHERE name = 'Car Wash');
