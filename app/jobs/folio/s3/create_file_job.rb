# frozen_string_literal: true

class Folio::S3::CreateFileJob < Folio::S3::BaseJob
  def perform_for_valid(s3_path:, klass:, existing_id:, web_session_id:, user_id:, attributes:)
    broadcast_start(s3_path:, file_type: klass.to_s)

    @user_id = user_id  # Store user_id for metadata extraction
    @file = prepare_file_model(klass, id: existing_id, web_session_id:, user_id:, attributes:)
    replacing_file = @file.persisted?

    # For video files on S3: use server-side copy instead of download+reupload
    if klass <= Folio::File::Video && !use_local_file_system?
      perform_with_s3_copy(s3_path:, klass:, replacing_file:)
      return
    end

    Dir.mktmpdir("folio-file-s3") do |tmpdir|
      @file.file = downloaded_file(s3_path, tmpdir)

      # Extract metadata synchronously before save for image files (to ensure headline is available for slug generation)
      if @file.is_a?(Folio::File::Image) && !replacing_file
        begin
          @file.extract_metadata!(save: false)
        rescue => e
          Rails.logger.warn "Metadata extraction failed during upload: #{e.message}"
          # Don't fail the upload if metadata extraction fails
        end
      end

      if save_file_with_slug_retry
        # Trigger async metadata extraction for image files if not already extracted synchronously
        if @file.is_a?(Folio::File::Image)
          trigger_metadata_extraction(@file, replacing_file: replacing_file)
        end

        if replacing_file
          broadcast_replace_success(file: @file, s3_path:, file_type: klass.to_s)
        else
          broadcast_success(file: @file, s3_path:, file_type: klass.to_s)
        end
      else
        if replacing_file
          broadcast_replace_error(file: @file, s3_path:, file_type: klass.to_s)
        else
          broadcast_error(file: @file, s3_path:, file_type: klass.to_s)
        end
      end
    end
  ensure
    test_aware_s3_delete(s3_path:)
  end

  private
    def perform_with_s3_copy(s3_path:, klass:, replacing_file:)
      file_name = s3_path.split("/").pop
      sanitized_name = file_name.split(".").map(&:parameterize).join(".")

      # Generate Dragonfly-compatible UID and S3 destination key
      uid = generate_dragonfly_uid(sanitized_name)
      dest_key = [dragonfly_s3_root_path, uid].compact_blank.join("/")
      source_key = test_aware_s3_path(s3_path)

      # Server-side S3 copy (instant, no data transfer through pod)
      s3_copy_object(source_key: source_key, dest_key: dest_key)

      # Get file metadata from S3 HEAD (no download)
      head = s3_head_object(key: source_key)

      # Set file attributes directly — bypass Dragonfly download+upload
      @file.file_uid = uid
      @file.file_name = sanitized_name
      @file.file_size = head.content_length
      @file.file_mime_type = head.content_type.presence || Marcel::MimeType.for(name: sanitized_name)

      if save_file_with_slug_retry
        if replacing_file
          broadcast_replace_success(file: @file, s3_path:, file_type: klass.to_s)
        else
          broadcast_success(file: @file, s3_path:, file_type: klass.to_s)
        end
      else
        # Rollback: delete the copied file
        test_aware_s3_delete(s3_path: uid)
        if replacing_file
          broadcast_replace_error(file: @file, s3_path:, file_type: klass.to_s)
        else
          broadcast_error(file: @file, s3_path:, file_type: klass.to_s)
        end
      end
    ensure
      test_aware_s3_delete(s3_path:)
    end

    def downloaded_file(s3_path, tmpdir)
      tmp_file_path = "#{tmpdir}/#{s3_path.split("/").pop}"

      test_aware_download_from_s3(s3_path:, local_path: tmp_file_path)

      tmp_file_path = ensure_proper_file_extension_for_mime_type(tmp_file_path)

      File.open(tmp_file_path)
    end

    def ensure_proper_file_extension_for_mime_type(tmp_file_path)
      file_mime_type = shell("file", "--brief", "--mime-type", tmp_file_path)

      ext = case file_mime_type
            when "image/jpeg"
              ".jpg"
            when "image/png"
              ".png"
            when "image/gif"
              ".gif"
            when "image/svg", "image/svg+xml"
              ".svg"
            else
              nil
      end

      if ext && !tmp_file_path.ends_with?(ext)
        new_file_path = "#{tmp_file_path.gsub(/\.\w+\z/, '')}#{ext}"
        FileUtils.cp(tmp_file_path, new_file_path)
        new_file_path
      else
        tmp_file_path
      end
    end

    def prepare_file_model(klass, id:, web_session_id:, user_id:, attributes: {})
      if id
        @file = klass.find(id)
      else
        @file = klass.new
      end

      @file.web_session_id = web_session_id if @file.respond_to?("web_session_id=")
      @file.user = Folio::User.find(user_id) if user_id && @file.respond_to?("user=")

      if user_id && @file.respond_to?("created_by_folio_user_id=")
        @file.created_by_folio_user_id = Folio::User.find(user_id).id
      end

      if attributes.present?
        if attributes[:site_id].present? && @file.respond_to?("site_id=")
          @file.assign_attributes(attributes)
        else
          attributes.delete(:site_id)
          @file.assign_attributes(attributes)
        end
      end

      @file
    end

    def save_file_with_slug_retry
      return true if save_with_db_uniqueness_guard

      if slug_conflict?(@file)
        Rails.logger.warn("[Folio] Slug validation conflict on #{file_ident_for_log}. Regenerating slug.")
        @file.slug = nil
        return true if save_with_db_uniqueness_guard
      end

      false
    end

    def save_with_db_uniqueness_guard
      @file.save
    rescue ActiveRecord::RecordNotUnique => e
      Rails.logger.warn("[Folio] DB unique violation on slug for #{file_ident_for_log}: #{e.message}. Regenerating slug.")
      @file.slug = nil
      begin
        @file.save
      rescue ActiveRecord::RecordNotUnique
        false
      end
    end

    def slug_conflict?(record)
      errs = record.errors[:slug]
      return false if errs.blank?

      errs.any? do |e|
        type = e.respond_to?(:type) ? e.type : nil
        type.nil? || type == :taken || type == :slug_not_unique_across_classes
      end
    end

    def file_ident_for_log
      id = @file.respond_to?(:id) ? @file.id : nil
      "#{@file.class.name}##{id || 'new'}"
    end

    def trigger_metadata_extraction(image, replacing_file: false)
      # For replaced files, force extraction since it's new file content
      force_extraction = replacing_file

      # Skip if metadata was already extracted synchronously before save
      return if image.file_metadata_extracted_at.present? && !replacing_file

      # Only trigger if extraction should happen (or force for replaced files)
      unless force_extraction || image.should_extract_metadata?
        return
      end

      # Use extraction service directly to ensure MessageBus broadcasting with user_id from S3 job
      Folio::Metadata::ExtractionService.perform_later(image, force: force_extraction, user_id: @user_id)
    rescue => e
      Rails.logger.error "Failed to trigger metadata extraction for image ##{image.id}: #{e.message}"
      # Don't fail the upload if metadata extraction fails
    end
end
