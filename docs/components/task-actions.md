# TaskActions Component

**Component Type**: interaction
**Complexity Level**: simple
**Dependencies**: Modal dialogs, Confirmation dialogs, API integration
**Estimated Implementation Time**: 5 hours

## Component Metadata

- **component_name**: TaskActions
- **component_type**: interaction
- **complexity_level**: simple
- **dependencies**: [Modal dialogs, Confirmation dialogs, API integration, Permissions]
- **estimated_implementation_time**: 5 hours

## Purpose

The TaskActions component provides quick action buttons for individual tasks, including edit, delete, duplicate, move, and status change operations. It appears as part of TaskCard components and adapts its available actions based on user permissions and task state, ensuring efficient task management within the project-first workflow.

## Props/Inputs

| Property | Type | Required | Default | Validation | Description |
|----------|------|----------|---------|------------|-------------|
| task | object | true | null | Valid task object | Task data for action context |
| position | string | false | 'right' | left\|right\|bottom | Position relative to task card |
| size | string | false | 'medium' | small\|medium\|large | Size variant for different contexts |
| orientation | string | false | 'horizontal' | horizontal\|vertical | Layout orientation |
| showLabels | boolean | false | false | true\|false | Whether to show text labels |
| canEdit | boolean | false | true | true\|false | User permission to edit task |
| canDelete | boolean | false | true | true\|false | User permission to delete task |
| canMove | boolean | false | true | true\|false | User permission to move task |
| visibleActions | array | false | null | Valid action names | Specific actions to show |
| onEdit | function | true | null | Valid function | Callback for edit action |
| onDelete | function | true | null | Valid function | Callback for delete action |
| onDuplicate | function | false | null | Valid function | Callback for duplicate action |
| onMove | function | false | null | Valid function | Callback for move action |
| onStatusChange | function | false | null | Valid function | Callback for status changes |
| onPriorityChange | function | false | null | Valid function | Callback for priority changes |

## Visual States

### Default State
- **Layout**: Horizontal row of icon buttons
- **Visibility**: Semi-transparent, becomes opaque on hover
- **Spacing**: Appropriate gaps between action buttons
- **Colors**: Neutral colors with hover states

### Hover State
- **Visibility**: Full opacity with enhanced button visibility
- **Animation**: Smooth fade-in transition
- **Feedback**: Individual button hover effects
- **Timing**: Quick response to mouse movement

### Disabled State
- **Appearance**: Grayed out buttons for unavailable actions
- **Interaction**: No click response, appropriate cursor
- **Tooltip**: Explanation of why action is disabled
- **Accessibility**: Proper disabled state announcements

### Mobile State
- **Size**: Larger touch targets (minimum 44px)
- **Spacing**: Increased spacing for finger navigation
- **Layout**: May switch to vertical or dropdown menu
- **Gestures**: Support for touch interactions

### Compact State
- **Size**: Smaller icons with reduced spacing
- **Priority**: Only essential actions visible
- **Overflow**: More actions in dropdown menu
- **Context**: Adapts to container constraints

## Accessibility

### Keyboard Navigation
- **Tab Order**: Sequential through available actions
- **Activation**: Enter or Space to trigger actions
- **Focus**: Clear focus indicators on each button
- **Shortcuts**: Optional keyboard shortcuts (e.g., Del for delete)

### Screen Reader Support
- **aria-label**: Descriptive labels for each action
- **Role**: "group" for action container, "button" for actions
- **Context**: Task title included in action descriptions
- **Feedback**: Action completion announcements

### Visual Indicators
- **Icons**: Clear, recognizable icons for each action
- **Color**: Not the only indicator (icons + tooltips)
- **Contrast**: High contrast for disabled states
- **Size**: Readable icons at all size variants

## Responsive Behavior

### Desktop (>1024px)
- **Layout**: Full horizontal layout with all actions visible
- **Labels**: Optional text labels alongside icons
- **Hover**: Rich hover effects and tooltips
- **Context**: Right-click context menu integration

### Tablet (768-1024px)
- **Layout**: Compact horizontal with essential actions
- **Touch**: Enhanced touch targets and spacing
- **Overflow**: Dropdown for secondary actions
- **Gestures**: Swipe gestures for common actions

### Mobile (<768px)
- **Layout**: Vertical stack or slide-up action sheet
- **Size**: Large touch-friendly buttons
- **Modal**: Full-screen action selection modal
- **Priority**: Most common actions first

## Integration Points

### Task Management API
- **Edit Action**: Opens task editing modal/form
- **Delete Action**: Confirms and executes task deletion
- **Status Change**: Updates task status via API
- **Move Action**: Transfers task between projects

### Permission System
- **Role Checks**: Verify user permissions for each action
- **Ownership**: Task owner vs. team member permissions
- **Project Rights**: Project-level permission inheritance
- **Dynamic**: Real-time permission updates

### UI Integration
- **Modal Dialogs**: Edit forms, confirmation dialogs
- **Context Menus**: Right-click action menus
- **Drag & Drop**: Move actions via drag interface
- **Bulk Actions**: Integration with bulk selection

## Data Structure

### Action Configuration
```javascript
{
  edit: {
    icon: '✏️',
    label: 'Edit',
    shortcut: 'E',
    requiresPermission: 'edit',
    callback: 'onEdit'
  },
  delete: {
    icon: '🗑️',
    label: 'Delete',
    shortcut: 'Del',
    requiresPermission: 'delete',
    callback: 'onDelete',
    confirmation: true
  },
  duplicate: {
    icon: '📄',
    label: 'Duplicate',
    shortcut: 'D',
    requiresPermission: 'create',
    callback: 'onDuplicate'
  },
  move: {
    icon: '📁',
    label: 'Move',
    shortcut: 'M',
    requiresPermission: 'move',
    callback: 'onMove'
  },
  complete: {
    icon: '✅',
    label: 'Complete',
    shortcut: 'C',
    requiresPermission: 'edit',
    callback: 'onStatusChange',
    toggle: true
  },
  priority: {
    icon: '🔥',
    label: 'Priority',
    shortcut: 'P',
    requiresPermission: 'edit',
    callback: 'onPriorityChange',
    submenu: true
  }
}
```

### Permission Matrix
```javascript
{
  owner: ['edit', 'delete', 'move', 'duplicate', 'complete', 'priority'],
  admin: ['edit', 'delete', 'move', 'duplicate', 'complete', 'priority'],
  member: ['edit', 'complete', 'priority'],
  viewer: [],
  guest: []
}
```

## Wireframe

```
┌─────────────────────────────────────┐
│ ☐ Complete project architecture     │
│   Design frontend project-first...  │
│   🔴 High   📅 Oct 8   🍅 2/5      │
│                          [✏️][🗑️] │ ← TaskActions
└─────────────────────────────────────┘

Mobile/Touch Version:
┌─────────────────────────────────────┐
│ ☐ Complete project architecture     │
│   Design frontend project-first...  │
│   🔴 High   📅 Oct 8   🍅 2/5      │
│   [✏️ Edit] [🗑️ Delete] [⋮ More]   │
└─────────────────────────────────────┘

Dropdown Menu:
        ┌─────────────────┐
        │ ✏️ Edit Task    │
        │ 📄 Duplicate    │
        │ 📁 Move to...   │
        │ 🔥 Change Prio  │
        │ ✅ Mark Done    │
        │ ─────────────── │
        │ 🗑️ Delete      │
        └─────────────────┘
```

## Implementation Notes

### CSS Classes
```css
.task-actions {
  display: flex;
  gap: 8px;
  align-items: center;
  opacity: 0.6;
  transition: opacity 0.2s ease;
}

.task-card:hover .task-actions,
.task-actions:focus-within {
  opacity: 1;
}

.task-actions.vertical {
  flex-direction: column;
}

.task-actions.small {
  gap: 4px;
}

.task-actions.large {
  gap: 12px;
}

.action-btn {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 32px;
  height: 32px;
  border: none;
  border-radius: 6px;
  background: transparent;
  color: var(--text-secondary);
  cursor: pointer;
  transition: all 0.2s ease;
  position: relative;
}

.action-btn:hover {
  background: var(--background-light);
  color: var(--text-primary);
  transform: scale(1.1);
}

.action-btn:active {
  transform: scale(0.95);
}

.action-btn.dangerous {
  color: var(--error-color);
}

.action-btn.dangerous:hover {
  background: var(--error-light);
  color: var(--error-color);
}

.action-btn:disabled {
  opacity: 0.4;
  cursor: not-allowed;
  transform: none;
}

.action-btn.with-label {
  width: auto;
  padding: 6px 12px;
  gap: 6px;
}

.action-label {
  font-size: 12px;
  font-weight: 500;
  white-space: nowrap;
}

/* Touch-friendly sizes */
.task-actions.touch .action-btn {
  width: 44px;
  height: 44px;
  font-size: 18px;
}

/* Tooltip styles */
.action-tooltip {
  position: absolute;
  bottom: 100%;
  left: 50%;
  transform: translateX(-50%);
  background: var(--text-primary);
  color: white;
  padding: 4px 8px;
  border-radius: 4px;
  font-size: 12px;
  white-space: nowrap;
  opacity: 0;
  pointer-events: none;
  transition: opacity 0.2s ease;
  z-index: 1000;
}

.action-btn:hover .action-tooltip {
  opacity: 1;
}

/* Dropdown menu */
.actions-dropdown {
  position: relative;
}

.dropdown-menu {
  position: absolute;
  top: 100%;
  right: 0;
  background: var(--surface-color);
  border: 1px solid var(--border-color);
  border-radius: 8px;
  padding: 8px 0;
  min-width: 160px;
  box-shadow: var(--shadow-medium);
  z-index: 1000;
  opacity: 0;
  transform: translateY(-10px);
  transition: all 0.2s ease;
  pointer-events: none;
}

.dropdown-menu.open {
  opacity: 1;
  transform: translateY(0);
  pointer-events: all;
}

.dropdown-item {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 8px 16px;
  border: none;
  background: none;
  width: 100%;
  text-align: left;
  color: var(--text-primary);
  cursor: pointer;
  transition: background-color 0.2s ease;
}

.dropdown-item:hover {
  background: var(--background-light);
}

.dropdown-item.dangerous {
  color: var(--error-color);
}

.dropdown-separator {
  height: 1px;
  background: var(--border-color);
  margin: 4px 0;
}

/* Mobile responsive */
@media (max-width: 768px) {
  .task-actions {
    opacity: 1; /* Always visible on mobile */
  }

  .action-btn {
    width: 40px;
    height: 40px;
    font-size: 16px;
  }

  .dropdown-menu {
    position: fixed;
    bottom: 0;
    left: 0;
    right: 0;
    top: auto;
    border-radius: 16px 16px 0 0;
    max-width: none;
    transform: translateY(100%);
  }

  .dropdown-menu.open {
    transform: translateY(0);
  }
}

/* Loading state */
.action-btn.loading {
  pointer-events: none;
}

.action-btn.loading::after {
  content: '';
  position: absolute;
  width: 16px;
  height: 16px;
  border: 2px solid transparent;
  border-top: 2px solid currentColor;
  border-radius: 50%;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}
```

### JavaScript Structure
```javascript
class TaskActions {
  constructor(props) {
    this.props = props;
    this.state = {
      isDropdownOpen: false,
      loadingAction: null
    };
    this.dropdownRef = null;
    this.init();
  }

  init() {
    this.bindEvents();
    this.setupPermissions();
  }

  setupPermissions() {
    // Check user permissions for each action
    this.availableActions = this.getAvailableActions();
  }

  getAvailableActions() {
    const { task, canEdit, canDelete, canMove, visibleActions } = this.props;
    const actions = [];

    // Define all possible actions
    const allActions = [
      {
        id: 'edit',
        icon: '✏️',
        label: 'Edit',
        available: canEdit,
        callback: () => this.handleEdit()
      },
      {
        id: 'complete',
        icon: task.status === 'completed' ? '↩️' : '✅',
        label: task.status === 'completed' ? 'Reopen' : 'Complete',
        available: canEdit,
        callback: () => this.handleStatusToggle()
      },
      {
        id: 'duplicate',
        icon: '📄',
        label: 'Duplicate',
        available: canEdit,
        callback: () => this.handleDuplicate()
      },
      {
        id: 'move',
        icon: '📁',
        label: 'Move',
        available: canMove,
        callback: () => this.handleMove()
      },
      {
        id: 'priority',
        icon: '🔥',
        label: 'Priority',
        available: canEdit,
        callback: () => this.handlePriorityChange()
      },
      {
        id: 'delete',
        icon: '🗑️',
        label: 'Delete',
        available: canDelete,
        dangerous: true,
        callback: () => this.handleDelete()
      }
    ];

    // Filter based on permissions and visible actions
    return allActions.filter(action => {
      if (!action.available) return false;
      if (visibleActions && !visibleActions.includes(action.id)) return false;
      return true;
    });
  }

  async handleEdit() {
    this.setLoadingAction('edit');
    try {
      await this.props.onEdit(this.props.task);
    } finally {
      this.setLoadingAction(null);
    }
  }

  async handleDelete() {
    const confirmed = await this.showConfirmDialog(
      'Delete Task',
      'Are you sure you want to delete this task? This action cannot be undone.'
    );

    if (confirmed) {
      this.setLoadingAction('delete');
      try {
        await this.props.onDelete(this.props.task);
      } finally {
        this.setLoadingAction(null);
      }
    }
  }

  async handleDuplicate() {
    this.setLoadingAction('duplicate');
    try {
      await this.props.onDuplicate(this.props.task);
    } finally {
      this.setLoadingAction(null);
    }
  }

  async handleMove() {
    // Show project selection modal
    const targetProject = await this.showProjectSelector();
    if (targetProject) {
      this.setLoadingAction('move');
      try {
        await this.props.onMove(this.props.task, targetProject);
      } finally {
        this.setLoadingAction(null);
      }
    }
  }

  async handleStatusToggle() {
    const newStatus = this.props.task.status === 'completed' ? 'pending' : 'completed';
    this.setLoadingAction('complete');
    try {
      await this.props.onStatusChange(this.props.task, newStatus);
    } finally {
      this.setLoadingAction(null);
    }
  }

  async handlePriorityChange() {
    // Show priority selection dropdown
    const priorities = ['low', 'medium', 'high', 'urgent'];
    const currentPriority = this.props.task.priority || 'medium';

    // Create quick priority menu
    this.showPriorityMenu(priorities, currentPriority);
  }

  setLoadingAction(actionId) {
    this.setState({ loadingAction: actionId });
  }

  toggleDropdown() {
    this.setState({ isDropdownOpen: !this.state.isDropdownOpen });
  }

  closeDropdown() {
    this.setState({ isDropdownOpen: false });
  }

  showConfirmDialog(title, message) {
    return new Promise((resolve) => {
      const modal = document.createElement('div');
      modal.className = 'confirm-modal';
      modal.innerHTML = `
        <div class="modal-backdrop" onclick="resolve(false)"></div>
        <div class="modal-content">
          <h3>${title}</h3>
          <p>${message}</p>
          <div class="modal-actions">
            <button class="btn btn-secondary" onclick="resolve(false)">Cancel</button>
            <button class="btn btn-danger" onclick="resolve(true)">Delete</button>
          </div>
        </div>
      `;

      // Add event handlers
      modal.querySelector('.btn-secondary').onclick = () => {
        document.body.removeChild(modal);
        resolve(false);
      };
      modal.querySelector('.btn-danger').onclick = () => {
        document.body.removeChild(modal);
        resolve(true);
      };

      document.body.appendChild(modal);
    });
  }

  render() {
    const { orientation, size, showLabels, position } = this.props;
    const { isDropdownOpen, loadingAction } = this.state;

    const visibleActions = this.availableActions.slice(0, 3);
    const overflowActions = this.availableActions.slice(3);

    return `
      <div class="task-actions ${orientation} ${size} ${showLabels ? 'with-labels' : ''}"
           role="group"
           aria-label="Task actions">

        ${visibleActions.map(action => this.renderActionButton(action)).join('')}

        ${overflowActions.length > 0 ? this.renderDropdown(overflowActions) : ''}
      </div>
    `;
  }

  renderActionButton(action) {
    const { showLabels } = this.props;
    const { loadingAction } = this.state;
    const isLoading = loadingAction === action.id;

    return `
      <button class="action-btn ${action.dangerous ? 'dangerous' : ''} ${showLabels ? 'with-label' : ''} ${isLoading ? 'loading' : ''}"
              onclick="this.handleAction('${action.id}')"
              disabled="${isLoading}"
              aria-label="${action.label} task: ${this.props.task.title}"
              title="${action.label}">

        ${!isLoading ? `<span class="action-icon">${action.icon}</span>` : ''}
        ${showLabels ? `<span class="action-label">${action.label}</span>` : ''}

        <div class="action-tooltip">${action.label}</div>
      </button>
    `;
  }

  renderDropdown(actions) {
    const { isDropdownOpen } = this.state;

    return `
      <div class="actions-dropdown">
        <button class="action-btn"
                onclick="this.toggleDropdown()"
                aria-label="More actions"
                aria-expanded="${isDropdownOpen}">
          <span class="action-icon">⋮</span>
          <div class="action-tooltip">More</div>
        </button>

        <div class="dropdown-menu ${isDropdownOpen ? 'open' : ''}"
             role="menu">
          ${actions.map(action => `
            <button class="dropdown-item ${action.dangerous ? 'dangerous' : ''}"
                    onclick="this.handleAction('${action.id}')"
                    role="menuitem">
              <span>${action.icon}</span>
              <span>${action.label}</span>
            </button>
          `).join('')}
        </div>
      </div>
    `;
  }

  handleAction(actionId) {
    const action = this.availableActions.find(a => a.id === actionId);
    if (action && action.callback) {
      action.callback();
    }
    this.closeDropdown();
  }

  bindEvents() {
    // Close dropdown when clicking outside
    document.addEventListener('click', (e) => {
      if (this.state.isDropdownOpen && !e.target.closest('.actions-dropdown')) {
        this.closeDropdown();
      }
    });

    // Keyboard shortcuts
    document.addEventListener('keydown', (e) => {
      if (e.target.closest('.task-card') === this.element?.closest('.task-card')) {
        this.handleKeyboard(e);
      }
    });
  }

  handleKeyboard(e) {
    const shortcuts = {
      'e': () => this.handleEdit(),
      'Delete': () => this.handleDelete(),
      'd': () => this.handleDuplicate(),
      'm': () => this.handleMove(),
      'c': () => this.handleStatusToggle()
    };

    const handler = shortcuts[e.key];
    if (handler && (e.ctrlKey || e.metaKey)) {
      e.preventDefault();
      handler();
    }
  }
}
```

## Testing Requirements

### Unit Tests
- [ ] Action button rendering and permissions
- [ ] Callback execution for each action type
- [ ] Loading states during async operations
- [ ] Dropdown menu functionality

### Integration Tests
- [ ] Integration with confirmation dialogs
- [ ] API calls for task operations
- [ ] Permission system integration
- [ ] Modal dialog integration

### Accessibility Tests
- [ ] Keyboard navigation through actions
- [ ] Screen reader announcements
- [ ] Focus management in dropdown menus
- [ ] ARIA attributes validation

### Performance Tests
- [ ] Rendering performance with many actions
- [ ] Memory usage during extended use
- [ ] Event handling efficiency
- [ ] Mobile touch response times

## Usage Examples

### Basic Usage
```html
<task-actions
  task="{taskObject}"
  onEdit="handleTaskEdit"
  onDelete="handleTaskDelete">
</task-actions>
```

### Full Permissions
```html
<task-actions
  task="{taskObject}"
  canEdit="true"
  canDelete="true"
  canMove="true"
  showLabels="false"
  orientation="horizontal"
  onEdit="handleTaskEdit"
  onDelete="handleTaskDelete"
  onDuplicate="handleTaskDuplicate"
  onMove="handleTaskMove"
  onStatusChange="handleStatusChange">
</task-actions>
```

### Limited Actions
```html
<task-actions
  task="{taskObject}"
  visibleActions="['edit', 'complete']"
  size="small"
  position="bottom"
  onEdit="handleTaskEdit"
  onStatusChange="handleStatusChange">
</task-actions>
```

This TaskActions component provides efficient task management capabilities while maintaining excellent usability and accessibility across all device types and user permission levels.