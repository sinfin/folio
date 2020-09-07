# frozen_string_literal: true

guard :rubocop, cli: ["--auto-correct-all"] do
  watch(%r{^(app|config|test)/.+\.rb$})
  watch(%r{^lib/.+\.(rb|rake)$})

  watch(%r{(?:.+/)?\.rubocop(?:_todo)?\.yml$}) { |m| File.dirname(m[0]) }
end

guard :slimlint, notify_on: :failure do
  watch(%r{^app/.+(\.slim)$})
end
