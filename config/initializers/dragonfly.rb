# frozen_string_literal: true

require 'dragonfly'
require 'dragonfly/s3_data_store'

Dragonfly.logger = Rails.logger
Rails.application.middleware.use Dragonfly::Middleware

# Add model functionality
if defined?(ActiveRecord::Base)
  ActiveRecord::Base.extend Dragonfly::Model
  ActiveRecord::Base.extend Dragonfly::Model::Validations
end

Dragonfly.app.configure do
  plugin :imagemagick

  processor :cmyk_to_srgb do |content, *args|
    if `identify '#{content.file.path}'` =~ /CMYK/
      content.shell_update escape: false do |old_path, new_path|
        cmyk_icc = "#{Folio::Engine.root}/data/icc_profiles/PSOuncoated_v3_FOGRA52.icc"
        srgb_icc = "#{Folio::Engine.root}/data/icc_profiles/sRGB_v4_ICC_preference.icc"
        "convert -profile #{cmyk_icc} '#{old_path}' -profile #{srgb_icc} -colorspace sRGB '#{new_path}'"
      end
    end
  end

  processor :jpegoptim do |content, *args|
    if `which jpegtran`.blank?
      msg = 'Missing jpegtran binary. Thumbnail not optimized.'
      Raven.capture_message msg if defined?(Raven)
      logger.error msg if defined?(logger)
      content
    else
      content.shell_update do |old_path, new_path|
        "jpegtran -optimize -outfile #{new_path} #{old_path}"  # The command sent to the command line
      end
    end
  end

  secret Rails.application.secrets.dragonfly_secret

  url_format '/media/:job/:sha/:name'

  if Rails.env.test? || (Rails.env.development? && !ENV['DEV_S3_DRAGONFLY'])
    datastore :file,
              root_path: Rails.root.join('public/system/dragonfly', Rails.env),
              server_root: Rails.root.join('public')
  else
    datastore :s3,
            bucket_name: ENV.fetch('S3_BUCKET_NAME'),
            access_key_id: ENV.fetch('AWS_ACCESS_KEY_ID'),
            secret_access_key: ENV.fetch('AWS_SECRET_ACCESS_KEY'),
            url_scheme: ENV.fetch('S3_SCHEME'),
            region: ENV.fetch('S3_REGION'),
            root_path: "#{ENV.fetch('PROJECT_NAME')}/#{Rails.env}/files",
            fog_storage_options: { path_style: true }
  end
end
