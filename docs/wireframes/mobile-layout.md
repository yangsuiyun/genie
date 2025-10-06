# Mobile Responsive Layout Wireframe

**Wireframe Type**: Mobile-first responsive design
**Target Breakpoint**: <768px (mobile devices)
**Navigation Pattern**: Bottom navigation + hamburger menu
**Dependencies**: Project data, task management, responsive design system

## Overview

This wireframe documents the mobile-first responsive layout that transforms the desktop project-first sidebar architecture into a mobile-optimized interface. The design prioritizes touch interaction, one-handed use, and efficient content access while maintaining the project-first organizational structure.

## Mobile Portrait Layout (320-768px)

### Primary Interface
```
┌─────────────────────────────────────────────────────────────┐
│  [≡] 🍅 Pomodoro Genie                    [🔔] [⚙️] [👤]   │  ← Header Bar
├─────────────────────────────────────────────────────────────┤
│                                                             │
│                      💼 Work Project                        │  ← Current Project Header
│                                                             │
│              ┌─────────────────────────────────────────┐     │
│              │  15任务  85%完成  24🍅  6h30m            │     │  ← Project Summary Card
│              └─────────────────────────────────────────┘     │
│                                                             │
│  📋 任务列表                                   [➕]         │  ← Section Header + Add Button
│                                                             │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ ☐ Complete project architecture design                 │ │  ← Task Card (Expanded)
│  │   Design frontend project-first architecture including │ │
│  │   left sidebar navigation and task management          │ │
│  │                                                       │ │
│  │   🔴 High Priority    📅 Oct 8    🍅 2/5              │ │  ← Task Metadata
│  │                                                       │ │
│  │   [🍅 Start Pomodoro]  [✏️ Edit]  [⋮ More]           │ │  ← Action Buttons
│  └─────────────────────────────────────────────────────────┘ │
│                                                             │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ ☐ Implement responsive layout                          │ │  ← Task Card (Compact)
│  │   Create mobile and desktop responsive design          │ │
│  │   🟡 Medium    📅 Oct 9    🍅 1/3    [🍅] [✏️] [⋮]   │ │  ← Inline Actions
│  └─────────────────────────────────────────────────────────┘ │
│                                                             │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │ ☑ Write API documentation                              │ │  ← Completed Task
│  │   Complete backend API interface documentation         │ │
│  │   ✅ Completed    📅 Oct 7    🍅 5/5                   │ │  ← Completed Metadata
│  └─────────────────────────────────────────────────────────┘ │
│                                                             │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│  [📥] [💼] [📚] [🏠] [📊]                                   │  ← Bottom Navigation
│  Inbox Work Study Home Stats                               │
└─────────────────────────────────────────────────────────────┘
```

### Hamburger Menu (Slide-out Sidebar)
```
┌─────────────────────────────────────────────────────────────┐
│  [✕] 🍅 Pomodoro Genie                                     │  ← Menu Header
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  👤 John Doe                                               │  ← User Profile
│  john.doe@example.com                                      │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  📋 我的项目                                                │  ← Projects Section
│                                                             │
│  📥 Inbox                                              [5]  │  ← Project Item
│  ████████████████░░░░░░░░░░  67%                            │  ← Progress Bar
│                                                             │
│  💼 Work Project                                       [3]  │  ← Active Project
│  ████████████████████████░░░  85%                          │  ← Progress Bar
│                                                             │
│  📚 Study Project                                      [7]  │  ← Project Item
│  ████████░░░░░░░░░░░░░░░░░░  33%                            │  ← Progress Bar
│                                                             │
│  🏠 Personal                                           [2]  │  ← Project Item
│  ████████████░░░░░░░░░░░░░░  50%                            │  ← Progress Bar
│                                                             │
│  [➕ New Project]                                           │  ← Create Button
│                                                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  📊 Today's Stats                                           │  ← Stats Section
│                                                             │
│  🍅 6 Pomodoros    ⏱️ 2h 30m    ✅ 4 Tasks    📈 3 Days    │  ← Compact Stats
│                                                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ⚙️ Settings                                                │  ← Menu Items
│  📊 Reports                                                 │
│  💾 Backup & Sync                                          │
│  ❓ Help & Support                                          │
│  🚪 Sign Out                                               │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Mobile Pomodoro Modal (Full Screen)
```
┌─────────────────────────────────────────────────────────────┐
│                         [✕]                                │  ← Close Button
│                                                             │
│                   🍅 Focus Mode                             │  ← Modal Header
│                                                             │
│              Complete project architecture                  │  ← Current Task
│                                                             │
│                      Progress: 2/5 🍅                      │  ← Task Progress
│            ████████████████░░░░░░░░░░  40%                 │  ← Progress Bar
│                                                             │
│                                                             │
│                    ┌───────────────┐                       │
│                    │               │                       │
│                    │     25:00     │                       │  ← Large Timer
│                    │               │                       │
│                    │   Work Time   │                       │  ← Session Type
│                    └───────────────┘                       │
│                                                             │
│                                                             │
│             [▶️ Start]  [⏸️ Pause]  [🔄 Reset]            │  ← Control Buttons
│                                                             │
│                                                             │
│                   Session 3 of 4                           │  ← Session Counter
│                                                             │
│                ● ● ◐ ○                                      │  ← Visual Progress
│                                                             │
│                                                             │
│              [🎵 Sounds]    [⚙️ Settings]                   │  ← Additional Options
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Mobile Landscape Layout (568-768px)

### Landscape Primary Interface
```
┌───────────────────────────────────────────────────────────────────────────────────────┐
│  [≡] 🍅 Pomodoro Genie    💼 Work Project    [🔔] [⚙️] [👤]                           │
├───────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                       │
│  ┌─────────────────────────────────────────┐   ┌─────────────────────────────────────┐ │
│  │  📋 Tasks                          [➕] │   │  📊 Stats                          │ │
│  │                                         │   │                                     │ │
│  │  ☐ Complete architecture          [🍅]  │   │  🍅 6 Pomodoros                     │ │
│  │  🔴 High   📅 Oct 8   🍅 2/5            │   │  ⏱️ 2h 30m Focus                   │ │
│  │                                         │   │  ✅ 4 Tasks Done                    │ │
│  │  ☐ Implement responsive           [🍅]  │   │  📈 3 Day Streak                   │ │
│  │  🟡 Med    📅 Oct 9   🍅 1/3            │   │                                     │ │
│  │                                         │   │  ████████████████░░░░░░░░░░  67%     │ │
│  │  ☑ Write API docs                      │   │                                     │ │
│  │  ✅ Done   📅 Oct 7   🍅 5/5            │   │  Today's Progress                   │ │
│  │                                         │   │                                     │ │
│  └─────────────────────────────────────────┘   └─────────────────────────────────────┘ │
│                                                                                       │
├───────────────────────────────────────────────────────────────────────────────────────┤
│  [📥 Inbox] [💼 Work] [📚 Study] [🏠 Personal] [📊 Stats]                            │
└───────────────────────────────────────────────────────────────────────────────────────┘
```

## Touch Interaction Patterns

### Gesture Controls
```
SWIPE GESTURES:
┌─────────────────────────────────────────┐
│  ☐ Task Item                            │
│     [← Swipe Left: Complete]            │  ← Left swipe reveals complete action
│     [Swipe Right: Edit →]               │  ← Right swipe reveals edit action
│     [Long Press: Select]                │  ← Long press for selection mode
└─────────────────────────────────────────┘

PULL-TO-REFRESH:
┌─────────────────────────────────────────┐
│              ↓ Pull down                │  ← Pull indicator
│           🔄 Release to refresh         │  ← Refresh indicator
├─────────────────────────────────────────┤
│  Task List Content...                   │
└─────────────────────────────────────────┘

FLOATING ACTION BUTTON:
                              ┌─────┐
                              │ [+] │  ← FAB for quick task creation
                              └─────┘
```

### Touch Targets
```
MINIMUM TOUCH SIZES:
┌────────────────┐  44px minimum height
│ Touch Target   │  44px minimum width
│                │  8px minimum spacing
└────────────────┘

BUTTON EXAMPLES:
[🍅 Start Pomodoro]  ← 48px height, full width
[✏️] [🗑️] [⋮]        ← 44px square buttons
[📥] [💼] [📚]        ← 56px tab bar items
```

## State Management

### Navigation States
```javascript
const MobileLayoutState = {
  currentView: 'tasks',           // tasks | stats | settings
  currentProject: 'work-project', // active project ID
  sidebarOpen: false,            // hamburger menu state
  selectedTasks: [],             // multi-select state
  bottomSheetOpen: false,        // modal state
  orientation: 'portrait'        // portrait | landscape
};
```

### Responsive Breakpoints
```css
/* Mobile Portrait */
@media (max-width: 480px) and (orientation: portrait) {
  .mobile-layout {
    grid-template-rows: 60px 1fr 80px;
    grid-template-areas: "header" "content" "nav";
  }
}

/* Mobile Landscape */
@media (max-width: 768px) and (orientation: landscape) {
  .mobile-layout {
    grid-template-columns: 60px 1fr 200px;
    grid-template-areas: "nav content stats";
  }
}

/* Large Mobile */
@media (min-width: 481px) and (max-width: 767px) {
  .mobile-layout {
    grid-template-rows: 64px 1fr 72px;
  }
}
```

## Performance Optimizations

### Mobile-Specific Features
```
VIRTUAL SCROLLING:
- Task lists virtualized for 1000+ items
- Only render visible + buffer items
- Smooth 60fps scrolling performance

LAZY LOADING:
- Project data loaded on demand
- Images and non-critical content deferred
- Progressive enhancement approach

TOUCH OPTIMIZATION:
- 300ms tap delay eliminated
- Passive event listeners for scroll
- Hardware acceleration for animations

MEMORY MANAGEMENT:
- Component cleanup on route changes
- Image optimization and caching
- Service worker for offline functionality
```

### Network Optimization
```
OFFLINE SUPPORT:
- Core functionality works offline
- Data synced when connection restored
- Clear offline/online indicators

BANDWIDTH CONSIDERATION:
- Compressed API responses
- Image optimization for mobile
- Essential data prioritized

CACHING STRATEGY:
- App shell cached for instant loading
- Task data cached with TTL
- Progressive data updates
```

## Accessibility Features

### Mobile Accessibility
```html
<!-- Touch accessibility -->
<button
  aria-label="Start pomodoro for project architecture task"
  style="min-height: 44px; min-width: 44px;">
  🍅 Start
</button>

<!-- Screen reader navigation -->
<nav role="navigation" aria-label="Project tabs">
  <button aria-selected="true">Work</button>
  <button aria-selected="false">Study</button>
</nav>

<!-- Voice control support -->
<div aria-live="polite" aria-atomic="true">
  Timer started for 25 minutes
</div>
```

### One-Handed Use
```
THUMB-FRIENDLY ZONES:
┌─────────────────────────────────────────┐
│                 [✕]                     │  ← Hard to reach
│                                         │
│                                         │  ← Comfortable zone
│  📋 Tasks                         [+]   │  ← Easy to reach
│                                         │
│  Task items...                          │  ← Main content
│                                         │
│                                         │  ← Comfortable zone
│  [📥] [💼] [📚] [🏠] [📊]               │  ← Easy to reach
└─────────────────────────────────────────┘

INTERACTION PRIORITIES:
- Primary actions in bottom 1/3 of screen
- Secondary actions in middle 1/3
- Tertiary actions in top 1/3
```

## Component Integration

### Navigation Flow
```
PROJECT SELECTION:
Bottom Nav → Project Tab → Task List
Hamburger → Project List → Select → Task List

TASK MANAGEMENT:
Task List → Swipe Actions → Quick Complete/Edit
Task Card → Tap → Pomodoro Modal
FAB → Tap → Create Task Modal

STATISTICS:
Bottom Nav → Stats Tab → Dashboard
Hamburger → Stats Section → Quick View
```

### Modal Patterns
```
FULL-SCREEN MODALS:
- Pomodoro timer (immersive focus)
- Task creation/editing (complex forms)
- Settings pages (multiple options)

BOTTOM SHEETS:
- Quick actions menu
- Filter/sort options
- Project selection

OVERLAYS:
- Loading states
- Confirmation dialogs
- Toast notifications
```

This mobile wireframe ensures the project-first architecture translates effectively to mobile devices while maintaining usability, performance, and accessibility standards for touch-based interactions.