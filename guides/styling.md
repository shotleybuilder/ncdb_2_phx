# Styling Guide

This guide covers customizing the visual appearance of NCDB2Phx admin interface components. The package provides semantic CSS classes and minimal base styling, allowing you to fully customize the design to match your application.

## Philosophy

NCDB2Phx follows a **semantic class** approach:

- **Package provides**: Meaningful CSS class names and minimal functional styling
- **Host app controls**: All visual design, colors, typography, spacing, and responsive behavior
- **Zero conflicts**: No opinionated styles that interfere with your design system
- **Framework agnostic**: Works with any CSS framework or custom styles

## CSS Class Reference

### Core Layout

#### Dashboard Components
```css
.sync-dashboard              /* Main dashboard container */
.dashboard-grid             /* Dashboard content grid */
.dashboard-header           /* Dashboard header section */
.dashboard-actions          /* Action buttons container */
.dashboard-card             /* Individual dashboard cards */
```

#### Navigation
```css
.sync-navbar                /* Main navigation bar */
.sync-navbar-brand         /* Brand/logo area */
.sync-navbar-nav           /* Navigation links container */
.sync-main-content         /* Main content area */
```

#### Page Structure
```css
.page-header               /* Page title and breadcrumbs */
.header-left               /* Left side of header */
.breadcrumb                /* Breadcrumb navigation */
.page-description          /* Page description text */
```

### Session Management

#### Session Cards
```css
.session-card              /* Individual session card */
.session-header            /* Session card header */
.session-name              /* Session name display */
.session-progress          /* Progress percentage */
.session-metrics           /* Session metrics container */
.session-actions           /* Session action buttons */
.session-list              /* List of sessions */
.session-item              /* Individual session list item */
```

#### Session Status
```css
.session-status            /* Status indicator base */
.session-status--running   /* Running session state */
.session-status--completed /* Completed session state */
.session-status--error     /* Error session state */
.session-status--pending   /* Pending session state */
```

### Progress Components

#### Progress Bars
```css
.progress-bar              /* Progress bar container */
.progress-fill             /* Progress fill element */
.progress-text             /* Progress percentage text */
.progress-stats            /* Progress statistics */
```

#### Status Indicators
```css
.status-indicator          /* Status dot/icon base */
.status-active             /* Active status */
.status-inactive           /* Inactive status */
.status-error              /* Error status */
.status-warning            /* Warning status */
```

### Monitoring Interface

#### System Monitoring
```css
.monitor-dashboard         /* Monitor main container */
.monitor-status            /* System status section */
.system-metrics            /* System metrics grid */
.metrics-grid              /* Metrics display grid */
.active-sessions           /* Active sessions section */
.sessions-grid             /* Sessions display grid */
```

#### Metric Cards
```css
.metric-card               /* Individual metric card */
.metric-header             /* Metric card header */
.metric-value              /* Metric value display */
.metric-label              /* Metric label text */
.metric--good              /* Good status modifier */
.metric--warning           /* Warning status modifier */
.metric--error             /* Error status modifier */
```

#### Performance Charts
```css
.performance-charts        /* Charts section container */
.charts-grid               /* Charts layout grid */
.chart-card                /* Individual chart card */
.chart-container           /* Chart content area */
.chart                     /* Chart element (for JS hooks) */
```

### Log Management

#### Log Display
```css
.log-index                 /* Log viewer main container */
.logs-container            /* Log entries container */
.logs-list                 /* Log entries list */
.log-entry                 /* Individual log entry */
.log-header                /* Log entry header */
.log-message               /* Log message content */
.log-timestamp             /* Log timestamp display */
```

#### Log Levels
```css
.log-error                 /* Error level logs */
.log-warning               /* Warning level logs */
.log-info                  /* Info level logs */
.log-debug                 /* Debug level logs */
.log-trace                 /* Trace level logs */
```

#### Log Controls
```css
.log-controls              /* Log control panel */
.log-filters               /* Filter controls section */
.log-actions               /* Action buttons section */
.filter-form               /* Filter form container */
.filter-group              /* Individual filter group */
.view-controls             /* View toggle controls */
```

#### Timeline View
```css
.timeline-container        /* Timeline view container */
.session-timeline          /* Session timeline */
.timeline-header           /* Timeline header */
.timeline                  /* Timeline content */
.timeline-group            /* Grouped timeline entries */
.timeline-timestamp        /* Timeline time markers */
.timeline-logs             /* Log entries in timeline */
.timeline-log-entry        /* Individual timeline log */
.timeline-marker           /* Timeline visual marker */
.timeline-content          /* Timeline entry content */
```

### Forms and Controls

#### Form Components
```css
.form-input                /* Base input styling */
.form-label                /* Form label styling */
.field                     /* Form field container */
.btn                       /* Button base class */
.btn-primary               /* Primary button variant */
.btn-outline               /* Outline button variant */
.btn-warning               /* Warning button variant */
.btn-error                 /* Error button variant */
.btn-sm                    /* Small button size */
```

#### Control Elements
```css
.toggle-control            /* Toggle switch container */
.live-indicator            /* Live streaming indicator */
.filter-group              /* Filter control group */
```

### Alerts and Notifications

#### Alert Components
```css
.alerts-section            /* Alerts container */
.alerts-list               /* List of alerts */
.alert                     /* Individual alert */
.alert-content             /* Alert message content */
.alert-timestamp           /* Alert timestamp */
.alert-error               /* Error alert variant */
.alert-warning             /* Warning alert variant */
.alert-info                /* Info alert variant */
```

### Utility Classes

#### State Classes
```css
.empty-state               /* Empty state message */
.loading-state             /* Loading indicator */
.error-state               /* Error state display */
.live-streaming            /* Live streaming active */
```

#### Badge Components
```css
.badge                     /* Badge base class */
.badge-error               /* Error badge */
.badge-warning             /* Warning badge */
.badge-info                /* Info badge */
.badge-success             /* Success badge */
```

#### Context and Details
```css
.log-context               /* Log context details */
.log-context-content       /* Context content area */
.context-item              /* Individual context item */
.log-stack-trace           /* Stack trace display */
```

## Framework Examples

### Tailwind CSS Integration

Create a comprehensive theme using Tailwind utilities:

```css
/* Dashboard Layout */
.sync-dashboard {
  @apply min-h-screen bg-gray-50;
}

.dashboard-grid {
  @apply grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 p-6;
}

.dashboard-card {
  @apply bg-white rounded-lg shadow-sm border border-gray-200 p-6;
}

/* Navigation */
.sync-navbar {
  @apply bg-white shadow-sm border-b border-gray-200 px-6 py-4;
}

.sync-navbar-brand {
  @apply font-bold text-xl text-gray-900;
}

.sync-main-content {
  @apply flex-1 overflow-auto;
}

/* Session Cards */
.session-card {
  @apply bg-white rounded-lg shadow-sm border border-gray-200 p-6 hover:shadow-md transition-shadow;
}

.session-header {
  @apply flex justify-between items-center mb-4;
}

.session-name {
  @apply font-semibold text-gray-900 truncate;
}

.session-status--running {
  @apply bg-green-100 text-green-800 px-2 py-1 rounded-full text-xs font-medium;
}

.session-status--error {
  @apply bg-red-100 text-red-800 px-2 py-1 rounded-full text-xs font-medium;
}

.session-status--completed {
  @apply bg-blue-100 text-blue-800 px-2 py-1 rounded-full text-xs font-medium;
}

/* Progress Components */
.progress-bar {
  @apply w-full bg-gray-200 rounded-full h-2 mb-2;
}

.progress-fill {
  @apply bg-blue-600 h-2 rounded-full transition-all duration-300 ease-out;
}

.progress-text {
  @apply text-sm text-gray-600 font-medium;
}

/* Metric Cards */
.metric-card {
  @apply bg-white rounded-lg p-4 border border-gray-200;
}

.metric-card.metric--good {
  @apply border-green-200 bg-green-50;
}

.metric-card.metric--warning {
  @apply border-yellow-200 bg-yellow-50;
}

.metric-card.metric--error {
  @apply border-red-200 bg-red-50;
}

.metric-value {
  @apply text-2xl font-bold text-gray-900;
}

.metric-label {
  @apply text-sm text-gray-600 uppercase tracking-wide font-medium;
}

/* Log Components */
.log-entry {
  @apply border-b border-gray-100 py-4 px-4 hover:bg-gray-50;
}

.log-entry.log-error {
  @apply border-l-4 border-red-500 bg-red-50;
}

.log-entry.log-warning {
  @apply border-l-4 border-yellow-500 bg-yellow-50;
}

.log-entry.log-info {
  @apply border-l-4 border-blue-500 bg-blue-50;
}

.log-header {
  @apply flex items-center justify-between mb-2;
}

.log-timestamp {
  @apply text-sm text-gray-500 font-mono;
}

.log-message {
  @apply text-gray-900;
}

/* Form Components */
.form-input {
  @apply block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm placeholder-gray-400 
         focus:outline-none focus:ring-blue-500 focus:border-blue-500;
}

.form-label {
  @apply block text-sm font-medium text-gray-700 mb-1;
}

.field {
  @apply mb-4;
}

/* Buttons */
.btn {
  @apply inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md 
         shadow-sm focus:outline-none focus:ring-2 focus:ring-offset-2 transition-colors;
}

.btn-primary {
  @apply text-white bg-blue-600 hover:bg-blue-700 focus:ring-blue-500;
}

.btn-outline {
  @apply text-gray-700 bg-white border-gray-300 hover:bg-gray-50 focus:ring-blue-500;
}

.btn-warning {
  @apply text-white bg-yellow-600 hover:bg-yellow-700 focus:ring-yellow-500;
}

.btn-error {
  @apply text-white bg-red-600 hover:bg-red-700 focus:ring-red-500;
}

.btn-sm {
  @apply px-3 py-1 text-xs;
}

/* Alerts */
.alert {
  @apply p-4 rounded-md mb-4;
}

.alert-error {
  @apply bg-red-50 border border-red-200 text-red-700;
}

.alert-warning {
  @apply bg-yellow-50 border border-yellow-200 text-yellow-700;
}

.alert-info {
  @apply bg-blue-50 border border-blue-200 text-blue-700;
}

/* Utility Classes */
.empty-state {
  @apply text-center py-12 text-gray-500;
}

.status-indicator {
  @apply inline-block w-3 h-3 rounded-full;
}

.status-active {
  @apply bg-green-500;
}

.status-error {
  @apply bg-red-500;
}

.status-warning {
  @apply bg-yellow-500;
}
```

### Bootstrap Integration

Integrate seamlessly with Bootstrap components:

```css
/* Extend Bootstrap classes */
.session-card {
  @extend .card;
  margin-bottom: 1rem;
}

.session-header {
  @extend .card-header;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.session-name {
  @extend .card-title;
  margin: 0;
}

.metric-card {
  @extend .card;
  @extend .text-center;
}

.metric-value {
  @extend .display-4;
  @extend .text-primary;
}

.log-entry {
  @extend .list-group-item;
}

.log-entry.log-error {
  @extend .list-group-item-danger;
}

.log-entry.log-warning {
  @extend .list-group-item-warning;
}

.log-entry.log-info {
  @extend .list-group-item-info;
}

.alert-error {
  @extend .alert;
  @extend .alert-danger;
}

.alert-warning {
  @extend .alert;
  @extend .alert-warning;
}

.alert-info {
  @extend .alert;
  @extend .alert-info;
}

/* Custom Bootstrap theme */
.sync-dashboard {
  background-color: var(--bs-light);
  min-height: 100vh;
}

.dashboard-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 1.5rem;
  padding: 2rem;
}

.progress-bar {
  @extend .progress;
  margin-bottom: 0.5rem;
}

.progress-fill {
  @extend .progress-bar;
  @extend .progress-bar-striped;
  @extend .progress-bar-animated;
}
```

### Custom CSS Framework

Create a complete custom design system:

```css
/* CSS Variables for theming */
:root {
  /* Colors */
  --sync-primary: #0066cc;
  --sync-primary-light: #3388dd;
  --sync-primary-dark: #004499;
  
  --sync-success: #28a745;
  --sync-warning: #ffc107;
  --sync-error: #dc3545;
  --sync-info: #17a2b8;
  
  --sync-gray-50: #f9fafb;
  --sync-gray-100: #f3f4f6;
  --sync-gray-200: #e5e7eb;
  --sync-gray-300: #d1d5db;
  --sync-gray-500: #6b7280;
  --sync-gray-700: #374151;
  --sync-gray-900: #111827;
  
  /* Typography */
  --sync-font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
  --sync-font-size-xs: 0.75rem;
  --sync-font-size-sm: 0.875rem;
  --sync-font-size-base: 1rem;
  --sync-font-size-lg: 1.125rem;
  --sync-font-size-xl: 1.25rem;
  --sync-font-size-2xl: 1.5rem;
  
  /* Spacing */
  --sync-space-1: 0.25rem;
  --sync-space-2: 0.5rem;
  --sync-space-3: 0.75rem;
  --sync-space-4: 1rem;
  --sync-space-6: 1.5rem;
  --sync-space-8: 2rem;
  
  /* Borders */
  --sync-border-radius: 0.5rem;
  --sync-border-width: 1px;
  --sync-border-color: var(--sync-gray-200);
  
  /* Shadows */
  --sync-shadow-sm: 0 1px 2px 0 rgba(0, 0, 0, 0.05);
  --sync-shadow: 0 1px 3px 0 rgba(0, 0, 0, 0.1), 0 1px 2px 0 rgba(0, 0, 0, 0.06);
  --sync-shadow-md: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
}

/* Base Styles */
.sync-dashboard {
  font-family: var(--sync-font-family);
  font-size: var(--sync-font-size-base);
  line-height: 1.5;
  color: var(--sync-gray-900);
  background-color: var(--sync-gray-50);
  min-height: 100vh;
}

/* Layout Components */
.dashboard-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(320px, 1fr));
  gap: var(--sync-space-6);
  padding: var(--sync-space-8);
}

.dashboard-card {
  background: white;
  border: var(--sync-border-width) solid var(--sync-border-color);
  border-radius: var(--sync-border-radius);
  box-shadow: var(--sync-shadow-sm);
  padding: var(--sync-space-6);
  transition: box-shadow 0.2s ease, transform 0.2s ease;
}

.dashboard-card:hover {
  box-shadow: var(--sync-shadow-md);
  transform: translateY(-1px);
}

/* Session Components */
.session-card {
  background: white;
  border: var(--sync-border-width) solid var(--sync-border-color);
  border-radius: var(--sync-border-radius);
  box-shadow: var(--sync-shadow-sm);
  padding: var(--sync-space-6);
  position: relative;
  overflow: hidden;
}

.session-card::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  width: 4px;
  height: 100%;
  background: var(--sync-gray-300);
}

.session-card.session-status--running::before {
  background: var(--sync-success);
}

.session-card.session-status--error::before {
  background: var(--sync-error);
}

.session-card.session-status--completed::before {
  background: var(--sync-primary);
}

.session-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: var(--sync-space-4);
}

.session-name {
  font-size: var(--sync-font-size-lg);
  font-weight: 600;
  color: var(--sync-gray-900);
  margin: 0;
}

/* Progress Components */
.progress-bar {
  width: 100%;
  height: 8px;
  background: var(--sync-gray-200);
  border-radius: 4px;
  overflow: hidden;
  margin-bottom: var(--sync-space-2);
}

.progress-fill {
  height: 100%;
  background: var(--sync-primary);
  border-radius: 4px;
  transition: width 0.3s ease;
  position: relative;
}

.progress-fill::after {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  bottom: 0;
  right: 0;
  background: linear-gradient(
    45deg,
    rgba(255, 255, 255, 0.2) 25%,
    transparent 25%,
    transparent 50%,
    rgba(255, 255, 255, 0.2) 50%,
    rgba(255, 255, 255, 0.2) 75%,
    transparent 75%
  );
  background-size: 16px 16px;
  animation: progress-stripes 1s linear infinite;
}

@keyframes progress-stripes {
  from { background-position: 0 0; }
  to { background-position: 16px 0; }
}

/* Status Indicators */
.status-indicator {
  display: inline-block;
  width: 12px;
  height: 12px;
  border-radius: 50%;
  margin-right: var(--sync-space-2);
}

.status-active {
  background: var(--sync-success);
  box-shadow: 0 0 0 2px rgba(40, 167, 69, 0.2);
}

.status-error {
  background: var(--sync-error);
  box-shadow: 0 0 0 2px rgba(220, 53, 69, 0.2);
}

.status-warning {
  background: var(--sync-warning);
  box-shadow: 0 0 0 2px rgba(255, 193, 7, 0.2);
}

/* Buttons */
.btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  padding: var(--sync-space-2) var(--sync-space-4);
  font-size: var(--sync-font-size-sm);
  font-weight: 500;
  line-height: 1.5;
  border: var(--sync-border-width) solid transparent;
  border-radius: var(--sync-border-radius);
  text-decoration: none;
  cursor: pointer;
  transition: all 0.2s ease;
  min-height: 36px;
}

.btn:focus {
  outline: none;
  box-shadow: 0 0 0 3px rgba(0, 102, 204, 0.1);
}

.btn-primary {
  color: white;
  background: var(--sync-primary);
  border-color: var(--sync-primary);
}

.btn-primary:hover {
  background: var(--sync-primary-dark);
  border-color: var(--sync-primary-dark);
  transform: translateY(-1px);
  box-shadow: var(--sync-shadow);
}

.btn-outline {
  color: var(--sync-gray-700);
  background: white;
  border-color: var(--sync-gray-300);
}

.btn-outline:hover {
  background: var(--sync-gray-50);
  border-color: var(--sync-gray-400);
}

.btn-sm {
  padding: var(--sync-space-1) var(--sync-space-3);
  font-size: var(--sync-font-size-xs);
  min-height: 28px;
}

/* Responsive Design */
@media (max-width: 768px) {
  .dashboard-grid {
    grid-template-columns: 1fr;
    padding: var(--sync-space-4);
    gap: var(--sync-space-4);
  }
  
  .session-header {
    flex-direction: column;
    align-items: flex-start;
  }
  
  .session-actions {
    margin-top: var(--sync-space-3);
    width: 100%;
  }
}

/* Dark Mode Support */
@media (prefers-color-scheme: dark) {
  :root {
    --sync-gray-50: #1f2937;
    --sync-gray-100: #374151;
    --sync-gray-200: #4b5563;
    --sync-gray-300: #6b7280;
    --sync-gray-500: #9ca3af;
    --sync-gray-700: #d1d5db;
    --sync-gray-900: #f9fafb;
    --sync-border-color: var(--sync-gray-200);
  }
  
  .dashboard-card {
    background: var(--sync-gray-100);
  }
  
  .session-card {
    background: var(--sync-gray-100);
  }
}
```

## Customization Patterns

### Brand Integration

Customize colors to match your brand:

```css
:root {
  /* Override default colors with your brand palette */
  --sync-primary: #your-brand-primary;
  --sync-primary-light: #your-brand-light;
  --sync-primary-dark: #your-brand-dark;
}

.sync-navbar {
  background: var(--your-brand-primary);
  color: white;
}

.btn-primary {
  background: var(--your-brand-primary);
  border-color: var(--your-brand-primary);
}

.progress-fill {
  background: var(--your-brand-primary);
}
```

### Layout Customization

Modify layouts for your specific needs:

```css
/* Sidebar layout instead of top navigation */
.sync-dashboard {
  display: flex;
  height: 100vh;
}

.sync-sidebar {
  width: 250px;
  background: white;
  border-right: 1px solid var(--sync-gray-200);
  padding: 1rem;
}

.sync-main-content {
  flex: 1;
  overflow-y: auto;
  padding: 2rem;
}

/* Full-width dashboard grid */
.dashboard-grid {
  grid-template-columns: repeat(12, 1fr);
}

.dashboard-card--span-2 {
  grid-column: span 2;
}

.dashboard-card--span-4 {
  grid-column: span 4;
}
```

### Component Overrides

Override specific components while keeping others:

```css
/* Custom session card design */
.session-card {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border: none;
  box-shadow: 0 10px 25px rgba(102, 126, 234, 0.3);
}

.session-name {
  color: white;
  font-size: 1.25rem;
}

.session-status--running {
  background: rgba(255, 255, 255, 0.2);
  color: white;
  border: 1px solid rgba(255, 255, 255, 0.3);
}

/* Custom progress bar */
.progress-bar {
  height: 12px;
  border-radius: 6px;
  background: rgba(255, 255, 255, 0.2);
}

.progress-fill {
  background: linear-gradient(90deg, #00d2ff 0%, #3a7bd5 100%);
  border-radius: 6px;
}
```

## Accessibility Considerations

Ensure your styles maintain accessibility:

```css
/* High contrast mode support */
@media (prefers-contrast: high) {
  .session-card {
    border: 2px solid currentColor;
  }
  
  .btn {
    border: 2px solid currentColor;
  }
  
  .progress-bar {
    border: 1px solid currentColor;
  }
}

/* Reduced motion support */
@media (prefers-reduced-motion: reduce) {
  .progress-fill,
  .btn,
  .session-card {
    transition: none;
  }
  
  .progress-fill::after {
    animation: none;
  }
}

/* Focus indicators */
.btn:focus,
.form-input:focus {
  outline: 2px solid var(--sync-primary);
  outline-offset: 2px;
}

/* Screen reader friendly status text */
.status-indicator::after {
  content: attr(aria-label);
  position: absolute;
  left: -10000px;
  top: auto;
  width: 1px;
  height: 1px;
  overflow: hidden;
}
```

## Testing Your Styles

### Style Guide Component

Create a style guide page to test all components:

```elixir
defmodule MyAppWeb.StyleGuideLive do
  use MyAppWeb, :live_view
  
  def render(assigns) do
    ~H"""
    <div class="style-guide">
      <h1>NCDB2Phx Style Guide</h1>
      
      <!-- Test all component states -->
      <section>
        <h2>Session Cards</h2>
        <div class="dashboard-grid">
          <div class="session-card session-status--running">
            <div class="session-header">
              <h3 class="session-name">Running Session</h3>
              <span class="session-status session-status--running">Running</span>
            </div>
            <div class="progress-bar">
              <div class="progress-fill" style="width: 65%"></div>
            </div>
            <div class="progress-text">65% complete</div>
          </div>
          
          <div class="session-card session-status--error">
            <div class="session-header">
              <h3 class="session-name">Failed Session</h3>
              <span class="session-status session-status--error">Error</span>
            </div>
            <p class="error-message">Connection timeout</p>
          </div>
        </div>
      </section>
      
      <!-- Test buttons -->
      <section>
        <h2>Buttons</h2>
        <div class="button-group">
          <button class="btn btn-primary">Primary</button>
          <button class="btn btn-outline">Outline</button>
          <button class="btn btn-warning">Warning</button>
          <button class="btn btn-error">Error</button>
          <button class="btn btn-sm btn-primary">Small</button>
        </div>
      </section>
      
      <!-- Test form elements -->
      <section>
        <h2>Form Elements</h2>
        <div class="field">
          <label class="form-label">Session Name</label>
          <input type="text" class="form-input" placeholder="Enter session name">
        </div>
      </section>
    </div>
    """
  end
end
```

### CSS Testing Checklist

- [ ] Test all component states (running, error, completed, pending)
- [ ] Verify responsive behavior on mobile, tablet, desktop
- [ ] Test dark mode appearance (if supported)
- [ ] Verify high contrast mode compatibility
- [ ] Test with reduced motion preferences
- [ ] Validate focus indicators for keyboard navigation
- [ ] Test color combinations for accessibility (WCAG AA)
- [ ] Verify print styles (if needed)

## Performance Optimization

### CSS Organization

Structure your CSS for optimal loading:

```css
/* Critical above-the-fold styles */
.sync-dashboard,
.dashboard-header,
.dashboard-grid {
  /* Inline critical CSS */
}

/* Non-critical styles - load async */
.log-details,
.chart-components,
.advanced-filters {
  /* Load via separate stylesheet */
}
```

### CSS Custom Properties

Use CSS custom properties for theme switching:

```css
/* Light theme (default) */
:root {
  --bg-primary: white;
  --text-primary: #111827;
  --border-color: #e5e7eb;
}

/* Dark theme */
[data-theme="dark"] {
  --bg-primary: #1f2937;
  --text-primary: #f9fafb;
  --border-color: #4b5563;
}

/* Components use custom properties */
.dashboard-card {
  background: var(--bg-primary);
  color: var(--text-primary);
  border-color: var(--border-color);
}
```

## Best Practices

### 1. Use Semantic Class Names
- Classes describe purpose, not appearance
- Easy to understand and maintain
- Supports design system evolution

### 2. Follow CSS Architecture
- Group related styles together
- Use consistent naming conventions
- Organize files logically (layout, components, utilities)

### 3. Plan for Scalability
- Use CSS custom properties for theming
- Create reusable utility classes
- Plan for responsive design from the start

### 4. Test Thoroughly
- Test across browsers and devices
- Verify accessibility compliance
- Test with real data and edge cases

### 5. Document Your Styles
- Comment complex CSS rules
- Maintain a style guide
- Document custom properties and their usage

The NCDB2Phx styling system provides maximum flexibility while maintaining semantic meaning. Use this guide to create a cohesive, accessible, and maintainable design that perfectly matches your application's visual identity.