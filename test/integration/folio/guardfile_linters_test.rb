# frozen_string_literal: true

require "test_helper"
require "open3"

# CI guardrail: same intent as +Guardfile+ +guard :rubocop+ / +guard :slimlint+ (see comments there).
# Keep paths in sync when changing +watch+ regexes in +Guardfile+.
# Uses +Folio::Engine.root+ (gem root); +Rails.root+ is +test/dummy+ here.
class Folio::GuardfileLintersTest < Minitest::Test
  # Mirrors Guardfile :rubocop watches: (app|config|db|test)/**/*.rb and lib/**/*.rb|rake
  RUBOCOP_DIRS = %w[app config db test lib].freeze

  # Mirrors Guardfile :slimlint watch: (app|test)/.+.slim
  SLIMLINT_DIRS = %w[app test].freeze

  def gem_root
    Folio::Engine.root
  end

  def test_rubocop_has_no_offenses_for_guard_watched_paths
    dirs = RUBOCOP_DIRS.filter_map { |d| p = gem_root.join(d); p if p.directory? }.map(&:to_s)
    assert dirs.any?, "expected at least one of #{RUBOCOP_DIRS.join(", ")} under #{gem_root}"

    output, status = Open3.capture2e(
      { "RUBOCOP_CACHE_ROOT" => gem_root.join("test/dummy/tmp/rubocop_cache").to_s },
      "bundle", "exec", "rubocop", "--format", "simple",
      *dirs,
      chdir: gem_root.to_s
    )

    return if status.success?

    flunk "RuboCop reported offenses (parity with Guardfile :rubocop). Output:\n#{output}"
  end

  def test_slim_lint_has_no_offenses_for_guard_watched_paths
    dirs = SLIMLINT_DIRS.filter_map { |d| p = gem_root.join(d); p if p.directory? }.map(&:to_s)
    skip "no #{SLIMLINT_DIRS.join("/")} directories under #{gem_root}" if dirs.empty?

    output, status = Open3.capture2e(
      "bundle", "exec", "slim-lint", *dirs,
      chdir: gem_root.to_s
    )

    return if status.success?

    flunk "slim-lint reported issues (parity with Guardfile :slimlint). Output:\n#{output}"
  end
end
