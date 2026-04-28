-- Car Meet Application Database Schema
-- CS348 Project Stage 2 & 3: Cars & Coffee 247
-- Database design: main table = Events; dropdown data from EventTypes, Locations (dynamic UI).

CREATE DATABASE IF NOT EXISTS carmeet_db;
USE carmeet_db;

-- Table 1: Users
CREATE TABLE IF NOT EXISTS Users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role ENUM('user', 'organizer', 'admin') DEFAULT 'user',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_email (email),
    INDEX idx_role (role)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;



-- Table 2: EventTypes (for dynamic dropdown)
CREATE TABLE IF NOT EXISTS EventTypes (
    type_id INT AUTO_INCREMENT PRIMARY KEY,
    type_name VARCHAR(100) NOT NULL,
    INDEX idx_type_name (type_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Table 2b: LocationTypes (what kind of place - parking lot, coffee shop, car wash)
CREATE TABLE IF NOT EXISTS LocationTypes (
    location_type_id INT AUTO_INCREMENT PRIMARY KEY,
    type_name VARCHAR(100) NOT NULL,
    INDEX idx_type_name (type_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;




-- Table 3: Locations (for dynamic dropdown - anywhere, user-addable)
CREATE TABLE IF NOT EXISTS Locations (
    location_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    address VARCHAR(500),
    city VARCHAR(100),
    state VARCHAR(50),
    zip_code VARCHAR(20),
    capacity INT,
    description TEXT,
    location_type_id INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (location_type_id) REFERENCES LocationTypes(location_type_id) ON DELETE SET NULL,
    INDEX idx_name (name),
    INDEX idx_city (city),
    INDEX idx_location_type (location_type_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- Table 4: Events [Main]
CREATE TABLE IF NOT EXISTS Events (
    event_id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    date DATE NOT NULL,
    time TIME NOT NULL,
    duration INT NOT NULL COMMENT 'Duration in minutes',
    max_capacity INT,
    type_id INT NOT NULL,
    location_id INT,
    location_description VARCHAR(500) COMMENT 'Place/spot description (address or landmark)',
    created_by INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,



    FOREIGN KEY (type_id) REFERENCES EventTypes(type_id) ON DELETE RESTRICT,
    FOREIGN KEY (location_id) REFERENCES Locations(location_id) ON DELETE SET NULL,
    FOREIGN KEY (created_by) REFERENCES Users(user_id) ON DELETE SET NULL,



    INDEX idx_date (date),
    INDEX idx_location (location_id),
    INDEX idx_type_id (type_id),
    INDEX idx_created_by (created_by),
    INDEX idx_date_time (date, time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;




-- Table 5: eventOrganizers
CREATE TABLE IF NOT EXISTS EventOrganizers (
    event_id INT NOT NULL,
    user_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (event_id, user_id),
    FOREIGN KEY (event_id) REFERENCES Events(event_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE,


    INDEX idx_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;




-- Table 6: RSVPs (yes/no/maybe )

CREATE TABLE IF NOT EXISTS RSVPs (
    event_id INT NOT NULL,
    user_id INT NOT NULL,
    status ENUM('yes', 'no', 'maybe') NOT NULL DEFAULT 'maybe',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (event_id, user_id),
    FOREIGN KEY (event_id) REFERENCES Events(event_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE,


    INDEX idx_status (status),
    INDEX idx_user (user_id),
    INDEX idx_event_id (event_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;













-- =====================
-- Sample data (for demo: dropdowns and report have data)
-- =====================

-- EventTypes (dropdown built from DB)
INSERT INTO EventTypes (type_name) VALUES
('Car Wash'),
('Cars & Coffee'),
('Night Cruise'),
('Track Day'),
('Show & Shine'),
('Other');

-- LocationTypes: generic place types (usable anywhere; exact spot via Add Location / map)
INSERT INTO LocationTypes (type_name) VALUES
('Parking Lot'),
('Coffee Shop'),
('Car Wash'),
('Race Track'),
('Cafe'),
('Garage'),
('Restaurant'),
('Rest Stop'),
('Other');

-- Locations: generic options for dropdown; exact address set via Add Location / map
INSERT INTO Locations (name, address, city, state, zip_code, capacity, description, location_type_id) VALUES
('Parking Lot', '', '', '', '', 100, 'Exact spot: add address or use map when creating a location', 1),
('Coffee Shop', '', '', '', '', 50, 'Exact spot: add address or use map when creating a location', 2),
('Garage', '', '', '', '', 30, 'Exact spot: add address or use map when creating a location', 6),
('Restaurant', '', '', '', '', 40, 'Exact spot: add address or use map when creating a location', 7),
('Rest Stop', '', '', '', '', 80, 'Exact spot: add address or use map when creating a location', 8),
('Car Wash', '', '', '', '', 20, 'Exact spot: add address or use map when creating a location', 3);

-- Users (password 'password123' - bcrypt hash)
INSERT INTO Users (name, email, password_hash, role) VALUES
('Admin User', 'admin@carmeet.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5Gy4QN/ZKy', 'admin'),
('John Organizer', 'organizer@carmeet.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5Gy4QN/ZKy', 'organizer'),
('Regular User', 'user@carmeet.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5Gy4QN/ZKy', 'user');

-- Events (type_id 2 = Cars & Coffee, 3 = Night Cruise, 4 = Track Day; locations 1–6 are generic)
INSERT INTO Events (title, description, date, time, duration, max_capacity, type_id, location_id, created_by) VALUES
('Cars & Coffee', 'Morning meetup for coffee and cars', '2025-03-15', '08:00:00', 120, 50, 2, 1, 2),
('Spring Cruise', 'Scenic cruise through the countryside', '2025-03-20', '14:00:00', 180, 30, 3, 2, 2),
('Track Day', 'Full day at the track', '2025-03-25', '09:00:00', 480, 100, 4, 3, 1),
('Car Wash Meet', 'Community car wash and hangout', '2025-03-18', '10:00:00', 120, 40, 1, 6, 2),
('Night Cruise', 'Evening cruise', '2025-03-22', '19:00:00', 120, 25, 3, 2, 2);

-- EventOrganizers
INSERT INTO EventOrganizers (event_id, user_id) VALUES
(1, 2), (2, 2), (3, 1), (4, 2), (5, 2);

-- RSVPs (for report: yes/maybe/no counts per event)
INSERT INTO RSVPs (event_id, user_id, status) VALUES
(1, 3, 'yes'),
(2, 3, 'maybe'),
(3, 3, 'yes'),
(1, 1, 'yes'),
(2, 1, 'no'),
(4, 3, 'yes');
