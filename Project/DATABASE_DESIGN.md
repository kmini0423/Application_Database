# CS348 Project – Database Design (Stage 2)

**Application:** Cars & Coffee 247 – Car club event management  
**Main table for Requirement 1:** Events  
**Report for Requirement 2:** Filtered event list + statistics (date range, event type, location)

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







---

## Table relationships (summary)

- **Events** is the main table (Requirement 1: insert, update, delete).
- **EventTypes** and **Locations** are referenced by Events and used to build dropdowns from the database (Requirement 2 point c).
- **Users** are referenced by Events (created_by) and EventOrganizers, and by RSVPs.
- **RSVPs** and **EventOrganizers** are supporting tables; report statistics are derived from Events + RSVPs (e.g., total events, average yes count, average total RSVPs per event).

---

## Requirement mapping

| Requirement | Main table / use |
|-------------|-------------------|
| **Req 1** (add, edit, delete) | Events (and EventOrganizers when assigning organizers). |
| **Req 2** (filter + report)   | Events filtered by date range, type_id, location_id; statistics from Events + RSVPs. |
| **Dynamic UI** (dropdowns from DB) | EventTypes and Locations tables; UI calls GET /api/event-types and GET /api/locations. |
