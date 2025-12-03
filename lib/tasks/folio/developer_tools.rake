# frozen_string_literal: true

namespace :folio do
  namespace :developer_tools do
    desc "Fill up Folio::Current.main_site to records, where site is missing (and is required)"
    task idp_fill_up_site_to_folio_records: :environment do
      site = begin
        ::Folio::Current.main_site
      rescue Folio::Singleton::MissingError
        nil
      end

      if site.blank?
        puts("!!! No main site found, skipping")
      else
        [
          ::Folio::Page,
          ::Folio::File,
          ::Folio::Lead,
          ::Folio::EmailTemplate,
          ::Folio::NewsletterSubscription,
          ::Folio::Menu
        ].each do |klass|
          if klass.new.attributes.key?("site_id")
            klass.where(site_id: nil).update_all(site_id: site.id)
            klass.where(site_id: 0).update_all(site_id: site.id)
          end
        end
      end
    end

    desc "split users to separate site-link-binded records when switching from crossdomain to user-per-site"
    task idp_split_users_to_sites: :environment do
      batches = Folio::User.pluck(:id).to_a.in_groups_of(1000)
      batches.each do |batch|
        Folio::User.find(batch).each do |user|
          puts("Spliting user #{user.id}")
          user.make_clones_to_all_linked_sites!
          # user.destroy if !user.superadmin? && user.auth_site_id == Folio::Current.main_site.id
        end
      end
    end

    desc "Try to fix users to be valid (phone, email, etc.)"
    task idp_fix_users_to_be_valid: :environment do
      puts("Fixing users to be valid. Latest ID: #{Folio::User.maximum(:id)}")
      Folio::User.find_each do |user|
        msg = "Fixing user #{user.id} #{user.to_label}"
        puts(msg)
        Rails.logger.error(msg)
        next if user.valid?

        if user.errors[:phone]
          user.phone = user.phone.to_s.delete("-").delete(" ").strip
          user.phone = "+420#{user.phone}" if user.phone.size == 9
        end

        if user.valid?
          user.save!
        else
          msg = "Failed to fix user #{user.id} #{user.to_label} #{user.errors.full_messages.join(", ")}"
          Raven.capture_message(msg) if defined?(Raven)
          Sentry.capture_message(msg) if defined?(Sentry)
          Rails.logger.error(msg)
        end
      end
    end

    desc "update tiptap nodes from legacy key_id syntax to the key_placement_attributes one"
    task idp_correct_tiptap_node_attachments: :environment do
      class_name = ENV["CLASS_NAME"]
      fail "Please provide CLASS_NAME env variable, e.g. CLASS_NAME=Folio::Page" if class_name.blank?
      scope = class_name.constantize.where.not(tiptap_content: nil)
      count = scope.count

      if count.zero?
        puts "[folio:developer_tools:idp_correct_tiptap_node_attachments] Nothing to do, exiting."
        next
      end

      count_length = count.to_s.length
      dots_page_by = 100

      i = 0
      scope.find_each do |record|
        i += 1

        # find any folioTiptapNode nodes
        # change cover_id: num to cover_placement_attributes: { file_id: num }
        # change video_cover_id: num to video_cover_placement_attributes: { file_id: num }
        # no others should be needed
        content = record.tiptap_content[Folio::Tiptap::TIPTAP_CONTENT_JSON_STRUCTURE[:content]]
        changed = false

        loop_content_and_replace = ->(node) {
          if node && node["content"].present?
            node["content"].each do |child|
              loop_content_and_replace.call(child)
            end
          end

          if node["type"] == "folioTiptapNode"
            if node["attrs"] && node["attrs"]["data"]
              if file_id = node["attrs"]["data"].delete("cover_id")
                node["attrs"]["data"]["cover_placement_attributes"] = { "file_id" => file_id }
                changed = true
              end
              if file_id = node["attrs"]["data"].delete("video_cover_id")
                node["attrs"]["data"]["video_cover_placement_attributes"] = { "file_id" => file_id }
                changed = true
              end
            end
          end

          node
        }

        new_content = loop_content_and_replace.call(content)

        if changed
          record.update_column(:tiptap_content, { Folio::Tiptap::TIPTAP_CONTENT_JSON_STRUCTURE[:content] => new_content })
          # to trigger tiptap file placements creation
          record.save
          print(".")
        else
          print("s")
        end

        if i % dots_page_by == 0
          print " #{i.to_s.rjust(count_length)} / #{count} (#{(i.to_f / count * 100).round(2)}%)"
          puts ""
        end
      end

      puts "\n[folio:developer_tools:idp_correct_tiptap_node_attachments] Done."
    end

    desc "Calculate and cache published usage counts for all files"
    task calculate_file_published_usage_counts: :environment do
      puts "Calculating published usage counts for all Folio::File records..."

      total_count = Folio::File.count
      processed = 0
      batch_size = 500

      Folio::File.find_in_batches(batch_size: batch_size) do |files|
        files.each do |file|
          file.update_file_placements_counts!
        end

        processed += files.size
        percentage = (processed.to_f / total_count * 100).round(2)

        puts "Processed #{processed}/#{total_count} files (#{percentage}%)"
      end
    end

    desc "Set correct site for files and theirs tags accorfing to Rails.application.config.folio_shared_files_between_sites setting"
    task idp_set_correct_site_for_files_and_tags: :environment do
      Rails.logger.silence do
        puts "[folio:developer_tools:idp_set_correct_site_for_files_and_tags] Setting correct site for files."

        if Rails.application.config.folio_shared_files_between_sites
          correct_site = Folio::File.correct_site(nil)
          raise "correct_site is nil" if correct_site.blank?
          puts "correct_site for all files: #{correct_site.domain}"

          wrong_files_scope = Folio::File.where.not(site: correct_site)
          puts "Updating #{wrong_files_scope.count} files"
          Folio::File.where(id: wrong_files_scope).update_all(site_id: correct_site.id)
          puts "Files updated"

          file_types = ["Folio::File", "Folio::File::Audio", "Folio::File::Video", "Folio::File::Image", "Folio::File::Document"]
          puts("Updating taggigs for file types: #{file_types.join(", ")}")
          wrong_taggings_scope = ActsAsTaggableOn::Tagging.where(taggable_type: file_types).where.not(tenant: correct_site.id)
          puts "Updating #{wrong_taggings_scope.count} taggings"
          ActsAsTaggableOn::Tagging.where(id: wrong_taggings_scope).update_all(tenant: correct_site.id)
          puts "Taggings updated"
        else
          puts "no sharing files is set, do nothing"
        end
      end
    end
  end
end
