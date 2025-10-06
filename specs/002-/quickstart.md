# Quickstart Guide: Project Management System

**Feature**: 002- Project Management System
**Purpose**: Validate the project management feature end-to-end

## Prerequisites

- Docker and Docker Compose installed
- Go 1.21+ installed
- Flutter 3.24.3+ installed
- PostgreSQL client (psql) for database inspection

## Setup

### 1. Start Infrastructure

```bash
# From repository root
docker-compose up -d postgres redis

# Wait for services to be ready
sleep 5

# Verify PostgreSQL is running
docker-compose ps postgres
```

### 2. Run Database Migration

```bash
# Apply migration 002
cd backend
psql $DATABASE_URL -f migrations/002_add_projects.sql

# Verify tables created
psql $DATABASE_URL -c "\dt projects"
psql $DATABASE_URL -c "\d projects"
```

Expected output:
- `projects` table exists
- `tasks.project_id` column exists and is NOT NULL
- `pomodoro_sessions.project_id` column exists

### 3. Start Backend API

```bash
# Terminal 1: Start Go backend
cd backend
go run main.go

# Should see:
# [GIN] Listening on :8081
```

### 4. Start Frontend (Optional)

```bash
# Terminal 2: Start Flutter web
cd mobile
flutter run -d web-server --web-port 3001 --web-hostname 0.0.0.0

# Or use standalone web app
cd mobile/build/web
python3 -m http.server 3002
```

## Test Scenarios

### Scenario 1: Default "Inbox" Project Auto-Creation

**Objective**: Verify new users automatically get an "Inbox" project

**Steps**:

1. **Create Test User** (if not exists):
```bash
curl -X POST http://localhost:8081/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'
```

2. **Login and Get Token**:
```bash
TOKEN=$(curl -X POST http://localhost:8081/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }' | jq -r '.token')

echo "Token: $TOKEN"
```

3. **List Projects** (should include Inbox):
```bash
curl -X GET http://localhost:8081/v1/projects \
  -H "Authorization: Bearer $TOKEN" | jq
```

**Expected Result**:
```json
{
  "data": [
    {
      "id": "...",
      "name": "Inbox",
      "is_default": true,
      "is_completed": false,
      ...
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 1,
    "total_pages": 1
  }
}
```

**Validation**:
- ✅ Exactly one project exists
- ✅ Project name is "Inbox"
- ✅ `is_default` is `true`
- ✅ Cannot be deleted

---

### Scenario 2: Create Custom Project

**Objective**: Create a new project and verify it appears in list

**Steps**:

1. **Create Project**:
```bash
curl -X POST http://localhost:8081/v1/projects \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Website Redesign",
    "description": "Q4 2025 redesign project"
  }' | jq
```

**Expected Result**:
```json
{
  "id": "...",
  "name": "Website Redesign",
  "description": "Q4 2025 redesign project",
  "is_default": false,
  "is_completed": false,
  "created_at": "2025-10-05T...",
  "updated_at": "2025-10-05T..."
}
```

2. **List Projects Again**:
```bash
curl -X GET http://localhost:8081/v1/projects \
  -H "Authorization: Bearer $TOKEN" | jq '.data | length'
```

**Expected**: `2` (Inbox + Website Redesign)

**Validation**:
- ✅ Project created successfully (201 status)
- ✅ Returns complete project object with ID
- ✅ `is_default` is `false`
- ✅ Now have 2 total projects

---

### Scenario 3: Create Task in Project

**Objective**: Create task associated with project, verify enforcement

**Steps**:

1. **Get Project ID**:
```bash
PROJECT_ID=$(curl -X GET http://localhost:8081/v1/projects \
  -H "Authorization: Bearer $TOKEN" | jq -r '.data[] | select(.name=="Website Redesign") | .id')

echo "Project ID: $PROJECT_ID"
```

2. **Create Task Without project_id** (should fail):
```bash
curl -X POST http://localhost:8081/v1/tasks \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Design mockups"
  }'
```

**Expected Result**: `400 Bad Request` with error message about missing project_id

3. **Create Task With project_id** (should succeed):
```bash
curl -X POST http://localhost:8081/v1/tasks \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"name\": \"Design mockups\",
    \"description\": \"Create homepage and landing page mockups\",
    \"project_id\": \"$PROJECT_ID\",
    \"priority\": 3,
    \"estimated_pomodoros\": 4
  }" | jq
```

**Expected Result**:
```json
{
  "id": "...",
  "name": "Design mockups",
  "project_id": "<PROJECT_ID>",
  "is_completed": false,
  "priority": 3,
  "estimated_pomodoros": 4,
  ...
}
```

**Validation**:
- ✅ Task creation without project_id fails (400)
- ✅ Task creation with project_id succeeds (201)
- ✅ Task.project_id matches provided project

---

### Scenario 4: Project Statistics

**Objective**: Verify statistics calculation for project

**Steps**:

1. **Create Multiple Tasks in Project**:
```bash
# Task 1 (already created above)

# Task 2
curl -X POST http://localhost:8081/v1/tasks \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"name\": \"Implement header\",
    \"project_id\": \"$PROJECT_ID\",
    \"priority\": 2
  }"

# Task 3
curl -X POST http://localhost:8081/v1/tasks \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"name\": \"User testing\",
    \"project_id\": \"$PROJECT_ID\",
    \"priority\": 1
  }"
```

2. **Get Project Statistics**:
```bash
curl -X GET "http://localhost:8081/v1/projects/$PROJECT_ID/statistics" \
  -H "Authorization: Bearer $TOKEN" | jq
```

**Expected Result**:
```json
{
  "total_tasks": 3,
  "completed_tasks": 0,
  "pending_tasks": 3,
  "completion_percent": 0.0,
  "total_pomodoros": 0,
  "total_time_seconds": 0,
  "total_time_formatted": "0h 0m",
  "avg_pomodoro_duration_sec": 0,
  "last_activity_at": null
}
```

**Validation**:
- ✅ `total_tasks` = 3
- ✅ `completed_tasks` = 0
- ✅ `completion_percent` = 0.0
- ✅ All time stats are 0 (no Pomodoros yet)

---

### Scenario 5: Complete Task and Track Pomodoro

**Objective**: Track Pomodoro session, verify project statistics update

**Steps**:

1. **Get First Task ID**:
```bash
TASK_ID=$(curl -X GET "http://localhost:8081/v1/projects/$PROJECT_ID/tasks" \
  -H "Authorization: Bearer $TOKEN" | jq -r '.data[0].id')

echo "Task ID: $TASK_ID"
```

2. **Start Pomodoro Session**:
```bash
curl -X POST http://localhost:8081/v1/pomodoro/start \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"task_id\": \"$TASK_ID\"
  }" | jq
```

3. **Complete Pomodoro** (after 25 min or manually):
```bash
SESSION_ID=$(curl -X GET http://localhost:8081/v1/pomodoro/current \
  -H "Authorization: Bearer $TOKEN" | jq -r '.id')

curl -X POST "http://localhost:8081/v1/pomodoro/$SESSION_ID/complete" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "duration": 1500
  }' | jq
```

4. **Re-check Project Statistics**:
```bash
curl -X GET "http://localhost:8081/v1/projects/$PROJECT_ID/statistics" \
  -H "Authorization: Bearer $TOKEN" | jq
```

**Expected Result**:
```json
{
  "total_tasks": 3,
  "completed_tasks": 0,
  "pending_tasks": 3,
  "completion_percent": 0.0,
  "total_pomodoros": 1,
  "total_time_seconds": 1500,
  "total_time_formatted": "0h 25m",
  "avg_pomodoro_duration_sec": 1500,
  "last_activity_at": "2025-10-05T..."
}
```

**Validation**:
- ✅ `total_pomodoros` = 1
- ✅ `total_time_seconds` = 1500 (25 minutes)
- ✅ `last_activity_at` is recent timestamp

---

### Scenario 6: Manual Project Completion

**Objective**: Mark project complete manually, verify tasks still accessible

**Steps**:

1. **Mark Project Complete** (with pending tasks):
```bash
curl -X POST "http://localhost:8081/v1/projects/$PROJECT_ID/complete" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "is_completed": true
  }' | jq
```

**Expected Result**:
```json
{
  "id": "<PROJECT_ID>",
  "name": "Website Redesign",
  "is_completed": true,
  ...
}
```

2. **Verify Tasks Still Accessible**:
```bash
curl -X GET "http://localhost:8081/v1/projects/$PROJECT_ID/tasks" \
  -H "Authorization: Bearer $TOKEN" | jq '.data | length'
```

**Expected**: `3` (all tasks still there)

3. **Create New Task in Completed Project** (should succeed):
```bash
curl -X POST http://localhost:8081/v1/tasks \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"name\": \"Post-launch task\",
    \"project_id\": \"$PROJECT_ID\"
  }" | jq '.id'
```

**Expected**: `201 Created` (task creation succeeds)

**Validation**:
- ✅ Project marked complete (is_completed = true)
- ✅ Tasks remain accessible
- ✅ Can create new tasks in completed project
- ✅ Can start Pomodoro sessions in completed project

---

### Scenario 7: Project Deletion with Cascade

**Objective**: Delete project, verify tasks and sessions cascade

**Steps**:

1. **Count Tasks Before Deletion**:
```bash
TASK_COUNT=$(curl -X GET "http://localhost:8081/v1/projects/$PROJECT_ID/tasks" \
  -H "Authorization: Bearer $TOKEN" | jq '.data | length')

echo "Tasks before deletion: $TASK_COUNT"
```

2. **Delete Project**:
```bash
curl -X DELETE "http://localhost:8081/v1/projects/$PROJECT_ID" \
  -H "Authorization: Bearer $TOKEN" \
  -I
```

**Expected**: `204 No Content`

3. **Verify Project Gone**:
```bash
curl -X GET "http://localhost:8081/v1/projects/$PROJECT_ID" \
  -H "Authorization: Bearer $TOKEN"
```

**Expected**: `404 Not Found`

4. **Verify Tasks Deleted** (check database):
```bash
psql $DATABASE_URL -c "SELECT COUNT(*) FROM tasks WHERE project_id = '$PROJECT_ID';"
```

**Expected**: `0` rows

5. **Verify Sessions Deleted** (check database):
```bash
psql $DATABASE_URL -c "SELECT COUNT(*) FROM pomodoro_sessions WHERE project_id = '$PROJECT_ID';"
```

**Expected**: `0` rows

**Validation**:
- ✅ Project deleted successfully (204)
- ✅ All tasks cascade deleted
- ✅ All sessions cascade deleted
- ✅ Database FK constraints enforced

---

### Scenario 8: Cannot Delete Default "Inbox" Project

**Objective**: Verify default project deletion prevention

**Steps**:

1. **Get Inbox Project ID**:
```bash
INBOX_ID=$(curl -X GET http://localhost:8081/v1/projects \
  -H "Authorization: Bearer $TOKEN" | jq -r '.data[] | select(.is_default==true) | .id')

echo "Inbox ID: $INBOX_ID"
```

2. **Attempt to Delete Inbox**:
```bash
curl -X DELETE "http://localhost:8081/v1/projects/$INBOX_ID" \
  -H "Authorization: Bearer $TOKEN" | jq
```

**Expected Result**:
```json
{
  "error": "forbidden",
  "message": "Cannot delete default project"
}
```

**Expected Status**: `403 Forbidden`

3. **Verify Inbox Still Exists**:
```bash
curl -X GET "http://localhost:8081/v1/projects/$INBOX_ID" \
  -H "Authorization: Bearer $TOKEN" | jq '.name'
```

**Expected**: `"Inbox"`

**Validation**:
- ✅ Deletion attempt returns 403
- ✅ Error message is clear
- ✅ Inbox project still exists
- ✅ Can still use Inbox for tasks

---

## Integration Test: Complete User Flow

**Scenario**: New user journey through project management

```bash
#!/bin/bash
set -e

# 1. Register new user
echo "Step 1: Registering user..."
curl -X POST http://localhost:8081/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email": "newuser@example.com", "password": "pass123"}' > /dev/null

# 2. Login
echo "Step 2: Logging in..."
TOKEN=$(curl -s -X POST http://localhost:8081/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "newuser@example.com", "password": "pass123"}' | jq -r '.token')

# 3. Verify Inbox auto-created
echo "Step 3: Verifying Inbox..."
INBOX_ID=$(curl -s -X GET http://localhost:8081/v1/projects \
  -H "Authorization: Bearer $TOKEN" | jq -r '.data[0].id')
echo "  Inbox ID: $INBOX_ID"

# 4. Create project
echo "Step 4: Creating project..."
PROJECT_ID=$(curl -s -X POST http://localhost:8081/v1/projects \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name": "Mobile App", "description": "iOS app"}' | jq -r '.id')
echo "  Project ID: $PROJECT_ID"

# 5. Create task in project
echo "Step 5: Creating task..."
TASK_ID=$(curl -s -X POST http://localhost:8081/v1/tasks \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"name\": \"Design UI\", \"project_id\": \"$PROJECT_ID\"}" | jq -r '.id')
echo "  Task ID: $TASK_ID"

# 6. Start Pomodoro
echo "Step 6: Starting Pomodoro..."
SESSION_ID=$(curl -s -X POST http://localhost:8081/v1/pomodoro/start \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"task_id\": \"$TASK_ID\"}" | jq -r '.id')
echo "  Session ID: $SESSION_ID"

# 7. Check project statistics
echo "Step 7: Checking statistics..."
STATS=$(curl -s -X GET "http://localhost:8081/v1/projects/$PROJECT_ID/statistics" \
  -H "Authorization: Bearer $TOKEN")
echo "  Stats: $(echo $STATS | jq -c '{tasks: .total_tasks, pomodoros: .total_pomodoros}')"

# 8. Complete project
echo "Step 8: Completing project..."
curl -s -X POST "http://localhost:8081/v1/projects/$PROJECT_ID/complete" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"is_completed": true}' > /dev/null

echo "✅ All steps completed successfully!"
```

**Expected Output**:
```
Step 1: Registering user...
Step 2: Logging in...
Step 3: Verifying Inbox...
  Inbox ID: ...
Step 4: Creating project...
  Project ID: ...
Step 5: Creating task...
  Task ID: ...
Step 6: Starting Pomodoro...
  Session ID: ...
Step 7: Checking statistics...
  Stats: {"tasks":1,"pomodoros":0}
Step 8: Completing project...
✅ All steps completed successfully!
```

---

## Cleanup

```bash
# Stop all services
docker-compose down

# Remove test database (optional)
docker volume rm pomodoro-genie_postgres_data
```

---

## Troubleshooting

### Issue: Default project not created

**Check**:
```bash
psql $DATABASE_URL -c "SELECT * FROM projects WHERE is_default = true;"
```

**Fix**: Run migration again or manually create:
```sql
INSERT INTO projects (user_id, name, description, is_default)
VALUES ('{USER_ID}', 'Inbox', 'Default tasks', true);
```

### Issue: Tasks without project_id

**Check**:
```bash
psql $DATABASE_URL -c "SELECT COUNT(*) FROM tasks WHERE project_id IS NULL;"
```

**Fix**: This should be impossible (NOT NULL constraint), but if found:
```sql
UPDATE tasks SET project_id = (
  SELECT id FROM projects WHERE user_id = tasks.user_id AND is_default = true
) WHERE project_id IS NULL;
```

### Issue: Statistics not calculating

**Check query**:
```bash
psql $DATABASE_URL -c "
SELECT p.name, COUNT(t.id) as tasks, COUNT(ps.id) as pomodoros
FROM projects p
LEFT JOIN tasks t ON t.project_id = p.id
LEFT JOIN pomodoro_sessions ps ON ps.project_id = p.id
WHERE p.id = '{PROJECT_ID}'
GROUP BY p.name;
"
```

---

## Success Criteria

All scenarios pass when:
- ✅ Default "Inbox" project auto-created for new users
- ✅ Custom projects can be created/updated/deleted
- ✅ Tasks MUST have project_id (enforced)
- ✅ Pomodoro sessions track project context
- ✅ Project statistics calculate correctly
- ✅ Manual project completion works
- ✅ Cascade deletion works (project → tasks → sessions)
- ✅ Default "Inbox" cannot be deleted
- ✅ Completed projects remain fully functional

---

**Quickstart Status**: ✅ READY FOR EXECUTION

Run these tests after implementation to validate the feature.
