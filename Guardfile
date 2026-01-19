# frozen_string_literal: true

require_relative "lib/guard/standard_js"

guard :rubocop, cli: ["--autocorrect-all"] do
  watch(/^(app|config|db|test|packs)\/.+\.rb$/)
  watch(/^lib\/.+\.(rb|rake)$/)

  watch(%r{(?:.+/)?\.rubocop(?:_todo)?\.yml$}) { |m| File.dirname(m[0]) }
end

guard :slimlint do
  watch(/^(app|test|packs)\/.+(\.slim)$/)
end

guard :standard_js, all_on_start: true do
  watch(/^(app|packs|test\/dummy\/app)\/.+(\.js)$/)
end
