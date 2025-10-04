# Quickstart Guide: 番茄工作法任务与时间管理应用

**Generated**: 2025-10-03
**Branch**: `001-`
**Purpose**: Integration test scenarios derived from user stories in [spec.md](./spec.md)

## Prerequisites

1. **Development Environment**:
   - Flutter SDK 3.5+ installed
   - Node.js 20+ for backend
   - Tauri CLI for desktop builds
   - Docker for local Supabase instance

2. **Test Data Setup**:
   - User account: `test@example.com` / `password123`
   - Sample tasks with due dates
   - Active Pomodoro session for testing

## Core User Flow Integration Tests

### Test Scenario 1: Complete Pomodoro Workflow
**Validates**: FR-001 through FR-008 (Pomodoro Timer functionality)

**Steps**:
1. **Register/Login** a new user via API
2. **Create a task** with subtasks
3. **Start a Pomodoro session** for the task
4. **Verify timer countdown** continues in background
5. **Complete the session** and verify notification
6. **Check session was recorded** with correct duration

**Expected Results**:
- ✅ Timer runs for exactly 25 minutes (±1 second precision)
- ✅ Push notification delivered when session completes
- ✅ Session record created with `status: "completed"`
- ✅ Task shows 1 completed Pomodoro session

### Test Scenario 2: Task Management & Reminders
**Validates**: FR-010 through FR-020 (Task Management & Reminders)

**Steps**:
1. **Create task with due date** (1 hour from now)
2. **Add subtasks** to break down the work
3. **Set custom reminder** (30 minutes before due date)
4. **Wait for reminder notification** to be triggered
5. **Mark task as complete**

**Expected Results**:
- ✅ Reminder notification sent exactly 30 minutes before due date
- ✅ Subtasks can be created, edited, and marked complete
- ✅ Task completion updates all subtasks and records completion time

### Test Scenario 3: Cross-Device Sync
**Validates**: FR-029 through FR-033 (Multi-device Sync)

**Steps**:
1. **Create task on Device A** (mobile app)
2. **Add note to task on Device B** (web app)
3. **Start Pomodoro on Device C** (desktop app)
4. **Complete task on Device A**
5. **Verify sync across all devices**

**Expected Results**:
- ✅ Task appears on all devices within 5 seconds (real-time sync)
- ✅ Notes and Pomodoro sessions sync correctly
- ✅ Last-write-wins resolves conflicts by timestamp
- ✅ Offline changes sync when connection restored

### Test Scenario 4: Reports & Analytics
**Validates**: FR-024 through FR-028 (Reports & Analytics)

**Setup**: Complete 5 Pomodoro sessions over 3 days with different tasks

**Steps**:
1. **Generate weekly report**
2. **Verify report metrics**: Sessions completed, focus time, completion rate, trends

**Expected Results**:
- ✅ Report shows accurate session count (5)
- ✅ Focus time totals correctly (125 minutes)
- ✅ Visual charts display productivity trends
- ✅ Historical data accessible for full time period

### Test Scenario 5: Recurring Tasks
**Validates**: FR-016 through FR-018 (Recurring Tasks)

**Steps**:
1. **Create daily recurring task** (stand-up meeting notes)
2. **Complete today's instance**
3. **Verify tomorrow's instance** is auto-generated
4. **Modify single instance** without affecting series
5. **Delete entire series** and verify cleanup

**Expected Results**:
- ✅ New task instance created automatically each day
- ✅ Single instance modifications don't affect series
- ✅ Series deletion removes all future instances
- ✅ Recurrence rules respect end date settings

## Performance Validation

### API Response Times
**Target**: <200ms at p95

### UI Responsiveness
**Target**: <100ms for interactions

### Timer Precision
**Target**: ±1 second accuracy

## Platform-Specific Tests

### Mobile (iOS/Android)
- **Background execution**: Timer continues when app minimized
- **Push notifications**: Delivered even when app closed
- **Offline mode**: Tasks can be created without internet

### Web Browser
- **Service worker**: Enables offline functionality
- **Web push**: Notifications work in supported browsers
- **Responsive design**: UI adapts to different screen sizes

### Desktop (Tauri)
- **System tray**: App minimizes to system tray
- **Native notifications**: OS-level notification integration
- **Auto-startup**: Option to launch on system boot

This quickstart guide serves as both user acceptance criteria and integration test specification. All scenarios must pass before deployment to production.