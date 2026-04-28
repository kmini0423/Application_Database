# CS348 Project – Database Design (Stage 2)

---

## Relational Schema

### 1. Users

| Column        | Type         | Constraints        |
|---------------|--------------|--------------------|
| user_id       | INT          | PK, AUTO_INCREMENT |
| name          | VARCHAR(255) | NOT NULL           |
| email         | VARCHAR(255) | NOT NULL, UNIQUE   |
| password_hash | VARCHAR(255) | NOT NULL           |
| role          | ENUM         | 'user', 'organizer', 'admin' |
| created_at    | TIMESTAMP    | DEFAULT CURRENT_TIMESTAMP |

**Indexes:** email, role (for login and role-based access).

---

### 2. EventTypes

| Column   | Type         | Constraints        |
|----------|--------------|--------------------|
| type_id   | INT          | PK, AUTO_INCREMENT |
| type_name | VARCHAR(100) | NOT NULL           |

**Purpose:** Dropdown options for event type are loaded from this table (dynamic UI – not hard-coded).  
**Index:** type_name.

---

### 3. Locations

| Column      | Type         | Constraints        |
|-------------|--------------|--------------------|
| location_id | INT          | PK, AUTO_INCREMENT |
| name        | VARCHAR(255) | NOT NULL           |
| address     | VARCHAR(500) |                    |
| city        | VARCHAR(100) |                    |
| state       | VARCHAR(50)  |                    |
| zip_code    | VARCHAR(20)  |                    |
| capacity    | INT          |                    |
| description | TEXT         |                    |
| created_at  | TIMESTAMP    | DEFAULT CURRENT_TIMESTAMP |

**Purpose:** Dropdown options for location are loaded from this table (dynamic UI). Locations are generic place types so the app works anywhere (e.g. Parking Lot, Coffee Shop, Garage, Restaurant, Rest Stop, Car Wash); the exact spot is set via address fields or map when adding a location.  
**Indexes:** name, city (for filtering and display).

---

### 4. Events (main table. add, edit, delete)

| Column      | Type    | Constraints                          |
|-------------|---------|--------------------------------------|
| event_id    | INT     | PK, AUTO_INCREMENT                   |
| title       | VARCHAR(255) | NOT NULL                         |
| description | TEXT    |                                      |
| date        | DATE    | NOT NULL                              |
| time        | TIME    | NOT NULL                              |
| duration    | INT     | NOT NULL (minutes)                   |
| max_capacity| INT    |                                      |
| type_id     | INT     | NOT NULL, FK → EventTypes(type_id)    |
| location_id | INT     | FK → Locations(location_id)          |
| created_by  | INT     | FK → Users(user_id)                  |
| created_at  | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP          |
| updated_at  | TIMESTAMP | ON UPDATE CURRENT_TIMESTAMP        |

[Foreign keys:]
- type_id -> EventTypes(type_id)  
- location_id -> Locations(location_id)  
- created_by -> Users(user_id)  

[Indexes (support queries and reports):]
- idx_date, idx_location, idx_type_id, idx_created_by, idx_date_time  
(Used by: event list, report filters by date range / location / event type.)

---

### 5. EventOrganizers

| Column    | Type      | Constraints                    |
|-----------|-----------|--------------------------------|
| event_id  | INT       | PK, FK → Events(event_id)      |
| user_id   | INT       | PK, FK → Users(user_id)        |
| created_at| TIMESTAMP | DEFAULT CURRENT_TIMESTAMP      |

[Purpose:]
Many-to-many between Events and Users.  
[Index:]
user_id (list events by organizer).

---

### 6. RSVP

| Column   | Type      | Constraints                        |
|----------|-----------|------------------------------------|
| event_id | INT       | PK, FK → Events(event_id)          |
| user_id  | INT       | PK, FK → Users(user_id)            |
| status   | ENUM      | 'yes', 'no', 'maybe' NOT NULL      |
| updated_at | TIMESTAMP | ON UPDATE CURRENT_TIMESTAMP        |

[Purpose:]
Per-event RSVP counts for report statistics (yes/maybe/no, totals).  
[Indexes:]
status, user_id, event_id (for report aggregates and lookups).



