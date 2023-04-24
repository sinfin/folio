# frozen_string_literal: true

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
  plugin :libvips

  analyser :mime_type do |content|
    content.shell_eval do |path|
      "file --brief --mime-type #{path}"
    end.chomp
  end

  processor :normalize_profiles_via_liblcms2 do |content, *args|
    if shell("which", "jpgicc").blank?
      msg = "Missing jpgicc binary. Profiles not normalized."
      Raven.capture_message msg if defined?(Raven)
      logger.error msg if defined?(logger)
      content
    else
      content.shell_update escape: false do |old_path, new_path|
        "jpgicc #{old_path} #{new_path}"
      end
    end
  end

  processor :flatten do |content, *args|
    # TODO
    # content.process! :convert, "-flatten"
    content
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

  processor :ffmpeg_screenshot_to_jpg do |content, file_track_duration_in_ffmpeg_format, *args|
    content.shell_update ext: "jpg" do |old_path, new_path|
      "ffmpeg -y -i #{old_path} -ss #{file_track_duration_in_ffmpeg_format} -frames:v 1 #{new_path}"
    end
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
      rescue MultiExiftool::Error
        {}
      end
    end
  end

  secret Rails.application.secrets.dragonfly_secret

  url_format "/media/:job/:sha/:name"

  if Rails.env.test?
    datastore :file,
              root_path: Rails.root.join("public/system/dragonfly/#{Rails.env}/files"),
              server_root: Rails.root.join("public")
  elsif Rails.env.development? && !File.exist?(Rails.root.join(".env"))
    puts "\nMissing .env file, not setting up dragonfly correctly.\n\n"
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
