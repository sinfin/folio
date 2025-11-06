# frozen_string_literal: true

AwsFileHandler.configure do |config|
  # This is the main configuration for the AwsFileHandler gem.
  config.access_key_id = ENV.fetch("AWS_ACCESS_KEY_ID")
  config.secret_access_key = ENV.fetch("AWS_SECRET_ACCESS_KEY")
  config.region = ENV.fetch("S3_REGION")
  config.bucket_name = ENV.fetch("S3_BUCKET_NAME")

  # Required only for development environment
  config.session_token = ENV.fetch("AWS_SESSION_TOKEN", nil)

  # Secret to sign and verify JWT tokens.
  config.jwt_file_processing_secret = ENV.fetch("AWS_FILE_HANDLER_JWT_FILE_PROCESSING_SECRET")
  # API token for communication from AWS notification lambda to our backend.
  config.api_token = ENV.fetch("AWS_FILE_HANDLER_API_TOKEN", nil)
  # SQS queue name for sending messages to uploading lambda.
  config.upload_lambda_queue = ENV.fetch("AWS_FILE_HANDLER_UPLOAD_LAMBDA_QUEUE")
  # SQS queue name for sending messages to processing lambda.
  config.processing_lambda_queue = ENV.fetch("AWS_FILE_HANDLER_PROCESSING_LAMBDA_QUEUE")

  # Enable/disable ActiveJobs. It's called only if `AWS_FILE_HANDLER_ACTIVE_JOBS` is set to true or not set at all.
  #
  # Examples:
  # config.active_jobs = -> { Rails.env.development? } # default
  # config.active_jobs = false

  # If set to false, it will raise an exception when AWS should be used. Just protection we will not call AWS. It's used
  # only if `AWS_FILE_HANDLER_ENABLED` is set to true or not set at all.
  #
  # Examples:
  # config.enabled = -> { Rails.env.production? || Rails.env.development? } # default
  # config.enabled = true

  # belongs_to user association if required, otherwise it will be nil.
  #
  # Parameters:
  #   `caller_class` is AwsFileHandler::File
  #
  # Examples:
  # config.user_association = proc do |caller_class|
  #   caller_class.belongs_to :user, class_name: "User", foreign_key: :user_id, optional: true
  # end
  # config.user_association = nil # default
  config.user_association = proc do |caller_class|
    caller_class.belongs_to :user, class_name: "Folio::User", foreign_key: :user_id, optional: true
  end

  # Block to specify the part of the download URL path used by `download_s3_path`. By default, it creates the name from
  # the base class of the `typeable` association if possible, otherwise it creates the name from the
  # `AwsFileHandler::File` class. Structure is `{file_type}/{name}?jwt={jwt_token}`. So, if we have the `typeable`
  # association with the `Folio::File::Image` class with the name `some_image.jpg`, the path will be
  # `images/some_image.jpg?jwt=...`. If the `typeable` association is not set, the path will be
  # `files/some_image.jpg?jwt=...`.
  #
  # Parameters:
  #   `caller` is an instance of AwsFileHandler::File
  #
  # Examples:
  # config.file_type = ->(caller) { (caller.typeable || caller).model_name.element.pluralize } # default
  # config.file_type = "files"

  # This block is called after a file is created. By default, it creates a job that periodically checks if a file was
  # uploaded or not yet.
  #
  # Parameters:
  #   `caller` is an instance of AwsFileHandler::File
  #
  # Examples:
  # config.after_file_initialize = ->(caller) { caller.check_aws_file(AwsFileHandler::CheckUploadedJob) } # default
  # config.after_file_initialize = nil

  # This block is called after a file was successfully uploaded. By default, it creates a job that periodically checks
  # if a file created `metadata.json` or not yet. It potentially downloads and processes the file.
  #
  # Parameters:
  #   `caller` is an instance of AwsFileHandler::File
  #
  # Examples:
  # config.after_file_upload = ->(caller) { caller.check_aws_file(AwsFileHandler::CheckMetadataJob) } # default
  # config.after_file_upload = nil

  # This block is called after a file was successfully processed. By default, it calls a method which sends a SQS
  # notification to AWS processing lambda if a file meets conditions
  #
  # Parameters:
  #   `caller` is an instance of AwsFileHandler::File
  #
  # Examples:
  # config.after_file_process = ->(caller) { caller.notify_aws_processing_lambda } # default
  # config.after_file_process = nil

  # This block is called when a file was marked as failed. This can happen in any phase of the process.
  #
  # Parameters:
  #   `caller` is an instance of AwsFileHandler::File
  #
  # Examples:
  # config.after_file_failed = ->(caller) { Rails.logger.error("Something went wrong") }
  # config.after_file_failed = nil # default

  # This block is called when a file was marked for reprocessing. By default, it sends a SQS message to AWS upload
  # lambda and creates a job that periodically checks if a `metadata.json` was created or not yet. It potentially
  # downloads and processes the file.
  #
  # Parameters:
  #   `caller` is an instance of AwsFileHandler::File
  #
  # Examples:
  # config.after_file_reprocess = proc do |caller|
  #   AwsFileHandler::Sqs::UploadLambdaService.reprocess_metadata(caller.full_s3_path)
  #   caller.check_aws_file(AwsFileHandler::CheckMetadataJob)
  # end # default
  # config.after_file_reprocess = nil

  # Check if we want to run rekognition for the `caller` file. By default, it returns false.
  #
  # Parameters:
  #   `caller` is an instance of AwsFileHandler::File
  #
  # Examples:
  # config.run_rekognition = ->(caller) { caller.typeable.run_rekognition? }
  # config.run_rekognition = false # default

  # Check if the file is valid, or we want to stop processing. It's used after storing metadata into a database. For
  # example, we want to check if the file has a valid mime type. If the method returns false, it will be processed as
  # processing_failed.
  #
  # Parameters:
  #   `caller` is an instance of AwsFileHandler::File
  #
  # Examples:
  # config.valid_file = ->(caller) { caller.typeable.valid_file? }
  # config.valid_file = true # default

  # Additional block for processing `metadata.json` file. It's called after check if it should be processed but before
  # any other changes. You can modify the data, and they will be stored in a database.
  #
  # Parameters:
  #   `caller` is an instance of AwsFileHandler::File
  #   `metadata_json` content of `metadata.json` file
  #   `file_last_modified` is a timestamp when the file was last modified
  #
  # Examples:
  # config.process_metadata = proc do |caller, metadata_json, file_last_modified|
  #   caller.typeable.process_metadata(metadata_json, file_last_modified)
  # end
  # config.process_metadata = nil # default

  # Additional block for processing `rekognition.metadata.json` file. It's called after check if it should be
  # processed but before any other changes. You can modify the data, and they will be stored in a database.
  #
  # Parameters:
  #   `caller` is an instance of AwsFileHandler::File
  #   `metadata_json` content of `rekognition.metadata.json` file
  #   `file_last_modified` is a timestamp when the file was last modified
  #
  # Examples:
  # config.process_rekognition_metadata = proc do |caller, metadata_json, file_last_modified|
  #   caller.typeable.process_rekognition_metadata(metadata_json, file_last_modified)
  # end
  # config.process_rekognition_metadata = nil # default

  # Additional block for processing `<your_custom.json>` file. It's called after check if it should be
  # processed but before any other changes. You can modify the data, and they will be stored in a database.
  #
  # Parameters:
  #   `caller` is an instance of AwsFileHandler::File
  #   `filename` <your_custom> file name
  #   `metadata_json` content of `<your_custom.json>` file
  #   `file_last_modified` is a timestamp when the file was last modified
  #
  # Examples:
  # config.process_custom_metadata = proc do |caller, filename, metadata_json, file_last_modified|
  #   caller.typeable.process_custom_metadata(filename, metadata_json, file_last_modified)
  # end
  # config.process_custom_metadata = nil # default

  # This block is called in the `/file/new` action. It's used for checking the request and preparing your application
  # before uploading a file to AWS with presign URL. It expects boolean as a return value. If a result is false, it
  # immediately ends action processing, so you should set some response, like `head :forbidden`. Generating presigned
  # URL, saving instance of AwsFileHandler::File and building response JSON is done after this block, so you don't
  # need to save it, and you can change data before it builds a path for S3 which is generated with `save!`.
  # Bellow you can see some examples.
  #
  # Parameters:
  #   `controller` controller instance
  #   `params` params from request
  #   `aws_file` created instance of AwsFileHandler::File
  #
  # Examples:
  # config.controller_new_file = proc do |controller, params, aws_file|
  #   current_user = Folio::User.find(controller.session[:user_id])
  #
  #   # Check if the user can process uploading the file.
  #   if controller.can? :create, AwsFileHandler::File, user: current_user
  #     # This is association to your model. It's the opposite of the `aws_file` association in the
  #     # `AwsFileHandler::FileTypeable` concern.
  #     #
  #     # optional (can be assigned later)
  #     aws_file.typeable = Folio::File::Image.new
  #
  #     # If you defined `config.user_association`, you can store current_user here. It's the opposite of the `aws_file`
  #     # association in the `AwsFileHandler::Userable` concern.
  #     #
  #     # optional (it is user_association)
  #     aws_file.user = current_user
  #
  #     # This property generates part of the S3 path. The path has the format
  #     # `uploads/{YYYY}/{MM}/{DD}/{s3_type_directory}/{id}/file`, so you can define here, for example,
  #     # `Folio::File::Image.underscore`, which will create
  #     # `uploads/2025/07/21/folio/file/image/276c7637-4f34-436e-810b-4fed5f55b170/file`
  #     #
  #     # WARNING: It's mandatory to define `s3_type_directory` in this block because first save (validation) of
  #     # `AwsFileHandler::File` instance will store default in the database. This default will be used for `s3_path`
  #     # which will be used for presigned URL generation. So you won't be able to change it later!!
  #     #
  #     # optional (default: "file")
  #     aws_file.s3_type_directory = aws_file.typeable.underscore
  #     aws_file.s3_type_directory = Folio::File::Image.underscore
  #     aws_file.s3_type_directory = "image"
  #
  #     # JSON attribute for your custom data.
  #     #
  #     # optional (any data as hash)
  #     aws_file.custom_data = { type: "image", class: Folio::File::Image }
  #
  #     next true
  #   end
  #
  #   # Or you can raise exception, and it'll be handled by AwsFileHandler::ApplicationController but with some
  #   # default HTTP code
  #   controller.head :forbidden
  #
  #   false
  # end
  # config.controller_new_file = true # default
  config.controller_new_file = proc do |controller, params, aws_file|
    if controller.current_user.can_now?(:create, AwsFileHandler::File)
      aws_file.user = controller.current_user

      file_klass = params.require(:type).safe_constantize

      unless file_klass && Rails.application.config.folio_direct_s3_upload_class_names.any? { |class_name| file_klass <= class_name.constantize }
        controller.head :forbidden
        next false
      end

      aws_file.s3_type_directory = file_klass.name.underscore
      aws_file.custom_data = { class: file_klass }

      next true
    end

    # Or you can raise exception, and it'll be handled by AwsFileHandler::FileController but with some
    # default HTTP code
    controller.head :forbidden

    false
  end

  # This block is called in the `/file/sent` action. It's used for checking the request before processing it as
  # uploaded. It expects boolean as a return value. If a result is false, it immediately ends action processing, so
  # you should set some response, like `head :forbidden`.
  #
  # NOTE: If you didn't set typeable object `aws_file.typeable` in the new action, you should do it here!
  #
  # Parameters:
  #   `controller` controller instance
  #   `params` params from request
  #   `aws_file` created instance of AwsFileHandler::File
  #
  # Examples:
  # config.controller_sent_file = proc do |controller, params, aws_file|
  #   current_user = Folio::User.find(controller.session[:user_id])
  #
  #   # Check if the user can process uploading the file.
  #   if controller.can? :create, AwsFileHandler::File, user: current_user
  #     # This is an association to your model. It's the opposite of the `aws_file` association in the
  #     # `AwsFileHandler::FileTypeable` concern. Do it here and in `controller_uploaded_file` if you didn't set it in the
  #     # `/file/new` action already!
  #     aws_file.typeable = aws_file.custom_data[:class].constantize.new
  #
  #     next true
  #   end
  #
  #   # Or you can raise an exception, and it'll be handled by AwsFileHandler::ApplicationController but with some
  #   # default HTTP code
  #   controller.head :forbidden
  #
  #   false
  # end
  # config.controller_sent_file = true # default
  config.controller_sent_file = proc do |controller, params, aws_file|
    if controller.current_user.can_now?(:create, AwsFileHandler::File)
      # Logic should be same except request verification
      AwsFileHandler.configuration.controller_uploaded_file(controller, params, aws_file)

      next true
    end

    head :forbidden

    false
  end

  # This block is called in the `/file/uploaded` action. It's for setting up the file before processing it as uploaded.
  # It's the same as `/file/sent` but it's called from AWS, so the request shouldn't be checked, and it should always
  # pass otherwise, lambda will try it again.
  #
  # NOTE: If you didn't set typeable object `aws_file.typeable` in the new action, you should do it here!
  #
  # Parameters:
  #   `controller` controller instance
  #   `params` params from request
  #   `aws_file` created instance of AwsFileHandler::File
  #
  # Examples:
  # config.controller_uploaded_file = proc do |controller, params, aws_file|
  #   # This is an association to your model. It's the opposite of the `aws_file` association in the
  #   # `AwsFileHandler::FileTypeable` concern. Do it here and in `controller_sent_file` if you didn't set it in the
  #   # `/file/new` action already!
  #   aws_file.typeable = aws_file.custom_data[:class].constantize.new
  # end
  # config.controller_sent_file = nil # default
  config.controller_uploaded_file = proc do |controller, params, aws_file|
    # TODO: fill data required for typeable instance
    aws_file.typeable = aws_file.custom_data[:class].constantize.new
  end

  # This block is called in the `/file/uploaded` action. It's for setting up the file before processing it as uploaded.
  # It's the same as `/file/sent` but it's called from AWS, so the request shouldn't be checked, and it should always
  # pass otherwise, lambda will try it again.
  #
  # NOTE: If you didn't set typeable object `aws_file.typeable` in the new action, you should do it here!
  #
  # Parameters:
  #   `controller` controller instance
  #   `params` params from request
  #   `aws_file` created instance of AwsFileHandler::File
  #
  # Examples:
  # config.controller_uploaded_file = proc do |controller, params, aws_file|
  #   # This is an association to your model. It's the opposite of the `aws_file` association in the
  #   # `AwsFileHandler::FileTypeable` concern. Do it here and in `controller_sent_file` if you didn't set it in the
  #   # `/file/new` action already!
  #   aws_file.typeable = aws_file.custom_data[:class].constantize.new
  # end
  # config.controller_sent_file = nil # default

  # This block is called when uncaught exception is raised in any of the gem's controller action.
  #
  # Parameters:
  #   `controller` controller instance
  #   `exception` exception raised in any action
  #
  # Examples:
  # config.controller_rescue_from = proc { |controller, exception| controller.head :internal_server_error } # default
  # config.controller_rescue_from = nil
  config.controller_rescue_from = proc do |controller, exception|
    status = :internal_server_error

    if ENV["FOLIO_API_DONT_RESCUE_ERRORS"] && (Rails.env.development? || Rails.env.test?)
      raise exception
    end

    Sentry.capture_exception(exception) if defined?(Sentry)

    errors = [
      {
        status: Rack::Utils::SYMBOL_TO_STATUS_CODE[status] || status,
        title: exception.class.name,
        detail: exception.message,
      }
    ]

    controller.render json: { errors: errors }, status: status
  end
end
