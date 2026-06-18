# frozen_string_literal: true

# CI enforces the same lint scope in test/integration/folio/guardfile_linters_test.rb — update that test
# when you change the watch patterns below.

require_relative "lib/guard/standard_js"

guard :rubocop, cli: ["--autocorrect-all"] do
  watch(/^(app|config|db|test)\/.+\.rb$/)
  watch(/^lib\/.+\.(rb|rake)$/)

  watch(%r{(?:.+/)?\.rubocop(?:_todo)?\.yml$}) { |m| File.dirname(m[0]) }
end

guard :slimlint do
  watch(/^(app|test)\/.+(\.slim)$/)
end

guard :standard_js, all_on_start: true do
  watch(/^(app|test\/dummy\/app)\/.+(\.js)$/)
end
