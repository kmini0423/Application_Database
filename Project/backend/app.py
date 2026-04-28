from flask import Flask, request, jsonify
from flask_cors import CORS
import mysql.connector
from mysql.connector import Error
from datetime import datetime
import bcrypt
import os
from dotenv import load_dotenv

load_dotenv()

app = Flask(__name__)
CORS(app)

# Database configuration
DB_CONFIG = {
    'host': os.getenv('DB_HOST', 'localhost'),
    'database': os.getenv('DB_NAME', 'carmeet_db'),
    'user': os.getenv('DB_USER', 'root'),
    'password': os.getenv('DB_PASSWORD', ''),
    'port': int(os.getenv('DB_PORT', 3306))
}

def get_db_connection():
    """Create and return database connection. On Access denied (1045), retries with empty password."""
    try:
        connection = mysql.connector.connect(**DB_CONFIG)
        return connection
    except Error as e:
        errno = getattr(e, 'errno', None)
        is_access_denied = errno == 1045 or 'Access denied' in str(e)
        if is_access_denied and DB_CONFIG.get('password'):
            try:
                fallback = {**DB_CONFIG, 'password': ''}
                connection = mysql.connector.connect(**fallback)
                DB_CONFIG['password'] = ''
                print("MySQL connected with empty password (root has no password).")
                return connection
            except Error:
                pass
        print(f"MySQL connection error: {e}")
        print(f"Tried: host={DB_CONFIG['host']}, database={DB_CONFIG['database']}, user={DB_CONFIG['user']}, port={DB_CONFIG['port']}")
        return None

# Map old DB location names to generic names (so dropdowns work anywhere)
_LOCATION_NAME_MAP = {
    'downtown parking lot': 'Parking Lot',
    'indianapolis motor speedway': 'Race Track',
    'speedway coffee shop': 'Coffee Shop',
}

def normalize_location_name(name):
    """Return generic display name for locations; keeps dropdowns usable anywhere."""
    if not name or not isinstance(name, str):
        return name
    key = name.strip().lower()
    return _LOCATION_NAME_MAP.get(key, name)

# Old seed/placeholder addresses (e.g. "123 Main St") - return empty so event detail doesn't show them
_OLD_ADDRESS_PARTS = ('123 main st', '123 main', '4790 w 16th', '456 race', 'indianapolis', 'speedway', '46222', '46202')

def normalize_location_address(addr):
    """Don't show old placeholder addresses; return empty so UI shows only location name / event's place description."""
    if not addr or not isinstance(addr, str):
        return ''
    a = addr.strip()
    if not a:
        return ''
    lower = a.lower()
    if any(p in lower for p in _OLD_ADDRESS_PARTS):
        return ''
    return a

# ============ AUTHENTICATION ENDPOINTS ============

@app.route('/api/register', methods=['POST'])
def register():
    """Register a new user"""
    data = request.get_json()
    name = data.get('name')
    email = data.get('email')
    password = data.get('password')
    role = data.get('role', 'user')  # default to 'user', can be 'admin' or 'organizer'
    
    if not name or not email or not password:
        return jsonify({'error': 'Missing required fields'}), 400
    
    connection = get_db_connection()
    if not connection:
        return jsonify({'error': 'Database connection failed'}), 500
    
    try:
        cursor = connection.cursor()
        
        # Check if email already exists
        cursor.execute("SELECT user_id FROM Users WHERE email = %s", (email,))
        if cursor.fetchone():
            return jsonify({'error': 'Email already exists'}), 400
        
        # Hash password
        password_hash = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
        
        # Insert user
        cursor.execute(
            "INSERT INTO Users (name, email, password_hash, role) VALUES (%s, %s, %s, %s)",
            (name, email, password_hash, role)
        )
        connection.commit()
        
        user_id = cursor.lastrowid
        cursor.close()
        connection.close()
        
        return jsonify({
            'message': 'User registered successfully',
            'user_id': user_id
        }), 201
    except Error as e:
        connection.rollback()
        cursor.close()
        connection.close()
        return jsonify({'error': str(e)}), 500

@app.route('/api/login', methods=['POST'])
def login():
    """Login user"""
    data = request.get_json()
    email = data.get('email')
    password = data.get('password')
    
    if not email or not password:
        return jsonify({'error': 'Missing email or password'}), 400
    
    connection = get_db_connection()
    if not connection:
        return jsonify({'error': 'Database connection failed'}), 500
    
    try:
        cursor = connection.cursor(dictionary=True)
        cursor.execute("SELECT * FROM Users WHERE email = %s", (email,))
        user = cursor.fetchone()
        
        if not user:
            return jsonify({'error': 'Invalid credentials'}), 401
        
        # Verify password
        if not bcrypt.checkpw(password.encode('utf-8'), user['password_hash'].encode('utf-8')):
            return jsonify({'error': 'Invalid credentials'}), 401
        
        cursor.close()
        connection.close()
        
        return jsonify({
            'message': 'Login successful',
            'user': {
                'user_id': user['user_id'],
                'name': user['name'],
                'email': user['email'],
                'role': user['role']
            }
        }), 200
    except Error as e:
        cursor.close()
        connection.close()
        return jsonify({'error': str(e)}), 500


@app.route('/api/event-types', methods=['GET'])
def get_event_types():
    """Get all event types from DB - used to build dropdown dynamically (not hard-coded)"""
    connection = get_db_connection()
    if not connection:
        return jsonify({'error': 'Database connection failed'}), 500
    try:
        cursor = connection.cursor(dictionary=True)
        cursor.execute("SELECT type_id, type_name FROM EventTypes ORDER BY type_name")
        rows = cursor.fetchall()
        cursor.close()
        connection.close()
        return jsonify(rows), 200
    except Error as e:
        cursor.close()
        connection.close()
        return jsonify({'error': str(e)}), 500


@app.route('/api/events', methods=['GET'])
def get_events():
    """Get all events with optional filters (parameterized - SQL injection safe)"""
    start_date = request.args.get('start_date')
    end_date = request.args.get('end_date')
    location_id = request.args.get('location_id')
    type_id = request.args.get('type_id')
    
    connection = get_db_connection()
    if not connection:
        return jsonify({'error': 'Database connection failed'}), 500
    
    try:
        cursor = connection.cursor(dictionary=True)
        
        query = """
            SELECT e.*, l.name as location_name, l.address as location_address,
                   t.type_name as event_type_name
            FROM Events e
            LEFT JOIN Locations l ON e.location_id = l.location_id
            LEFT JOIN EventTypes t ON e.type_id = t.type_id
            WHERE 1=1
        """
        params = []
        
        if start_date:
            query += " AND e.date >= %s"
            params.append(start_date)
        if end_date:
            query += " AND e.date <= %s"
            params.append(end_date)
        if location_id:
            query += " AND e.location_id = %s"
            params.append(location_id)
        if type_id:
            query += " AND e.type_id = %s"
            params.append(type_id)
        
        query += " ORDER BY e.date, e.time"
        
        cursor.execute(query, params)
        events = cursor.fetchall()
        
        for event in events:
            if event.get('date'):
                event['date'] = event['date'].isoformat() if isinstance(event['date'], datetime) else str(event['date'])
            if event.get('time'):
                event['time'] = str(event['time'])
            event['event_type'] = event.get('event_type_name') or 'Other'
            if event.get('location_name'):
                event['location_name'] = normalize_location_name(event['location_name'])
            if event.get('location_address') is not None:
                event['location_address'] = normalize_location_address(event.get('location_address') or '')
        
        cursor.close()
        connection.close()
        return jsonify(events), 200
    except Error as e:
        cursor.close()
        connection.close()
        return jsonify({'error': str(e)}), 500

@app.route('/api/events/<int:event_id>', methods=['GET'])
def get_event(event_id):
    """Get a specific event by ID (parameterized)"""
    connection = get_db_connection()
    if not connection:
        return jsonify({'error': 'Database connection failed'}), 500
    
    try:
        cursor = connection.cursor(dictionary=True)
        
        cursor.execute("""
            SELECT e.*, l.name as location_name, l.address as location_address,
                   t.type_name as event_type_name
            FROM Events e
            LEFT JOIN Locations l ON e.location_id = l.location_id
            LEFT JOIN EventTypes t ON e.type_id = t.type_id
            WHERE e.event_id = %s
        """, (event_id,))
        event = cursor.fetchone()
        
        if not event:
            return jsonify({'error': 'Event not found'}), 404
        
        cursor.execute("""
            SELECT u.user_id, u.name, u.email
            FROM EventOrganizers eo
            JOIN Users u ON eo.user_id = u.user_id
            WHERE eo.event_id = %s
        """, (event_id,))
        organizers = cursor.fetchall()
        event['organizers'] = organizers
        event['event_type'] = event.get('event_type_name') or 'Other'
        if event.get('location_name'):
            event['location_name'] = normalize_location_name(event['location_name'])
        if event.get('location_address') is not None:
            event['location_address'] = normalize_location_address(event.get('location_address') or '')
        cursor.execute("""
            SELECT status, COUNT(*) as cnt FROM RSVPs WHERE event_id = %s GROUP BY status
        """, (event_id,))
        for row in cursor.fetchall():
            event[f"rsvp_{row['status']}_count"] = row['cnt']
        event.setdefault('rsvp_yes_count', 0)
        event.setdefault('rsvp_no_count', 0)
        event.setdefault('rsvp_maybe_count', 0)
        if event.get('date'):
            event['date'] = event['date'].isoformat() if isinstance(event['date'], datetime) else str(event['date'])
        if event.get('time'):
            event['time'] = str(event['time'])
        
        cursor.close()
        connection.close()
        return jsonify(event), 200
    except Error as e:
        cursor.close()
        connection.close()
        return jsonify({'error': str(e)}), 500

@app.route('/api/events', methods=['POST'])
def create_event():
    """Create a new event - Requirement 1 insert (parameterized)"""
    data = request.get_json()
    
    required_fields = ['title', 'date', 'time', 'duration', 'location_id', 'type_id']
    for field in required_fields:
        if field not in data:
            return jsonify({'error': f'Missing required field: {field}'}), 400
    
    connection = get_db_connection()
    if not connection:
        return jsonify({'error': 'Database connection failed'}), 500
    
    try:
        cursor = connection.cursor()
        cursor.execute("""
            INSERT INTO Events (title, date, time, duration, description, location_id, type_id, max_capacity, location_description, created_by)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        """, (
            data['title'],
            data['date'],
            data['time'],
            data['duration'],
            data.get('description', ''),
            data['location_id'],
            data['type_id'],
            data.get('max_capacity'),
            data.get('location_description') or '',
            data.get('created_by'),
        ))
        
        event_id = cursor.lastrowid
        
        organizer_ids = data.get('organizer_ids')
        if isinstance(organizer_ids, list) and len(organizer_ids) > 0:
            for user_id in organizer_ids:
                cursor.execute(
                    "INSERT INTO EventOrganizers (event_id, user_id) VALUES (%s, %s)",
                    (event_id, user_id)
                )
        else:
            # Default: creator is the sole organizer
            created_by = data.get('created_by')
            if created_by is not None:
                cursor.execute(
                    "INSERT INTO EventOrganizers (event_id, user_id) VALUES (%s, %s)",
                    (event_id, created_by)
                )
        
        connection.commit()
        cursor.close()
        connection.close()
        return jsonify({'message': 'Event created successfully', 'event_id': event_id}), 201
    except Error as e:
        connection.rollback()
        cursor.close()
        connection.close()
        return jsonify({'error': str(e)}), 500

@app.route('/api/events/<int:event_id>', methods=['PUT'])
def update_event(event_id):
    """Update an existing event (admin/organizer only)"""
    data = request.get_json()
    
    connection = get_db_connection()
    if not connection:
        return jsonify({'error': 'Database connection failed'}), 500
    
    try:
        cursor = connection.cursor()
        
        # Update event fields
        update_fields = []
        params = []
        
        fields_mapping = {
            'title': 'title',
            'date': 'date',
            'time': 'time',
            'duration': 'duration',
            'description': 'description',
            'location_id': 'location_id',
            'type_id': 'type_id',
            'max_capacity': 'max_capacity',
            'location_description': 'location_description',
            'created_by': 'created_by',
        }
        
        for key, column in fields_mapping.items():
            if key in data:
                update_fields.append(f"{column} = %s")
                params.append(data[key])
        
        if update_fields:
            params.append(event_id)
            query = f"UPDATE Events SET {', '.join(update_fields)} WHERE event_id = %s"
            cursor.execute(query, params)
        

        if 'organizer_ids' in data:
            # Delete existing organizers
            cursor.execute("DELETE FROM EventOrganizers WHERE event_id = %s", (event_id,))
            # Insert new organizers
            if isinstance(data['organizer_ids'], list):
                for user_id in data['organizer_ids']:
                    cursor.execute(
                        "INSERT INTO EventOrganizers (event_id, user_id) VALUES (%s, %s)",
                        (event_id, user_id)
                    )
        
        connection.commit()
        cursor.close()
        connection.close()
        
        return jsonify({'message': 'Event updated successfully'}), 200
    except Error as e:
        connection.rollback()
        cursor.close()
        connection.close()
        return jsonify({'error': str(e)}), 500

@app.route('/api/events/<int:event_id>', methods=['DELETE'])
def delete_event(event_id):
    """Delete an event (=organizer only)"""
    connection = get_db_connection()
    if not connection:
        return jsonify({'error': 'Database connection failed'}), 500
    
    try:
        cursor = connection.cursor()
        
        # Delete related records first
        cursor.execute("DELETE FROM RSVPs WHERE event_id = %s", (event_id,))
        cursor.execute("DELETE FROM EventOrganizers WHERE event_id = %s", (event_id,))
        cursor.execute("DELETE FROM Events WHERE event_id = %s", (event_id,))
        
        connection.commit()
        cursor.close()
        connection.close()
        
        return jsonify({'message': 'Event deleted successfully'}), 200
    except Error as e:
        connection.rollback()
        cursor.close()
        connection.close()
        return jsonify({'error': str(e)}), 500

# ============ RSVP ENDPOINTS ============

@app.route('/api/events/<int:event_id>/rsvp', methods=['POST'])
def create_rsvp(event_id):
    """Create or update RSVP for an event"""
    data = request.get_json()
    user_id = data.get('user_id')
    status = data.get('status')  # 'yes', 'no', 'maybe'
    
    if not user_id or not status:
        return jsonify({'error': 'Missing user_id or status'}), 400
    
    if status not in ['yes', 'no', 'maybe']:
        return jsonify({'error': 'Invalid status. Must be yes, no, or maybe'}), 400
    
    connection = get_db_connection()
    if not connection:
        return jsonify({'error': 'Database connection failed'}), 500
    
    try:
        cursor = connection.cursor()
        
        # Check if RSVP already exists
        cursor.execute(
            "SELECT * FROM RSVPs WHERE event_id = %s AND user_id = %s",
            (event_id, user_id)
        )
        existing = cursor.fetchone()
        
        if existing:
            # Update existing RSVP
            cursor.execute(
                "UPDATE RSVPs SET status = %s, updated_at = NOW() WHERE event_id = %s AND user_id = %s",
                (status, event_id, user_id)
            )
        else:
            cursor.execute(
                "INSERT INTO RSVPs (event_id, user_id, status) VALUES (%s, %s, %s)",
                (event_id, user_id, status)
            )
        
        connection.commit()
        cursor.close()
        connection.close()
        
        return jsonify({'message': 'RSVP updated successfully'}), 200
    except Error as e:
        connection.rollback()
        cursor.close()
        connection.close()
        return jsonify({'error': str(e)}), 500

# ============ LOCATION TYPES (for "what kind of place" dropdown) ============

@app.route('/api/location-types', methods=['GET'])
def get_location_types():
    """Get all location types (Parking Lot, Coffee Shop, Car Wash, etc.) - for adding locations anywhere"""
    connection = get_db_connection()
    if not connection:
        return jsonify({'error': 'Database connection failed'}), 500
    try:
        cursor = connection.cursor(dictionary=True)
        cursor.execute("SELECT location_type_id, type_name FROM LocationTypes ORDER BY type_name")
        rows = cursor.fetchall()
        cursor.close()
        connection.close()
        return jsonify(rows), 200
    except Error as e:
        cursor.close()
        connection.close()
        return jsonify({'error': str(e)}), 500


@app.route('/api/locations', methods=['GET'])
def get_locations():
    """Get all locations (from DB - used in filters and event form everywhere)"""
    connection = get_db_connection()
    if not connection:
        return jsonify({'error': 'Database connection failed'}), 500
    
    try:
        cursor = connection.cursor(dictionary=True)
        try:
            cursor.execute("""
                SELECT l.*, t.type_name as location_type_name
                FROM Locations l
                LEFT JOIN LocationTypes t ON l.location_type_id = t.location_type_id
                ORDER BY l.name
            """)
        except Error:
            cursor.execute("SELECT * FROM Locations ORDER BY name")
        locations = cursor.fetchall()
        for loc in locations:
            if loc.get('name'):
                loc['name'] = normalize_location_name(loc['name'])
        cursor.close()
        connection.close()
        
        return jsonify(locations), 200
    except Error as e:
        cursor.close()
        connection.close()
        return jsonify({'error': str(e)}), 500

@app.route('/api/locations', methods=['POST'])
def create_location():
    """Add a new location (so filters and events can use it anywhere - not fixed to one region)"""
    data = request.get_json()
    if not data or not data.get('name'):
        return jsonify({'error': 'Name is required'}), 400
    
    connection = get_db_connection()
    if not connection:
        return jsonify({'error': 'Database connection failed'}), 500
    
    try:
        cursor = connection.cursor()
        cursor.execute("""
            INSERT INTO Locations (name, address, city, state, zip_code, capacity, description, location_type_id)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
        """, (
            data.get('name'),
            data.get('address'),
            data.get('city'),
            data.get('state'),
            data.get('zip_code'),
            data.get('capacity'),
            data.get('description'),
            data.get('location_type_id'),
        ))
        connection.commit()
        location_id = cursor.lastrowid
        cursor.close()
        connection.close()
        return jsonify({'message': 'Location created', 'location_id': location_id}), 201
    except Error as e:
        connection.rollback()
        cursor.close()
        connection.close()
        return jsonify({'error': str(e)}), 500

# ============ USERS ENDPOINTS ============

@app.route('/api/users', methods=['GET'])
def get_users():
    """Get all users (for selecting organizers)"""
    connection = get_db_connection()
    if not connection:
        return jsonify({'error': 'Database connection failed'}), 500
    
    try:
        cursor = connection.cursor(dictionary=True)
        cursor.execute("SELECT user_id, name, email, role FROM Users ORDER BY name")
        users = cursor.fetchall()
        cursor.close()
        connection.close()
        
        return jsonify(users), 200
    except Error as e:
        cursor.close()
        connection.close()
        return jsonify({'error': str(e)}), 500

# ============ REPORTS ENDPOINTS (Requirement 2) ============

@app.route('/api/reports/events', methods=['GET'])
def get_event_report():
    """Filtered event report with statistics (date range, type_id, location_id) - parameterized"""
    start_date = request.args.get('start_date')
    end_date = request.args.get('end_date')
    location_id = request.args.get('location_id')
    type_id = request.args.get('type_id')
    
    connection = get_db_connection()
    if not connection:
        return jsonify({'error': 'Database connection failed'}), 500
    
    try:
        cursor = connection.cursor(dictionary=True)
        
        where_clause = "WHERE 1=1"
        params = []
        if start_date:
            where_clause += " AND e.date >= %s"
            params.append(start_date)
        if end_date:
            where_clause += " AND e.date <= %s"
            params.append(end_date)
        if location_id:
            where_clause += " AND e.location_id = %s"
            params.append(location_id)
        if type_id:
            where_clause += " AND e.type_id = %s"
            params.append(type_id)
        
        events_query = """
            SELECT e.*, l.name as location_name, l.address as location_address,
                   t.type_name as event_type_name
            FROM Events e
            LEFT JOIN Locations l
            ON e.location_id = l.location_id
            LEFT JOIN EventTypes t
            ON e.type_id = t.type_id
            """ + where_clause + " ORDER BY e.date, e.time"
        cursor.execute(events_query, params)
        events = cursor.fetchall()
        
        for event in events:
            if event.get('date'):
                event['date'] = event['date'].isoformat() if isinstance(event['date'], datetime) else str(event['date'])
            if event.get('time'):
                event['time'] = str(event['time'])
            event['event_type'] = event.get('event_type_name') or 'Other'
            if event.get('location_name'):
                event['location_name'] = normalize_location_name(event['location_name'])
            if event.get('location_address') is not None:
                event['location_address'] = normalize_location_address(event.get('location_address') or '')
        
        stats_query = """
            SELECT COUNT(*) as total_events,
            AVG(e.duration) as avg_duration
            FROM Events e
            """ + where_clause
        cursor.execute(stats_query, params)
        stats = cursor.fetchone()
        
        event_ids = [e['event_id'] for e in events]
        avg_yes_count = 0.0
        avg_total_rsvp = 0.0
        if event_ids:
            placeholders = ','.join(['%s'] * len(event_ids))
            cursor.execute(
                """
                SELECT event_id,
                       SUM(CASE WHEN status = 'yes' THEN 1 ELSE 0 END) as yes_count,
                       COUNT(*) as total_rsvp
                FROM RSVPs WHERE event_id IN (""" + placeholders + """) GROUP BY event_id
                """,
                tuple(event_ids)
            )
            rsvp_rows = cursor.fetchall()
            if rsvp_rows:
                avg_yes_count = sum(r['yes_count'] for r in rsvp_rows) / len(rsvp_rows)
                avg_total_rsvp = sum(r['total_rsvp'] for r in rsvp_rows) / len(rsvp_rows)
        
        cursor.close()
        connection.close()
        
        return jsonify({
            'events': events,
            'statistics': {
                'total_events': stats['total_events'] or 0,
                'avg_duration': float(stats['avg_duration'] or 0),
                'avg_yes_rsvps': round(avg_yes_count, 1),
                'avg_total_rsvps': round(avg_total_rsvp, 1),
            }
        }), 200
    except Error as e:
        cursor.close()
        connection.close()
        return jsonify({'error': str(e)}), 500

# ============ HEALTH CHECK ============

@app.route('/api/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({'status': 'ok', 'message': 'Car Meet API is running'}), 200

if __name__ == '__main__':
    port = int(os.getenv('PORT', 5001))
    app.run(debug=True, host='0.0.0.0', port=port)
