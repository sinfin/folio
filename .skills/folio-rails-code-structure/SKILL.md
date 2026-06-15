---
name: folio-rails-code-structure
description: >-
  Ruby/Rails code structure conventions for Folio: keeping model, controller,
  and concern entrypoints thin; extracting multi-step parsing, decision, or
  orchestration logic to focused classes under lib; and avoiding helper-method
  clusters on Rails integration objects. Use when adding or refactoring Ruby
  methods, controller actions, model hooks, concerns, or service-style code.
---

# Rails code structure (Folio)

Use this skill when Ruby/Rails code would otherwise add several helper methods
to a model, controller, concern, or similar integration object.

## Thin entrypoints

Keep public model methods, controller actions, callbacks, hooks, and concern
methods focused on their integration role.

If a method such as `abc` needs parsing, policy checks, transformations, or
multi-step decisions, do not add a cluster of private helpers that only `abc`
uses. Extract that work into a focused class under the relevant `lib/` tree and
call it from `abc`.

```ruby
def abc
  MyFeature::Abc.call(self)
end
```

Prefer a single clear entrypoint on the model/controller over spreading the
implementation across incidental private helpers there.

## Focused classes

- Put extracted non-Rails objects under `lib/` with a namespace matching the
  owning feature or domain.
- Give the class one job and a small public API, usually `.call` or one clearly
  named instance method.
- Keep private helper methods inside that focused class when they support its
  single responsibility.
- In optional packs, use the pack's own `lib/` tree for pack-owned focused
  classes.

## Method signatures

- When a method takes more than two arguments, use keyword arguments instead of
  positional arguments. This applies to private helpers as well as public APIs.

## Jobs

Jobs are already focused classes that perform one unit of work. Do not extract
from a job just to satisfy this convention. Normal private helper methods are
fine inside a job when they support the job's single responsibility.
