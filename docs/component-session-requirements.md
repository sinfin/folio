# Component Session Requirements

This document describes how Folio handles session requirements from components using a clean polymorphic architecture, allowing form atoms and interactive components to work correctly on cached pages.

## Overview

When cache optimization is enabled (`FOLIO_CACHE_SKIP_SESSION=true`), Folio normally skips session cookies for anonymous users to improve Cloudflare cache hit rates. However, some components (like forms) require session state for CSRF tokens, captcha validation, or flash messages.

The Component Session Requirements system uses **polymorphic override pattern** - components that need session include a concern and override methods, which are automatically detected by the cache headers system without manual class name checking.

## How It Works

### 1. Components Declare Session Requirements

Components that need session state (forms, interactive elements) include the helper concern and override the `session_requirement_reason` method:

```ruby
class MyFormComponent < ApplicationComponent
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

### Form Components

```ruby
class Project::Leads::FormComponent < ApplicationComponent
  include Folio::ComponentSessionHelper

  def initialize(lead: nil)
    @lead = lead || Folio::Lead.new
  end

  def session_requirement_reason
    "lead_form_csrf_and_flash"
  end

  def form(&block)
    helpers.simple_form_for(@lead, { url: leads_path }, &block)
  end
end
```

### Newsletter Signup Components

```ruby
class Folio::NewsletterSubscriptions::FormComponent < ApplicationComponent
  include Folio::ComponentSessionHelper

  def initialize(newsletter_subscription: nil, view_options: {})
    @newsletter_subscription = newsletter_subscription || Folio::NewsletterSubscription.new
    @view_options = view_options
  end

  def session_requirement_reason
    "newsletter_subscription_csrf_and_turnstile"  
  end
end
```

### Atom Components

Atom components can also declare session requirements, ensuring they work on any page:

```ruby
class Project::Atom::Forms::Leads::FormComponent < ApplicationComponent
  include Folio::ComponentSessionHelper

  def initialize(atom:, atom_options: {})
    @atom = atom
    @atom_options = atom_options
  end

  def session_requirement_reason
    "lead_atom_form"
  end
end
```

## Implementation Details

### ComponentSessionHelper (for Components)

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
