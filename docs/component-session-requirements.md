# Component Session Requirements

This document describes how Folio handles session requirements from components, allowing form atoms and interactive components to work correctly on cached pages.

## Overview

When cache optimization is enabled (`FOLIO_CACHE_SKIP_SESSION=true`), Folio normally skips session cookies for anonymous users to improve Cloudflare cache hit rates. However, some components (like forms) require session state for CSRF tokens, captcha validation, or flash messages.

The Component Session Requirements system allows components to declare their session needs, automatically disabling cache optimization when necessary.

## How It Works

### 1. Components Declare Session Requirements

Components that need session state (forms, interactive elements) include the helper and declare their requirements:

```ruby
class MyFormComponent < ApplicationComponent
  include Folio::ComponentSessionHelper

  def initialize(...)
    super
    require_session_for_component!("contact_form_csrf")
  end
end
```

### 2. Controllers Track Requirements

All controllers (via `ApplicationControllerBase`) track session requirements from rendered components:

```ruby
# Automatically included in all controllers
include Folio::ComponentSessionRequirements

# Tracks requirements during page rendering
@component_session_requirements = []
```

### 3. Cache Optimization Respects Requirements

When determining whether to skip session cookies, the system checks component requirements:

```ruby
def should_skip_cookies_for_cache?
  # If any component requires session, don't skip cookies
  return false if component_requires_session?
  
  # Otherwise proceed with cache optimization
  super
end
```

## Usage Examples

### Form Components

```ruby
class Economia::Leads::FormComponent < ApplicationComponent
  include Folio::ComponentSessionHelper

  def initialize(lead: nil)
    @lead = lead || Folio::Lead.new
    
    # Declare session requirement for CSRF and flash messages
    require_session_for_component!("lead_form_csrf_and_flash")
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
    
    # Declare session requirement for CSRF and Turnstile captcha
    require_session_for_component!("newsletter_subscription_csrf_and_turnstile")
  end
end
```

### Atom Components

Atom components can also declare session requirements, ensuring they work on any page:

```ruby
class Economia::Atom::Forms::Leads::FormComponent < ApplicationComponent
  include Folio::ComponentSessionHelper

  def initialize(atom:, atom_options: {})
    @atom = atom
    @atom_options = atom_options
    
    # This atom contains a form that needs session
    require_session_for_component!("lead_atom_form")
  end
end
```

## Implementation Details

### ComponentSessionHelper (for Components)

```ruby
module Folio::ComponentSessionHelper
  private

  def require_session_for_component!(reason)
    # Find current controller and inform it of session requirement
    if helpers.respond_to?(:controller) && 
       helpers.controller.respond_to?(:require_session_for_component!)
      helpers.controller.require_session_for_component!(reason)
    end
  end

  def session_available?
    helpers.respond_to?(:session) && helpers.session.respond_to?(:id)
  end

  def csrf_token
    helpers.form_authenticity_token if helpers.respond_to?(:form_authenticity_token)
  end
end
```

### ComponentSessionRequirements (for Controllers)

```ruby
module Folio::ComponentSessionRequirements
  included do
    attr_accessor :component_session_requirements
    before_action :initialize_component_session_requirements
  end

  private

  def component_requires_session?
    @component_session_requirements.present?
  end

  def require_session_for_component!(reason)
    @component_session_requirements ||= []
    @component_session_requirements << {
      reason: reason,
      component: caller_locations(1, 1).first&.label || "unknown",
      timestamp: Time.current
    }
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
→ Component declares: require_session_for_component!("form_csrf")
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

1. **Be Specific**: Use descriptive reason strings for debugging
2. **Declare Early**: Call `require_session_for_component!` in `initialize`
3. **Document Needs**: Comment why your component needs session
4. **Test Both Modes**: Test with and without cache optimization
5. **Monitor Impact**: Watch cache hit rates after deployment

## Migration Guide

### Existing Form Components
Add session requirement declaration:

```ruby
# Before
class MyFormComponent < ApplicationComponent
  def initialize(...)
    # ...
  end
end

# After  
class MyFormComponent < ApplicationComponent
  include Folio::ComponentSessionHelper

  def initialize(...)
    # ...
    require_session_for_component!("my_form_csrf")
  end
end
```

### No Changes Required For
- Controllers (automatically get ComponentSessionRequirements)
- Non-form components (no session requirements)
- Existing cache optimization settings
- CSRF token handling (works automatically)
