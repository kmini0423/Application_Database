# Car Meet Backend API

Flask backend for the Car Meet management application.

## Setup

1. **Install Python dependencies**
   ```bash
   pip install -r requirements.txt
   ```

2. **Create a `.env` file** (required for DB connection)
   - Copy `env.example` to `.env`: `cp env.example .env`
   - Edit `.env` and set `DB_PASSWORD` to your MySQL root password (leave as empty string if you have no password).

3. **Start MySQL** (if not already running)
   - macOS (Homebrew): `brew services start mysql`
   - Or open MySQL Workbench / start your MySQL server.

4. **Create the database and tables**
   ```bash
   mysql -u root -p < database/schema.sql
   ```
   Enter your MySQL password when prompted. This creates `carmeet_db` and all tables.

5. **Run the Flask server**
   ```bash
   python app.py
   ```
   The API will be available at `http://localhost:5001`

### If you get "Database connection failed"

- **MySQL not running:** Start MySQL (see step 3).
- **Wrong password:** Set `DB_PASSWORD` in `.env` to your actual MySQL password.
- **Database missing:** Run step 4: `mysql -u root -p < database/schema.sql`
- **Wrong host/port:** If MySQL is on another machine or port, set `DB_HOST` and `DB_PORT` in `.env`.
- Check the Flask terminal for the exact MySQL error message (e.g. "Access denied", "Unknown database").

**Stage 2 schema:** Use `database/schema.sql` for a fresh install. If you have an existing DB from before Stage 2, see `database/migrate_to_stage2.sql`.  
**Generic locations:** If your DB still has old location names (e.g. "Downtown Parking Lot", "Indianapolis Motor Speedway"), run `database/migrate_locations_generic.sql` to switch to generic options (Parking Lot, Coffee Shop, Garage, Restaurant, Rest Stop, Car Wash).

## API Endpoints

### Authentication
- `POST /api/register` - Register a new user
- `POST /api/login` - Login user

### Dynamic dropdown data (Stage 2 – UI built from DB)
- `GET /api/event-types` - List event types (for Event Type dropdown)
- `GET /api/locations` - List locations (for Location dropdown)

### Events (Requirement 1 – main table CRUD)
- `GET /api/events` - Get all events (optional: start_date, end_date, location_id, type_id)
- `GET /api/events/<id>` - Get one event (with RSVP counts)
- `POST /api/events` - Create event (body: title, date, time, duration, location_id, type_id, created_by, …)
- `PUT /api/events/<id>` - Update event
- `DELETE /api/events/<id>` - Delete event

### RSVP
- `POST /api/events/<id>/rsvp` - Create/update RSVP (body: user_id, status: yes|no|maybe)

### Locations
- `GET /api/locations` - Get all locations

### Users
- `GET /api/users` - Get all users (for selecting organizers)

### Reports (Requirement 2)
- `GET /api/reports/events` - Filtered report (query: start_date, end_date, location_id, type_id). Returns event list and statistics (total_events, avg_duration, avg_yes_rsvps, avg_total_rsvps).

### Health Check
- `GET /api/health` - Check API health

## Database Schema

See `database/schema.sql` for the complete database schema.
