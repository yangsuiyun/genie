# DailyStats Component

**Component Type**: display
**Complexity Level**: simple
**Dependencies**: Session API, Task API, Analytics calculation
**Estimated Implementation Time**: 4 hours

## Component Metadata

- **component_name**: DailyStats
- **component_type**: display
- **complexity_level**: simple
- **dependencies**: [Session API, Task API, Analytics calculation, localStorage]
- **estimated_implementation_time**: 4 hours

## Purpose

The DailyStats component provides a concise summary of the user's daily productivity metrics within the sidebar, including completed pomodoros, focus time, and completed tasks. It serves as a motivational element and quick progress indicator for the current day's accomplishments.

## Props/Inputs

| Property | Type | Required | Default | Validation | Description |
|----------|------|----------|---------|------------|-------------|
| date | string | false | today | Valid ISO date | Date for statistics (YYYY-MM-DD) |
| userId | string | true | null | Valid UUID | User ID for data filtering |
| refreshInterval | number | false | 300000 | 60000-600000 | Auto-refresh interval in milliseconds |
| showDetails | boolean | false | false | true\|false | Whether to show detailed breakdown |
| isCompact | boolean | false | true | true\|false | Compact display mode for sidebar |
| onStatsClick | function | false | null | Valid function | Callback when stats are clicked |
| theme | string | false | 'default' | Valid theme name | Visual theme for display |

## Visual States

### Default State
- **Layout**: Vertical stack with icon + number + label
- **Colors**: Icons in primary color, numbers in dark text
- **Typography**: Numbers in bold/large, labels in smaller secondary text
- **Animation**: Subtle counting animation when values update

### Loading State
- **Indicator**: Skeleton placeholders for each metric
- **Animation**: Shimmer effect on placeholder cards
- **Fallback**: "Loading..." text for screen readers
- **Duration**: Brief loading state with quick data fetch

### Error State
- **Display**: Error icon with "Unable to load stats"
- **Recovery**: Retry button or automatic retry
- **Fallback**: Show cached data if available
- **Styling**: Muted appearance to indicate error state

### Empty State (No Activity)
- **Display**: All metrics show "0" with encouraging message
- **Message**: "Start your first pomodoro to see stats!"
- **Action**: Link to task list or create task
- **Visual**: Motivational styling to encourage use

### Compact Mode
- **Layout**: Horizontal row with minimal spacing
- **Display**: Numbers only with small icons
- **Abbreviations**: "2h 30m" instead of "2 hours 30 minutes"
- **Priority**: Most important metrics first

## Accessibility

### Keyboard Navigation
- **Focus**: Tab to stats container, Enter to expand details
- **Navigation**: Arrow keys between individual stats if interactive
- **Shortcuts**: No specific shortcuts (display-only component)

### Screen Reader Support
- **aria-label**: "Daily productivity statistics"
- **aria-live**: "polite" for stat updates
- **Role**: "status" for live updates
- **Format**: "6 completed pomodoros, 2 hours 30 minutes focus time, 4 completed tasks"

### Visual Indicators
- **Color**: Not the only indicator (icons and text included)
- **Contrast**: High contrast for numbers and icons
- **Size**: Readable font sizes (minimum 14px for numbers)

## Responsive Behavior

### Desktop Sidebar (>1024px)
- **Layout**: Full vertical layout with icons, numbers, and descriptive labels
- **Detail**: Complete stat descriptions and additional metrics
- **Spacing**: Generous padding and margin for comfortable reading
- **Hover**: Subtle hover effects with additional detail tooltips

### Tablet Collapsed Sidebar (768-1024px)
- **Layout**: Compact vertical with reduced spacing
- **Detail**: Numbers and icons only, labels abbreviated
- **Interaction**: Hover to expand and show full labels
- **Animation**: Smooth transition between compact and expanded

### Mobile (<768px)
- **Layout**: Horizontal row in bottom navigation or header area
- **Detail**: Essential metrics only (pomodoros, time)
- **Size**: Larger touch targets for mobile interaction
- **Position**: Fixed position for easy access

## Integration Points

### API Integration
- **Sessions**: `GET /v1/sessions?date={date}&user_id={userId}` for pomodoro counts
- **Tasks**: `GET /v1/tasks?completed_date={date}&user_id={userId}` for task completion
- **Analytics**: `GET /v1/reports/daily?date={date}&user_id={userId}` for aggregated stats
- **Real-time**: WebSocket or polling for live updates during active sessions

### Data Calculation
- **Focus Time**: Sum of all completed pomodoro session durations
- **Pomodoro Count**: Count of sessions with status 'completed'
- **Task Count**: Count of tasks marked complete on the specified date
- **Additional Metrics**: Average session length, productivity score, streak days

### Caching Strategy
- **Local Cache**: Store daily stats in localStorage for offline access
- **Cache Duration**: 5 minutes for current day, 1 day for historical dates
- **Update Triggers**: New session completion, task completion, manual refresh
- **Sync**: Sync cached data with server when connection restored

## Data Structure

### Stats Object Schema
```javascript
{
  date: "2023-10-06",
  user_id: "uuid-string",
  pomodoros_completed: 6,
  focus_time_seconds: 9000,
  focus_time_formatted: "2h 30m",
  tasks_completed: 4,
  sessions_started: 8,
  sessions_abandoned: 2,
  average_session_minutes: 25,
  productivity_score: 85,
  streak_days: 3,
  last_updated: "2023-10-06T18:30:00Z"
}
```

### Historical Comparison
```javascript
{
  current: { /* today's stats */ },
  previous: { /* yesterday's stats */ },
  weekly_average: { /* last 7 days average */ },
  trends: {
    pomodoros: "up", // "up" | "down" | "stable"
    focus_time: "up",
    tasks: "stable"
  }
}
```

## Wireframe

```
┌─────────────────────────────────────┐
│         📊 今日统计                  │
├─────────────────────────────────────┤
│                                     │
│ 🍅 完成番茄钟                        │
│      6                              │
│                                     │
│ ⏱️ 专注时间                          │
│     2h 30m                          │
│                                     │
│ ✅ 完成任务                          │
│      4                              │
│                                     │
│ 📈 连续天数                          │
│      3                              │
│                                     │
├─────────────────────────────────────┤
│    [View Detailed Report] →         │
└─────────────────────────────────────┘
```

### Compact Mode Wireframe
```
┌─────────────────────────────────────┐
│ 🍅6  ⏱️2h30m  ✅4  📈3              │
└─────────────────────────────────────┘
```

## Implementation Notes

### CSS Classes
```css
.daily-stats {
  background: white;
  border-radius: 12px;
  padding: 20px;
  border: 1px solid var(--border-color);
  box-shadow: var(--shadow-light);
}

.daily-stats.compact {
  padding: 12px;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.stats-header {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 16px;
  font-weight: 600;
  color: var(--text-primary);
}

.stats-grid {
  display: grid;
  grid-template-columns: 1fr;
  gap: 16px;
}

.stats-grid.compact {
  grid-template-columns: repeat(auto-fit, minmax(60px, 1fr));
  gap: 8px;
}

.stat-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  text-align: center;
  padding: 12px;
  border-radius: 8px;
  background: var(--background-light);
  transition: var(--transition);
}

.stat-item:hover {
  background: var(--primary-light-bg);
  transform: translateY(-1px);
}

.stat-icon {
  font-size: 20px;
  margin-bottom: 8px;
  color: var(--primary-color);
}

.stat-number {
  font-size: 24px;
  font-weight: 800;
  color: var(--text-primary);
  margin-bottom: 4px;
  animation: countUp 0.5s ease-out;
}

.stat-label {
  font-size: 12px;
  color: var(--text-secondary);
  font-weight: 500;
}

.stat-item.compact .stat-number {
  font-size: 16px;
  margin-bottom: 0;
}

.stat-item.compact .stat-label {
  display: none;
}

.stats-footer {
  margin-top: 16px;
  text-align: center;
}

.view-details-btn {
  color: var(--primary-color);
  text-decoration: none;
  font-size: 14px;
  font-weight: 500;
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding: 8px 12px;
  border-radius: 6px;
  transition: var(--transition);
}

.view-details-btn:hover {
  background: var(--primary-light-bg);
}

@keyframes countUp {
  from {
    opacity: 0;
    transform: translateY(10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

/* Loading state */
.stat-skeleton {
  background: linear-gradient(90deg, #f0f0f0 25%, #e0e0e0 50%, #f0f0f0 75%);
  background-size: 200% 100%;
  animation: shimmer 1.5s infinite;
  border-radius: 4px;
  height: 20px;
  width: 60px;
}

@keyframes shimmer {
  0% { background-position: -200% 0; }
  100% { background-position: 200% 0; }
}
```

### JavaScript Structure
```javascript
class DailyStats {
  constructor(props) {
    this.props = props;
    this.state = {
      stats: null,
      isLoading: true,
      error: null,
      lastUpdated: null
    };
    this.refreshTimer = null;
    this.init();
  }

  init() {
    this.loadStats();
    this.setupAutoRefresh();
    this.bindEvents();
  }

  async loadStats() {
    try {
      this.setState({ isLoading: true, error: null });

      const date = this.props.date || this.getCurrentDate();
      const userId = this.props.userId;

      const response = await fetch(`/v1/reports/daily?date=${date}&user_id=${userId}`, {
        headers: { 'Authorization': 'Bearer ' + this.getToken() }
      });

      if (!response.ok) throw new Error('Failed to load daily stats');

      const stats = await response.json();

      this.setState({
        stats: stats.data,
        isLoading: false,
        lastUpdated: new Date()
      });

      // Cache for offline access
      this.cacheStats(stats.data);

    } catch (error) {
      console.error('Failed to load daily stats:', error);

      // Try to load from cache
      const cachedStats = this.getCachedStats();
      if (cachedStats) {
        this.setState({
          stats: cachedStats,
          isLoading: false,
          error: 'Using cached data'
        });
      } else {
        this.setState({
          isLoading: false,
          error: error.message
        });
      }
    }
  }

  setupAutoRefresh() {
    if (this.props.refreshInterval) {
      this.refreshTimer = setInterval(() => {
        this.loadStats();
      }, this.props.refreshInterval);
    }
  }

  getCurrentDate() {
    return new Date().toISOString().split('T')[0];
  }

  cacheStats(stats) {
    const cacheKey = `daily_stats_${this.props.userId}_${stats.date}`;
    const cacheData = {
      stats,
      timestamp: Date.now()
    };
    localStorage.setItem(cacheKey, JSON.stringify(cacheData));
  }

  getCachedStats() {
    const date = this.props.date || this.getCurrentDate();
    const cacheKey = `daily_stats_${this.props.userId}_${date}`;
    const cached = localStorage.getItem(cacheKey);

    if (cached) {
      const { stats, timestamp } = JSON.parse(cached);
      const age = Date.now() - timestamp;

      // Use cache if less than 5 minutes old for current day
      const isToday = date === this.getCurrentDate();
      const maxAge = isToday ? 5 * 60 * 1000 : 24 * 60 * 60 * 1000;

      if (age < maxAge) {
        return stats;
      }
    }

    return null;
  }

  render() {
    const { stats, isLoading, error } = this.state;
    const { isCompact, showDetails } = this.props;

    if (isLoading) return this.renderLoadingState();
    if (error && !stats) return this.renderErrorState();

    return `
      <div class="daily-stats ${isCompact ? 'compact' : ''}"
           role="status"
           aria-live="polite"
           aria-label="Daily productivity statistics">

        ${!isCompact ? this.renderHeader() : ''}

        <div class="stats-grid ${isCompact ? 'compact' : ''}">
          ${this.renderStatItem('🍅', stats.pomodoros_completed, '完成番茄钟')}
          ${this.renderStatItem('⏱️', stats.focus_time_formatted, '专注时间')}
          ${this.renderStatItem('✅', stats.tasks_completed, '完成任务')}
          ${!isCompact ? this.renderStatItem('📈', stats.streak_days, '连续天数') : ''}
        </div>

        ${!isCompact && showDetails ? this.renderFooter() : ''}
        ${error ? this.renderErrorIndicator() : ''}
      </div>
    `;
  }

  renderHeader() {
    return `
      <div class="stats-header">
        <span>📊</span>
        <span>今日统计</span>
      </div>
    `;
  }

  renderStatItem(icon, value, label) {
    const { isCompact } = this.props;

    return `
      <div class="stat-item ${isCompact ? 'compact' : ''}"
           role="img"
           aria-label="${label}: ${value}">
        <div class="stat-icon">${icon}</div>
        <div class="stat-number">${value || 0}</div>
        ${!isCompact ? `<div class="stat-label">${label}</div>` : ''}
      </div>
    `;
  }

  renderFooter() {
    return `
      <div class="stats-footer">
        <a href="#" class="view-details-btn" onclick="this.handleDetailsClick()">
          View Detailed Report →
        </a>
      </div>
    `;
  }

  renderLoadingState() {
    const { isCompact } = this.props;

    return `
      <div class="daily-stats ${isCompact ? 'compact' : ''}" aria-label="Loading statistics">
        ${!isCompact ? '<div class="stats-header">📊 Loading...</div>' : ''}
        <div class="stats-grid ${isCompact ? 'compact' : ''}">
          <div class="stat-item ${isCompact ? 'compact' : ''}">
            <div class="stat-skeleton"></div>
          </div>
          <div class="stat-item ${isCompact ? 'compact' : ''}">
            <div class="stat-skeleton"></div>
          </div>
          <div class="stat-item ${isCompact ? 'compact' : ''}">
            <div class="stat-skeleton"></div>
          </div>
          ${!isCompact ? '<div class="stat-item"><div class="stat-skeleton"></div></div>' : ''}
        </div>
      </div>
    `;
  }

  renderErrorState() {
    return `
      <div class="daily-stats error" role="alert">
        <div class="error-message">
          <span>❌</span>
          <span>Unable to load stats</span>
          <button onclick="this.loadStats()" class="retry-btn">Retry</button>
        </div>
      </div>
    `;
  }

  handleDetailsClick() {
    if (this.props.onStatsClick) {
      this.props.onStatsClick(this.state.stats);
    } else {
      // Default behavior: navigate to reports page
      window.location.href = '#/reports';
    }
  }

  bindEvents() {
    // Listen for session completion events to update stats
    document.addEventListener('pomodoroCompleted', () => {
      this.loadStats();
    });

    document.addEventListener('taskCompleted', () => {
      this.loadStats();
    });
  }

  destroy() {
    if (this.refreshTimer) {
      clearInterval(this.refreshTimer);
    }
  }
}
```

## Testing Requirements

### Unit Tests
- [ ] Stats calculation and formatting
- [ ] Caching and retrieval logic
- [ ] Component rendering with different props
- [ ] Auto-refresh functionality

### Integration Tests
- [ ] API integration for daily stats
- [ ] Real-time updates on session/task completion
- [ ] Offline functionality with cached data
- [ ] Error handling and recovery

### Accessibility Tests
- [ ] Screen reader announcements for stat updates
- [ ] Proper ARIA labels and roles
- [ ] Keyboard navigation for interactive elements
- [ ] Color contrast for all visual elements

### Performance Tests
- [ ] Rendering performance with frequent updates
- [ ] Memory usage during auto-refresh cycles
- [ ] Cache efficiency and storage usage
- [ ] Network request optimization

## Usage Examples

### Basic Usage (Sidebar)
```html
<daily-stats
  userId="user-123"
  isCompact="true"
  refreshInterval="300000">
</daily-stats>
```

### Detailed Dashboard Usage
```html
<daily-stats
  userId="user-123"
  date="2023-10-06"
  showDetails="true"
  isCompact="false"
  onStatsClick="handleStatsClick">
</daily-stats>
```

### Mobile Usage
```html
<daily-stats
  userId="user-123"
  isCompact="true"
  theme="mobile"
  refreshInterval="600000">
</daily-stats>
```

This DailyStats component provides users with immediate feedback on their productivity while maintaining simplicity and performance, serving as an effective motivational tool within the project-first interface architecture.