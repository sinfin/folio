# frozen_string_literal: true

require "dragonfly"
require "dragonfly/s3_data_store"
require "open3"

Dragonfly.logger = Rails.logger
Rails.application.middleware.use Dragonfly::Middleware

# Add model functionality
if defined?(ActiveRecord::Base)
  ActiveRecord::Base.extend Dragonfly::Model
  ActiveRecord::Base.extend Dragonfly::Model::Validations
end

def shell(*command)
  cmd = command.join(" ")

  stdout, stderr, status = Open3.capture3(*command)

  if status == 0
    stdout.chomp
  else
    fail "Failed: '#{cmd}' failed with '#{stderr.chomp}'. Stdout: '#{stdout.chomp}'."
  end
end

Dragonfly.app.configure do
  plugin :imagemagick

  processor :cmyk_to_srgb do |content, *args|
    if /CMYK/.match?(shell("identify", content.file.path))
      content.shell_update escape: false do |old_path, new_path|
        cmyk_icc = "#{Folio::Engine.root}/data/icc_profiles/PSOuncoated_v3_FOGRA52.icc"
        srgb_icc = "#{Folio::Engine.root}/data/icc_profiles/sRGB_v4_ICC_preference.icc"
        "convert -profile #{cmyk_icc} '#{old_path}' -profile #{srgb_icc} -colorspace sRGB '#{new_path}'"
      end
    end
  end

  processor :flatten do |content, *args|
    content.process! :convert, "-flatten"
  end

  processor :auto_orient do |content, *args|
    content.process! :convert, "-auto-orient"
  end

  processor :jpegoptim do |content, *args|
    if shell("which", "jpegtran").blank?
      msg = "Missing jpegtran binary. Thumbnail not optimized."
      Raven.capture_message msg if defined?(Raven)
      logger.error msg if defined?(logger)
      content
    else
      content.shell_update do |old_path, new_path|
        "jpegtran -optimize -outfile #{new_path} #{old_path}"
      end
    end
  end

  processor :animated_gif_resize do |content, raw_size, *args|
    fail "Missing gifsicle binary." if shell("which", "gifsicle").blank?
    size = raw_size.match(/\d+x\d+/)[0] # get rid of resize options which gifsicle doesn't understand
    content.shell_update do |old_path, new_path|
      "gifsicle --resize-fit #{size} #{old_path} --output #{new_path}"
    end
  end

  processor :add_white_background do |content, *args|
    content.process! :convert, "-background white -alpha remove"
  end

  processor :convert_to_webp do |content, *args|
    content.shell_update ext: "webp" do |old_path, new_path|
      "cwebp -q 85 #{old_path} -o #{new_path}"
    end
  end

  analyser :metadata do |content|
    if shell("which", "exiftool").blank?
      msg = "Missing ExifTool binary. Metadata not processed."
      Raven.capture_message msg if defined?(Raven)
      logger.error msg if defined?(logger)
      # content
      {}
    else
      begin
        reader = MultiExiftool::Reader.new
        reader.filenames = [content.file.path]
        reader.read.try(:first).try(:to_hash)
      # FIXME: rm ArgumentError after MultiExiftool issue is fixed
      # https://github.com/janfri/multi_exiftool/issues/14
      rescue MultiExiftool::Error, ArgumentError
        {}
      end
    end
  end

  secret Rails.application.secrets.dragonfly_secret

  url_format "/media/:job/:sha/:name"

  if Rails.env.test? || (Rails.env.development? && !ENV["DEV_S3_DRAGONFLY"])
    datastore :file,
              root_path: Rails.root.join("public/system/dragonfly/#{Rails.env}/files"),
              server_root: Rails.root.join("public")
  else
    datastore :s3,
              bucket_name: ENV.fetch("S3_BUCKET_NAME"),
              access_key_id: ENV.fetch("AWS_ACCESS_KEY_ID"),
              secret_access_key: ENV.fetch("AWS_SECRET_ACCESS_KEY"),
              url_scheme: ENV.fetch("S3_SCHEME"),
              region: ENV.fetch("S3_REGION"),
              root_path: "#{ENV.fetch('PROJECT_NAME')}/#{ENV.fetch('DRAGONFLY_RAILS_ENV') { Rails.env }}/files",
              fog_storage_options: { path_style: true }
  end
end
