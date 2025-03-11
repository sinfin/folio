# frozen_string_literal: true

guard :rubocop, cli: ["--autocorrect-all"] do
  watch(/^(app|config|db|test)\/.+\.rb$/)
  watch(/^lib\/.+\.(rb|rake)$/)

  watch(%r{(?:.+/)?\.rubocop(?:_todo)?\.yml$}) { |m| File.dirname(m[0]) }
end

guard :slimlint do
  watch(/^(app|test)\/.+(\.slim)$/)
end

guard :standard_js, all_on_start: true do
  watch(/^(app|test\/dummy\/app)\/frontend\/.+(\.js)$/)
end
