# AI Usage (CS 348 Semester Project)

This section satisfies the course disclosure requirement for AI-assisted work.

## Tools used

- **Cursor** (IDE with integrated coding assistant / agent)
- Occasional use of **general-purpose LLM chat** for high-level explanations (optional; primary work was in Cursor)

## Tasks the AI assisted with

- Brainstorming and refining **database schema** and migration SQL ideas
- **Flask API** structure, parameterized queries, and error-handling patterns
- **Flutter UI** wiring (screens, dialogs, navigation, API calls)
- Debugging **runtime errors** (layout, async, controller disposal)
- Drafting **documentation** and demo outlines (this file, Stage 3 technical notes)

## How outputs were verified and modified

- All **SQL** was run against MySQL and checked with real queries; schema matches `backend/database/schema.sql`
- All **API endpoints** were exercised from the Flutter app or HTTP client; responses validated against the DB
- **Security**: reviewed every `cursor.execute` path—user-controlled values are passed as **parameters** (`%s`), not concatenated into SQL strings (except **whitelisted** column names in dynamic `UPDATE`, see `STAGE3_TECHNICAL.md`)
- **Course alignment**: Requirement 1 (Events CRUD), Requirement 2 (report + filters), and Stage 3 topics (SQL injection, indexes, transactions) were cross-checked against the official project description
- AI-generated snippets were **edited** to match project conventions, naming, and grading rubric

## Student responsibility

The author understands and can explain **all** submitted code, schema choices, indexes, transaction boundaries, and security decisions. AI was used as a productivity aid, not as a substitute for learning.
