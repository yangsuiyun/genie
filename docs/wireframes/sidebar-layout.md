# Sidebar Navigation Wireframe

**Wireframe Type**: Navigation layout
**Target Component**: ProjectSidebar, ProjectList, DailyStats
**Responsive**: Collapsible on tablet, hidden on mobile
**Dependencies**: Project data, user statistics, theme settings

## Overview

This wireframe details the left sidebar navigation structure that forms the core of the project-first UI architecture. The sidebar serves as the primary navigation hub, prioritizing project selection and organization over traditional bottom navigation patterns.

## Desktop Sidebar Layout (>1024px)

```
┌─────────────────────────────────────────┐
│               🍅 Pomodoro Genie         │  ← App Header
├─────────────────────────────────────────┤
│                                         │
│                📋 我的项目         [➕]  │  ← Section Header + Add Button
│                                         │
│  ┌─────────────────────────────────────┐ │
│  │ 📥 Inbox                        [5] │ │  ← Project Item
│  │ ████████████████░░░░░░░░░░  67%     │ │  ← Progress Bar
│  │ 12 tasks • 8 pomodoros             │ │  ← Stats Line
│  └─────────────────────────────────────┘ │
│                                         │
│  ┌─────────────────────────────────────┐ │
│  │ 💼 Work Project                 [3] │ │  ← Active Project (highlighted)
│  │ ████████████████████████░░░  85%   │ │  ← Progress Bar
│  │ 15 tasks • 24 pomodoros           │ │  ← Stats Line
│  └─────────────────────────────────────┘ │
│                                         │
│  ┌─────────────────────────────────────┐ │
│  │ 📚 Study Project                [7] │ │  ← Project Item
│  │ ████████░░░░░░░░░░░░░░░░░░  33%     │ │  ← Progress Bar
│  │ 21 tasks • 12 pomodoros           │ │  ← Stats Line
│  └─────────────────────────────────────┘ │
│                                         │
│  ┌─────────────────────────────────────┐ │
│  │ 🏠 Personal                     [2] │ │  ← Project Item
│  │ ████████████░░░░░░░░░░░░░░  50%     │ │  ← Progress Bar
│  │ 8 tasks • 6 pomodoros             │ │  ← Stats Line
│  └─────────────────────────────────────┘ │
│                                         │
│  ┌─────────────────────────────────────┐ │
│  │ ✅ Completed Projects           [1] │ │  ← Collapsed Section
│  │                               [⌄]   │ │  ← Expand Indicator
│  └─────────────────────────────────────┘ │
│                                         │
├─────────────────────────────────────────┤
│              📊 今日统计                 │  ← Stats Section Header
│                                         │
│  🍅 完成番茄钟                           │  ← Stat Item
│       6                                 │  ← Value
│                                         │
│  ⏱️ 专注时间                             │  ← Stat Item
│      2h 30m                             │  ← Value
│                                         │
│  ✅ 完成任务                             │  ← Stat Item
│       4                                 │  ← Value
│                                         │
│  📈 连续天数                             │  ← Stat Item
│       3                                 │  ← Value
│                                         │
├─────────────────────────────────────────┤
│                                         │
│  [⚙️ 设置]     [📊 报告]     [👤 账户]    │  ← Bottom Actions
│                                         │
└─────────────────────────────────────────┘
```

### Layout Specifications
- **Total Width**: 240px fixed
- **Sections**: Project list (expandable), daily stats (fixed), bottom actions (fixed)
- **Scroll Area**: Project list only (when content overflows)
- **Padding**: 16px horizontal, 20px vertical
- **Item Height**: Project items ~80px, stat items ~40px

## Tablet Sidebar Layout (768-1024px)

### Collapsed State (Default)
```
┌────────┐
│   🍅   │  ← App Icon
├────────┤
│        │
│  📋    │  ← Projects Icon
│        │
│  📥 5  │  ← Inbox + Badge
│        │
│  💼 3  │  ← Work + Badge (Active)
│        │
│  📚 7  │  ← Study + Badge
│        │
│  🏠 2  │  ← Personal + Badge
│        │
│  ✅ 1  │  ← Completed + Badge
│        │
├────────┤
│  📊    │  ← Stats Icon
│   6    │  ← Pomodoro Count
│ 2h30m  │  ← Time
│   4    │  ← Tasks
│   3    │  ← Streak
├────────┤
│  ⚙️    │  ← Settings
│  📊    │  ← Reports
│  👤    │  ← Account
└────────┘
```

### Expanded State (Hover/Touch)
```
┌─────────────────────────────────────────┐
│               🍅 Pomodoro Genie         │  ← Slides out
├─────────────────────────────────────────┤
│                                         │
│               📋 我的项目          [➕]  │  ← Full header
│                                         │
│  ┌─────────────────────────────────────┐ │
│  │ 📥 Inbox                        [5] │ │  ← Full project card
│  │ ████████████████░░░░░░░░░░  67%     │ │
│  │ 12 tasks • 8 pomodoros             │ │
│  └─────────────────────────────────────┘ │
│  [... other projects ...]               │
├─────────────────────────────────────────┤
│              📊 今日统计                 │
│                                         │
│  🍅 完成番茄钟    6                      │
│  ⏱️ 专注时间     2h 30m                  │
│  ✅ 完成任务     4                       │
│  📈 连续天数     3                       │
└─────────────────────────────────────────┘
```

### Layout Specifications
- **Collapsed Width**: 60px
- **Expanded Width**: 240px
- **Transition**: 200ms smooth slide animation
- **Trigger**: Hover for 300ms or touch/click
- **Auto-close**: Click outside or 2s after mouse leave

## Component Integration Points

### Project List Section
```
PROJECT ITEM STRUCTURE:
┌─────────────────────────────────────────┐
│ [ICON] Project Name             [BADGE] │  ← Title Row
│ [PROGRESS_BAR________________] PERCENT% │  ← Progress Row
│ [STAT1] • [STAT2] • [STAT3]            │  ← Stats Row
│ [ACTION_BUTTONS]                        │  ← Hover Actions (optional)
└─────────────────────────────────────────┘

HOVER STATES:
- Border color changes to project theme
- Transform: slight upward movement (2px)
- Shadow: enhanced shadow effect
- Actions: edit/settings buttons appear

ACTIVE STATE:
- Background: project theme light color
- Border: project theme color
- Text: enhanced contrast
- Indicator: left border or accent

LOADING STATE:
- Skeleton animation for all text
- Progress bar shows shimmer
- No hover effects active
```

### Daily Stats Section
```
STATS LAYOUT:
📊 今日统计                    ← Section Header
─────────────────────────────  ← Optional divider

ICON  LABEL        VALUE       ← Stat Item Pattern
🍅   完成番茄钟      6
⏱️   专注时间       2h 30m
✅   完成任务       4
📈   连续天数       3

COMPACT LAYOUT (Collapsed):
📊                            ← Just icon
6                             ← Primary value
2h30m                         ← Secondary value
4                             ← Tertiary value
3                             ← Quaternary value
```

### Bottom Actions Section
```
DESKTOP LAYOUT:
[⚙️ 设置]  [📊 报告]  [👤 账户]   ← Horizontal buttons

TABLET COLLAPSED:
⚙️                            ← Icon only
📊                            ← Icon only
👤                            ← Icon only

INTERACTION STATES:
- Hover: background color change
- Active: pressed state with visual feedback
- Disabled: grayed out with no interaction
```

## Responsive Breakpoint Behavior

### 1024px → 768px Transition
1. **Sidebar Width**: 240px → 60px (collapsed)
2. **Project Names**: Full text → hidden
3. **Progress Bars**: Full width → hidden
4. **Stats Text**: Full labels → icons only
5. **Animation**: Smooth 200ms transition

### Hover Expansion (768-1024px)
1. **Trigger**: Mouse hover for 300ms
2. **Animation**: Slide out from 60px to 240px
3. **Content**: Full content appears progressively
4. **Z-index**: Elevated above main content
5. **Backdrop**: Semi-transparent overlay on main content

### Mobile Transition (768px → 0px)
1. **Visibility**: Sidebar completely hidden
2. **Trigger**: Hamburger menu button in header
3. **Animation**: Slide in from left as overlay
4. **Backdrop**: Dark overlay covers main content
5. **Close**: Tap outside, swipe left, or close button

## Accessibility Features

### Navigation Landmarks
```html
<nav role="navigation" aria-label="Project navigation">
  <div role="list" aria-label="Projects">
    <div role="listitem" aria-selected="true">Work Project</div>
    <div role="listitem" aria-selected="false">Study Project</div>
  </div>
</nav>

<aside role="complementary" aria-label="Daily statistics">
  <div role="status" aria-live="polite">
    6 completed pomodoros today
  </div>
</aside>
```

### Keyboard Navigation
- **Tab Order**: Projects list → stats → bottom actions
- **Arrow Keys**: Navigate between projects
- **Enter/Space**: Select project or activate action
- **Escape**: Close expanded sidebar (tablet) or mobile overlay

### Screen Reader Support
- **Project Announcements**: "Work Project, 3 pending tasks, 85% complete"
- **Stats Announcements**: "6 completed pomodoros, 2 hours 30 minutes focus time"
- **State Changes**: "Sidebar expanded" / "Sidebar collapsed"
- **Live Updates**: Statistics updates announced when changed

## Performance Considerations

### Rendering Optimization
- **Virtual Scrolling**: For 100+ projects
- **Lazy Loading**: Project statistics loaded on demand
- **Memoization**: Project items only re-render when data changes
- **Animation**: CSS transforms for better performance

### Data Loading
- **Initial Load**: Basic project list first
- **Progressive Enhancement**: Statistics loaded after
- **Caching**: Project data cached for offline access
- **Real-time Updates**: WebSocket updates for live statistics

### Mobile Performance
- **Touch Response**: < 16ms touch response time
- **Scroll Performance**: 60fps scrolling in project list
- **Memory Usage**: < 10MB for sidebar component
- **Battery Optimization**: Minimal background updates

## Implementation Notes

### CSS Grid Layout
```css
.sidebar {
  display: grid;
  grid-template-rows: auto 1fr auto auto;
  grid-template-areas:
    "header"
    "projects"
    "stats"
    "actions";
  height: 100vh;
  overflow: hidden;
}

.project-list {
  grid-area: projects;
  overflow-y: auto;
  scrollbar-width: thin;
}

.daily-stats {
  grid-area: stats;
  flex-shrink: 0;
}

.bottom-actions {
  grid-area: actions;
  flex-shrink: 0;
}
```

### Animation System
```css
.sidebar {
  transition: width 200ms cubic-bezier(0.4, 0, 0.2, 1);
}

.sidebar.collapsed {
  width: 60px;
}

.sidebar.expanded {
  width: 240px;
}

.project-item {
  transition: all 200ms ease;
}

.project-item:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0,0,0,0.15);
}
```

### State Management
```javascript
const SidebarState = {
  isCollapsed: false,
  selectedProjectId: null,
  projects: [],
  dailyStats: {},
  expandTimer: null
};

// Tablet hover behavior
function handleSidebarHover() {
  if (window.innerWidth >= 768 && window.innerWidth <= 1024) {
    clearTimeout(SidebarState.expandTimer);
    SidebarState.expandTimer = setTimeout(() => {
      expandSidebar();
    }, 300);
  }
}
```

This sidebar wireframe provides the foundation for implementing the project-first navigation architecture while ensuring excellent usability across all device types and accessibility requirements.