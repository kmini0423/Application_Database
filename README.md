Car Meet Management App
CS348 Project - A database-backed mobile application for managing car meet events.

Project Overview
This is a Flutter mobile application with a Flask backend and MySQL database. The app allows users to discover car meet events, RSVP to events, and provides admin/organizer functionality to create and manage events.

Tech Stack
Frontend: Flutter (Dart)
Backend: Flask (Python)
Database: MySQL
Project Structure
Project/
├── backend/              # Flask backend API
│   ├── app.py           # Main Flask application
│   ├── requirements.txt # Python dependencies
│   ├── database/
│   │   └── schema.sql   # Database schema
│   └── README.md        # Backend setup instructions
├── lib/                 # Flutter application code
│   ├── main.dart        # App entry point
│   ├── models/          # Data models
│   ├── screens/         # UI screens
│   └── services/        # API services
└── README.md           # This file
Setup Instructions
Prerequisites
Flutter: Install Flutter SDK from flutter.dev
Python: Python 3.8+ installed
MySQL: MySQL server installed and running
MySQL Client: For running SQL scripts
Backend Setup
Navigate to the backend directory:
cd backend
Create a virtual environment (recommended):
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
Install Python dependencies:
pip install -r requirements.txt
Create a .env file in the backend directory:
DB_HOST=localhost
DB_NAME=carmeet_db
DB_USER=root
DB_PASSWORD=your_password
DB_PORT=3306
Create the database:
mysql -u root -p < database/schema.sql
Start the Flask server:
python app.py
The API will be available at http://localhost:5001 (see PORT in backend/app.py / .env).

Frontend Setup
Install Flutter dependencies:
flutter pub get
Update API endpoint in lib/services/api_service.dart:

For Android emulator: e.g. 'http://10.0.2.2:5001/api'
For iOS simulator: e.g. 'http://localhost:5001/api'
For physical device: your computer's IP, e.g. 'http://192.168.1.100:5001/api'
Run the Flutter app:

flutter run
Database Schema
The application uses the following main tables:

Users: User accounts with roles (user, organizer, admin)
Events: Car meet events (main table for Requirement 1)
EventOrganizers: Links events to organizers (supporting table)
Locations: Event locations
RSVPs: User RSVPs for events
See backend/database/schema.sql for complete schema definition.

Features
Stage 1 ✅
Hello World page demonstrating Flutter setup
Basic app structure
Main Features
Requirement 1: Event CRUD (Admin/Organizer)
Create, edit, and delete events
Select multiple organizers for each event
Choose location from database
Full CRUD operations on the Events table
Requirement 2: Event Reports
Filter events by date range, location, and event type
Display filtered event list
Show statistics:
Total events
Average duration (minutes)
Average “yes” RSVPs per event (among events with RSVPs)
Average total RSVPs per event
Additional Features
User registration and authentication
Role-based access control
RSVP functionality (Yes/No/Maybe)
Event discovery with filters
Event detail view
API Endpoints
Authentication
POST /api/register - Register new user
POST /api/login - Login user
Events
GET /api/events - Get all events (with filters)
GET /api/events/<id> - Get specific event
POST /api/events - Create event (admin/organizer)
PUT /api/events/<id> - Update event (admin/organizer)
DELETE /api/events/<id> - Delete event (admin/organizer)
RSVP
POST /api/events/<id>/rsvp - Create/update RSVP
Reports
GET /api/reports/events - Generate event report with statistics
See backend/README.md for complete API documentation.

Sample Data
The database schema includes sample data:

3 locations
3 users (admin, organizer, regular user)
3 sample events
Password for all sample users: password123
Demo Credentials
Admin: admin@carmeet.com / password123
Organizer: organizer@carmeet.com / password123
User: user@carmeet.com / password123
Notes
The app uses HTTP (not HTTPS) for local development
CORS is enabled on the Flask backend for development
Database password hashing uses bcrypt
The Flutter app needs the backend running to function
Stage 3 submission
Recorded demo (5–10 min): Follow STAGE3_DEMO_SCRIPT.md — cover SQL injection protection, indexes, transactions/isolation, and AI usage (see AI_USAGE.md).

Technical reference (for narration): STAGE3_TECHNICAL.md — code locations, index-to-query mapping, transaction discussion.

AI disclosure (required): AI_USAGE.md

Source code URL: Add your GitHub repository link here after publishing:

Repository: https://github.com/YOUR_USERNAME/YOUR_REPO (replace with your link)
Live application URL (optional; extra credit if deployed to GCP/AWS/Azure):

Production: (add URL if applicable; keep instance running through the grading window if required by the syllabus)
Future Enhancements
Push notifications for event updates
Event search functionality
User profiles
Event comments/reviews
Image uploads for events
Map integration for locations
