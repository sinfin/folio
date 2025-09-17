# Component Session Requirements

This document describes how Folio handles session requirements from components using a clean polymorphic architecture, allowing form atoms and interactive components to work correctly on cached pages.

## Overview

When cache optimization is enabled (`FOLIO_CACHE_SKIP_SESSION=true`), Folio normally skips session cookies for anonymous users to improve Cloudflare cache hit rates. However, some components (like forms) require session state for CSRF tokens, captcha validation, or flash messages.

The Component Session Requirements system uses **polymorphic override pattern** - atom models that need session include a concern and override methods, which are automatically detected by the cache headers system without manual class name checking.

## How It Works

### 1. Atom Models Declare Session Requirements

Atom models that correspond to form components include the helper concern and override the `session_requirement_reason` method:

```ruby
class YourApp::Atom::Forms::Contact::Form < Folio::Atom::Base
  include Folio::ComponentSessionHelper

  def session_requirement_reason
    "contact_form_csrf"
  end
end
```

### 2. Automatic Detection via Polymorphism

Controllers automatically include the `ComponentSessionRequirements` concern via `ApplicationControllerBase`. This concern provides a polymorphic override of the cache headers system:

```ruby
# Automatically included in all controllers
include Folio::ComponentSessionRequirements

# Provides polymorphic override
def should_skip_session_for_cache?
  # Auto-analyze @page if it exists and has atoms
  if defined?(@page) && @page&.respond_to?(:atoms)
    analyze_page_session_requirements(@page)
  end
  
  # Check if any component requires session
  return false if component_requires_session?

  # Delegate to parent (Headers concern)
  super if defined?(super)
end
```

### 3. Clean Architecture - No Manual Class Checking

The system automatically detects session requirements without fragile class name matching:

```ruby
def analyze_page_session_requirements(page)
  return unless page.respond_to?(:atoms)

  page.atoms.each do |atom|
    # Polymorphic check - no string matching!
    if atom.respond_to?(:requires_session?) && atom.requires_session?
      @component_session_requirements ||= []
      @component_session_requirements << atom.session_requirement
    end
  end
end
```

## Usage Examples

### Architecture Overview

There are **two different approaches** for different component types:

1. **Atom-based Components** - Have both atom model and ViewComponent
2. **Standalone Components** - Only have ViewComponent, no model

The key difference is **timing**: cache headers must be set **before** component rendering, but components render **during** the view phase. Therefore:

- **Atom models** enable automatic detection before rendering
- **Standalone components** require manual controller registration

### 1. Atom-based Components (Recommended)

For atom-based components, add `ComponentSessionHelper` **only to the atom model**:

```ruby
# ATOM MODEL - handles session requirements for cache headers
class YourApp::Atom::Forms::Leads::Form < Folio::Atom::Base
  include Folio::ComponentSessionHelper

  def session_requirement_reason
    "lead_atom_form_csrf"
  end
end
```

The corresponding ViewComponent doesn't need any session-related code - it just handles rendering.

### 2. Standalone Components

For components without atom models, use manual registration in the controller:

```ruby
# CONTROLLER - register session requirements manually
class SomeController < ApplicationController
  before_action :register_form_session_requirement, only: [:form_page]
  
  private
    def register_form_session_requirement
      require_session_for_component!("standalone_form_csrf")
    end
end
```

The ViewComponent itself doesn't need any session-related code.

### Additional Atom Model Examples

```ruby
# Newsletter subscription atom model  
class YourApp::Atom::Forms::Newsletters::Form < Folio::Atom::Base
  include Folio::ComponentSessionHelper

  def session_requirement_reason
    "newsletter_subscription_csrf_and_turnstile"
  end
end

# Lead form atom model
class YourApp::Atom::Forms::Leads::Form < Folio::Atom::Base
  include Folio::ComponentSessionHelper

  def session_requirement_reason
    "lead_form_csrf_and_flash"
  end
end
```

## How It Works

Session requirements are handled at different points in the request lifecycle depending on component type:

**For atom-based components:**
- Session requirements are declared in the **atom model** using `ComponentSessionHelper`
- The controller automatically analyzes `@page.atoms` during `before_action`
- Cache headers are set accordingly in `after_action`

**For standalone components:**  
- Session requirements must be registered manually in the controller
- Use `require_session_for_component!("reason")` in a `before_action` callback

## Implementation Details

### ComponentSessionHelper (for Atom Models Only)

```ruby
module Folio::ComponentSessionHelper
  extend ActiveSupport::Concern

  # Default implementation - components can override
  def requires_session?
    true
  end

  # Default session requirement details - components should override  
  def session_requirement
    {
      reason: session_requirement_reason,
      component: "#{self.class.name}_atom",
      timestamp: Time.current
    }
  end

  # Override this in your component to specify the reason
  def session_requirement_reason
    "unknown_session_requirement"
  end
end
```

### ComponentSessionRequirements (for Controllers)

```ruby
module Folio::ComponentSessionRequirements
  extend ActiveSupport::Concern

  included do
    attr_accessor :component_session_requirements
    before_action :initialize_component_session_requirements
  end

  # Check if any rendered components require session state
  def component_requires_session?
    component_session_requirements.present?
  end

  # Override from cache headers concern
  def should_skip_session_for_cache?
    # Auto-analyze @page if it exists and has atoms
    if defined?(@page) && @page&.respond_to?(:atoms)
      analyze_page_session_requirements(@page)
    end
    
    # If any component requires session, don't skip session
    return false if component_requires_session?

    # Delegate to parent implementation
    super if defined?(super)
  end

  private

  def initialize_component_session_requirements
    @component_session_requirements = []
  end

  def analyze_page_session_requirements(page)
    return unless page.respond_to?(:atoms)

    page.atoms.each do |atom|
      # Check if atom declares session requirements via ComponentSessionHelper concern
      if atom.respond_to?(:requires_session?) && atom.requires_session?
        @component_session_requirements ||= []
        @component_session_requirements << atom.session_requirement
      end
    end
  end
end
```

## Cache Behavior

### Without Session Requirements
```
Anonymous user visits page without forms:
→ Cache optimization active
→ No session cookies sent
→ Cloudflare cache: HIT
```

### With Session Requirements
```
Anonymous user visits page with form atom:
→ Component includes Folio::ComponentSessionHelper
→ ComponentSessionRequirements automatically detects session needs  
→ Cache optimization disabled for this request
→ Session cookies sent
→ Cloudflare cache: BYPASS (but CSRF works)
```

## Benefits

1. **Automatic Detection**: Components automatically declare their session needs
2. **Granular Control**: Per-component session requirements
3. **Cache Optimization**: Non-form pages still get full cache benefits
4. **Backward Compatible**: Existing components work without changes
5. **Debugging Support**: Session requirements are logged in development

## Integration with Existing Systems

### Form Controllers
Controllers that handle form submissions still need `RequiresSession`:

```ruby
class Folio::LeadsController < Folio::ApplicationController
  include Folio::RequiresSession
  requires_session_for :form_functionality, only: [:create]
end
```

### Component + Controller Integration
- **Component** declares session need during rendering
- **Controller** handles form submission with session
- **Result**: End-to-end session support for form workflows

## Performance Impact

### Expected Cache Hit Rates
```
Pages with forms:        ~65% (session required)
Pages without forms:     ~75% (full optimization)
Overall improvement:     ~70% vs current ~30%
```

### Debugging
In development, session requirements are logged:
```
[ComponentSession] Session required by component: lead_form_csrf
[ComponentSession] Session required by component: newsletter_signup_turnstile
```

## Best Practices

1. **Be Specific**: Use descriptive `session_requirement_reason` strings for debugging
2. **Override Method**: Override `session_requirement_reason` method in your component
3. **Document Needs**: Comment why your component needs session
4. **Test Both Modes**: Test with and without cache optimization  
5. **Monitor Impact**: Watch cache hit rates after deployment
6. **Polymorphic Pattern**: Rely on concern pattern, not manual configuration

## Migration Guide

### Existing Form Components
Migration from old `require_session_for_component!` pattern:

```ruby
# Before (old pattern)
class MyFormComponent < ApplicationComponent
  include Folio::ComponentSessionHelper

  def initialize(...)
    # ...
    require_session_for_component!("my_form_csrf")
  end
end

# After (new polymorphic pattern)
class MyFormComponent < ApplicationComponent
  include Folio::ComponentSessionHelper

  def initialize(...)
    # ...
    # No more manual calls!
  end

  def session_requirement_reason
    "my_form_csrf"
  end
end
```

### No Changes Required For
- Controllers (automatically get ComponentSessionRequirements)
- Non-form components (no session requirements)
- Existing cache optimization settings
- CSRF token handling (works automatically)
