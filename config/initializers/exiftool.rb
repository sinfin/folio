# frozen_string_literal: true

require 'mini_exiftool'
# MiniExiftool.command = '/path/to/my/exiftool'
MiniExiftool.pstore_dir = Rails.root.join('tmp').to_s
