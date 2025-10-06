# Main Layout Wireframe

**Layout Type**: Overall application structure
**Responsive**: Desktop primary, tablet/mobile variants included
**Components**: ProjectSidebar, MainContent, PomodoroModal (overlay)

## Desktop Layout (>1024px)

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                         🍅 Pomodoro Genie                                   │
│                    [用户头像] [设置] [通知]                                   │
├────────────────┬─────────────────────────────────────────────────────────────┤
│                │                                                             │
│  📋 我的项目     │                     项目详情                               │
│                │                                                             │
│  📥 Inbox   5  │  💼 工作项目                           [➕ 新建任务]        │
│  💼 Work    12 │  ┌─────────────────────────────────────────────────────────┐ │
│  📚 Study   8  │  │                  项目统计                              │ │
│  🏠 Personal 3 │  │  24总任务  12已完成  50%完成率  36番茄钟               │ │
│                │  └─────────────────────────────────────────────────────────┘ │
│  📊 今日统计     │                                                             │
│  ────────────  │  📋 任务列表                                               │
│  🍅 完成番茄钟   │  [全部] [待开始] [进行中] [已完成]                         │
│      6         │                                                             │
│  ⏱️ 专注时间     │  ┌─────────────────────────────────────────────────────────┐ │
│     2h 30m     │  │ ☐ 完成项目架构设计                          [🍅开始番茄钟]│ │
│  ✅ 完成任务     │  │   设计前端项目优先架构，包括左侧边栏                     │ │
│      4         │  │   🔴高优先级  📅10月8日  🍅2/5         ✏️ 🗑️           │ │
│                │  └─────────────────────────────────────────────────────────┘ │
│                │                                                             │
│                │  ┌─────────────────────────────────────────────────────────┐ │
│                │  │ ☑ 编写API文档                                          │ │
│                │  │   完成后端API接口文档编写                               │ │
│                │  │   🟡中优先级  📅10月7日  🍅5/5         ✏️ 🗑️           │ │
│                │  └─────────────────────────────────────────────────────────┘ │
│                │                                                             │
└────────────────┴─────────────────────────────────────────────────────────────┘
```

### Layout Specifications
- **Total Width**: 100vw (viewport width)
- **Sidebar Width**: 240px fixed
- **Main Content**: calc(100vw - 240px)
- **Header Height**: 60px
- **Content Padding**: 24px all sides

### Component Boundaries
- **Sidebar**: Fixed left panel, full height minus header
- **Main Area**: Flexible content area with scrolling
- **Header**: Fixed top bar spanning full width
- **Modal Overlay**: z-index: 1000, covers entire viewport when active

## Tablet Layout (768-1024px)

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                         🍅 Pomodoro Genie                    [≡] [⚙️] [🔔]   │
├──┬───────────────────────────────────────────────────────────────────────────┤
│  │                                                                           │
│≡ │                      项目详情                                            │
│📋│                                                                           │
│💼│  💼 工作项目                                    [➕]                      │
│📚│  ┌───────────────────────────────────────────────────────────────────────┐ │
│  │  │          项目统计: 24任务 50%完成 36🍅                              │ │
│  │  └───────────────────────────────────────────────────────────────────────┘ │
│📊│                                                                           │
│6 │  📋 任务列表  [全部] [进行中] [已完成]                                   │
│2h│                                                                           │
│4 │  ┌───────────────────────────────────────────────────────────────────────┐ │
│  │  │ ☐ 完成架构设计                               [🍅]                    │ │
│  │  │   🔴高优先级  📅10月8日  🍅2/5                                       │ │
│  │  └───────────────────────────────────────────────────────────────────────┘ │
│  │                                                                           │
└──┴───────────────────────────────────────────────────────────────────────────┘
```

### Layout Specifications
- **Sidebar Width**: 60px collapsed, 240px expanded
- **Hover Behavior**: Expands on hover with 200ms transition
- **Touch Behavior**: Tap to expand, tap outside to collapse
- **Icon Display**: Shows project icons and stat numbers only when collapsed

## Mobile Layout (<768px)

```
┌──────────────────────────────────────────────────────────────────────────────┐
│  🍅 Pomodoro Genie                              [≡] [⚙️] [🔔]                │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│                          💼 工作项目                                        │
│                                                                              │
│                  ┌──────────────────────────────────────┐                  │
│                  │  24任务  50%完成  36🍅  2h30m        │                  │
│                  └──────────────────────────────────────┘                  │
│                                                                              │
│  📋 任务列表                                                [➕]            │
│                                                                              │
│  ┌──────────────────────────────────────────────────────────────────────────┐ │
│  │ ☐ 完成项目架构设计                                                      │ │
│  │   设计前端项目优先架构，包括左侧边栏                                     │ │
│  │   🔴高优先级    📅10月8日    🍅2/5                                      │ │
│  │                                           [🍅开始番茄钟]                │ │
│  └──────────────────────────────────────────────────────────────────────────┘ │
│                                                                              │
│  ┌──────────────────────────────────────────────────────────────────────────┐ │
│  │ ☑ 编写API文档                                                           │ │
│  │   完成后端API接口文档编写                                               │ │
│  │   🟡中优先级    📅10月7日    🍅5/5                                      │ │
│  └──────────────────────────────────────────────────────────────────────────┘ │
│                                                                              │
├──────────────────────────────────────────────────────────────────────────────┤
│  📥Inbox  💼Work  📚Study  🏠Personal  📊Stats                              │  ← Bottom Nav
└──────────────────────────────────────────────────────────────────────────────┘
```

### Layout Specifications
- **Navigation**: Bottom horizontal bar (60px height)
- **Content**: Full width with 16px padding
- **Touch Targets**: Minimum 44px for all interactive elements
- **Scroll**: Vertical scrolling for task list

## Component Integration

### State Management
```javascript
const LayoutState = {
  currentProject: 'work-project-1',
  sidebarCollapsed: false,
  isMobile: window.innerWidth < 768,
  activePomodoro: null
};
```

### Responsive Breakpoints
```css
/* Mobile First */
.main-layout {
  display: flex;
  flex-direction: column;
}

/* Tablet */
@media (min-width: 768px) {
  .main-layout {
    flex-direction: row;
  }
  .sidebar {
    width: 60px;
  }
  .sidebar:hover {
    width: 240px;
  }
}

/* Desktop */
@media (min-width: 1024px) {
  .sidebar {
    width: 240px;
  }
  .sidebar:hover {
    width: 240px; /* No change */
  }
}
```

### Performance Considerations
- **Sidebar Rendering**: Only render expanded content when visible
- **Task Virtualization**: Implement virtual scrolling for 100+ tasks
- **Image Lazy Loading**: Defer non-critical assets
- **Animation Performance**: Use transform and opacity for smooth transitions

## Accessibility Features

### Navigation Landmarks
- **Banner**: Header region with site title and user controls
- **Navigation**: Sidebar project list with proper ARIA labels
- **Main**: Primary content area with project details and tasks
- **Complementary**: Daily statistics and secondary information

### Focus Management
- **Skip Links**: "Skip to main content" for keyboard users
- **Focus Trapping**: In modals and expanded sidebar on mobile
- **Focus Indicators**: Clear visual focus states throughout layout
- **Logical Tab Order**: Header → Sidebar → Main Content → Bottom Nav (mobile)

### Screen Reader Support
- **Landmark Announcements**: Clear region identification
- **Dynamic Content**: Live regions for project/task updates
- **State Changes**: Announcements for sidebar collapse/expand
- **Navigation**: Clear indication of current project and location

This main layout wireframe provides the foundation for implementing the project-first UI architecture with responsive design and comprehensive accessibility support.