# frozen_string_literal: true

# Slim 4.0+ stopped converting underscores to hyphens in data/aria attributes.
# We rely on this conversion extensively (e.g. data_test_id -> data-test-id),
# so re-enable the old Slim 3.x behavior.
Slim::Engine.set_options hyphen_attrs: %w[data aria],
                         hyphen_underscore_attrs: true
