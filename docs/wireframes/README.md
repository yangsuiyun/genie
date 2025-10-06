# Wireframe Standards and ASCII Art Conventions

## ASCII Wireframe Symbols

### Layout Structure
```
┌─────────────────┐  Top-left corner
│                 │  Vertical borders
└─────────────────┘  Bottom-right corner
```

### Components
```
[Button]             - Interactive buttons
<Input Field>        - Text input fields
{Dropdown}           - Dropdown selectors
(•) Radio            - Radio buttons
[x] Checkbox         - Checkboxes
```

### Content Areas
```
████████████████     - Solid content blocks
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒     - Secondary content
░░░░░░░░░░░░░░░░     - Background/placeholder
```

### Text Representation
```
Title Text           - Component/section titles
lorem ipsum text     - Body content placeholder
• List item          - Bulleted lists
1. Numbered item     - Numbered lists
```

### Navigation Elements
```
≡ Menu               - Hamburger menu
⊞ Expand             - Expandable sections
⊟ Collapse           - Collapsible sections
← → ↑ ↓             - Directional navigation
```

### Icons and Indicators
```
🍅 Pomodoro          - Pomodoro timer
📋 Projects          - Project management
✅ Completed         - Completed tasks
⚠️  Warning          - Alerts/warnings
📊 Statistics        - Data/charts
⚙️  Settings         - Configuration
```

## Layout Conventions

### Standard Dimensions
- **Total Width**: 80 characters maximum
- **Sidebar Width**: 20 characters
- **Main Content**: 55 characters
- **Margins**: 2 characters on each side

### Responsive Breakpoints
- **Desktop** (>1024px): Full layout with sidebar
- **Tablet** (768-1024px): Compressed sidebar
- **Mobile** (<768px): Stacked layout

### Component Spacing
- **Between sections**: 2 empty lines
- **Between components**: 1 empty line
- **Component padding**: 1 character minimum

## Example Wireframe Structure
```
┌──────────────────────────────────────────────────────────────────────────────┐
│                              Page Title                                      │
├──────────────┬───────────────────────────────────────────────────────────────┤
│              │                                                               │
│   Sidebar    │                Main Content Area                              │
│              │                                                               │
│  📋 Projects │  ┌─────────────────────────────────────────────────────────┐  │
│  • Project 1 │  │                  Component Area                         │  │
│  • Project 2 │  │                                                         │  │
│              │  │  [Button]     <Input Field>     {Dropdown}              │  │
│  📊 Stats    │  │                                                         │  │
│  🍅 4 today  │  │  Lorem ipsum content area with sample text              │  │
│  ⏱️ 2h 30m   │  │  and additional descriptive content here                │  │
│              │  └─────────────────────────────────────────────────────────┘  │
│              │                                                               │
└──────────────┴───────────────────────────────────────────────────────────────┘
```

## Validation Rules

### Required Elements
- [ ] All wireframes must fit within 80 character width
- [ ] Component boundaries clearly marked with ASCII art
- [ ] Consistent symbol usage throughout all wireframes
- [ ] Proper spacing and alignment maintained
- [ ] Labels and content clearly readable

### Quality Standards
- [ ] Layout proportions match responsive design requirements
- [ ] Interactive elements clearly distinguished from static content
- [ ] Navigation flow logical and intuitive
- [ ] Component hierarchy visually apparent
- [ ] Accessibility considerations noted in labels

This standard ensures consistent, readable wireframes that effectively communicate the project-first UI design architecture.