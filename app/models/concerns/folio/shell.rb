# frozen_string_literal: true

require 'open3'

module Folio::Shell
  extend ActiveSupport::Concern

  private
    def shell(*command)
      cmd = command.join(' ')

      stdout, stderr, status = Open3.capture3(*command)

      if status == 0
        stdout.chomp
      else
        fail "Failed: '#{cmd}' failed with '#{stderr.chomp}'. Stdout: '#{stdout.chomp}'."
      end
    end
end
