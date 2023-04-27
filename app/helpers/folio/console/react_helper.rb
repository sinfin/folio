# frozen_string_literal: true

module Folio::Console::ReactHelper
  def file_picker(f:, placement_key:, file_type:)
    raw cell("folio/console/file/picker",
             f:,
             placement_key:,
             file_type:)
  end

  def file_picker_for_audio_cover(f)
    file_picker(f:,
                placement_key: :audio_cover_placement,
                file_type: "Folio::File::Audio")
  end

  def file_picker_for_video_cover(f)
    file_picker(f:,
                placement_key: :video_cover_placement,
                file_type: "Folio::File::Video")
  end

  def react_images(selected_placements = nil,
                   attachmentable: "page",
                   type: :image_placements,
                   atom_setting: nil)
    react_files("Folio::File::Image",
                selected_placements,
                attachmentable:,
                type:,
                atom_setting:)
  end

  def react_documents(selected_placements = nil,
                      attachmentable: "page",
                      type: :document_placements,
                      atom_setting: nil)
    react_files("Folio::File::Document",
                selected_placements,
                attachmentable:,
                type:,
                atom_setting:)
  end

  def react_audio_cover_picker(f, placement_key: :audio_cover_placement, file_type: "Folio::File::Audio", title: nil, atom_setting: nil)
    react_picker(f,
                 placement_key,
                 file_type:,
                 title:,
                 atom_setting:)
  end

  def react_picker(f, placement_key, file_type: "Folio::File::Image", title: nil, atom_setting: nil)
    raw cell("folio/console/react_picker", f, placement_key:,
                                              title:,
                                              file_type:,
                                              atom_setting:)
  end

  def react_ancestry(klass, max_nesting_depth: 2)
    raw cell("folio/console/react_ancestry",
             klass,
             max_nesting_depth:)
  end

  def react_modal_for(file_type, opts: {})
    if ["new", "edit", "create", "update"].include?(action_name) || controller.try(:force_use_react_modals?)
      klass = file_type.constantize

      url = if opts && opts[:url_name]
        main_app.send(opts[:url_name])
      else
        begin
          url_for([:console, :api, klass])
        rescue StandardError
          if file_type.start_with?("Folio::")
            folio.url_for([:console, :api, klass])
          else
            main_app.url_for([:console, :api, klass])
          end
        end
      end

      content_tag(:div,
                  nil,
                  "class" => "folio-react-wrap",
                  "data-file-type" => file_type,
                  "data-files-url" => url,
                  "data-react-type" => klass.human_type,
                  "data-taggable" => klass.react_taggable ? "1" : nil,
                  "data-mode" => "modal-single-select")
    end
  end

  def console_form_atoms(f)
    if f.object.class.respond_to?(:atom_locales)
      atoms = {}
      destroyed_ids = {}
      f.object.class.atom_locales.each do |locale|
        key = "#{locale}_atoms"
        atoms[key] = []
        destroyed_ids[key] = []

        f.object.send(key).to_a.each do |atom|
          if atom.marked_for_destruction?
            destroyed_ids[key] << atom.id
          else
            atoms[key] << atom.to_h
          end
        end
      end
    else
      atoms = { atoms: [] }
      destroyed_ids = { atoms: [] }

      f.object.atoms.to_a.each do |atom|
        if atom.marked_for_destruction?
          destroyed_ids[:atoms] << atom.id
        else
          atoms[:atoms] << atom.to_h
        end
      end
    end

    if f.lookup_model_names.size == 1
      namespace = f.lookup_model_names[0]
    else
      nested = f.lookup_model_names[1..-1].map { |n| "[#{n}]" }
      namespace = "#{f.lookup_model_names[0]}#{nested.join('')}"
    end

    data = {
      atoms:,
      destroyedIds: destroyed_ids,
      namespace:,
      structures: Folio::Atom.structures_for(klass: f.object.class),
      placementType: f.object.class.to_s,
      className: f.object.class.to_s,
    }

    content_tag(:div, nil, "class" => "f-c-atoms folio-react-wrap",
                           "data-mode" => "atoms",
                           "data-atoms" => data.to_json)
  end

  def react_files(file_type, selected_placements, attachmentable:, type:, atom_setting: nil)
    if selected_placements.present?
      placements = selected_placements.ordered.map do |fp|
        {
          id: fp.id,
          file_id: fp.file.id,
          alt: fp.alt,
          title: fp.title,
          file: Folio::Console::FileSerializer.new(fp.file)
                                              .serializable_hash[:data]
        }
      end.to_json
    else
      placements = nil
    end

    class_name = "folio-react-wrap"

    if atom_setting
      class_name = "#{class_name} f-c-js-atoms-placement-setting"
    end

    klass = file_type.constantize

    begin
      url = url_for([:console, :api, klass])
    rescue StandardError
      url = main_app.url_for([:console, :api, klass])
    end

    content_tag(:div, nil,
      "class" => class_name,
      "data-original-placements" => placements,
      "data-file-type" => file_type,
      "data-files-url" => url,
      "data-react-type" => klass.human_type,
      "data-mode" => "multi-select",
      "data-attachmentable" => attachmentable,
      "data-placement-type" => type,
      "data-atom-setting" => atom_setting,
      "data-can-destroy-files" => can?(:destroy, Folio::File) ? "1" : nil,
    )
  end

  def react_ordered_multiselect(f, relation_name, atom_setting: nil, scope: nil, order_scope: :ordered, sortable: true)
    class_name = "folio-react-wrap folio-react-wrap--ordered-multiselect"

    unless sortable
      class_name = "#{class_name} folio-react-wrap--ordered-multiselect-not-sortable"
    end

    klass = f.object.class
    reflection = klass.reflections[relation_name.to_s]
    through = reflection.options[:through]

    if through.nil?
      fail StandardError, "Only supported for :through relations"
    end

    through_klass = reflection.class_name.constantize

    param_base = "#{klass.model_name.param_key}[#{through}_attributes]"
    items = f.object.send(through).map do |record|
      through_record = through_klass.find(record.send(reflection.foreign_key))

      {
        id: record.id,
        label: through_record.to_console_label,
        value: through_record.id,
        _destroy: false,
      }
    end

    url = Folio::Engine.routes
                       .url_helpers
                       .url_for([:selectize,
                                 :console,
                                 :api,
                                 :autocomplete,
                                 klass: through_klass.to_s,
                                 scope:,
                                 order_scope:,
                                 only_path: true])

    content_tag(:div, class: "form-group") do
      concat(f.label relation_name)
      concat(
        content_tag(:div, content_tag(:span, nil, class: "folio-loader"),
          "class" => class_name,
          "data-param-base" => param_base,
          "data-foreign-key" => reflection.foreign_key,
          "data-items" => items.to_json,
          "data-url" => url,
          "data-sortable" => sortable ? "1" : "0",
          "data-atom-setting" => atom_setting,
        )
      )
    end
  end

  REACT_NOTE_PARENT_CLASS_NAME = "f-c-r-notes-fields-app-parent"
  REACT_NOTE_TOOLTIP_PARENT_CLASS_NAME = "f-c-r-notes-fields-app-tooltip-parent"
  REACT_NOTE_FORM_PARENT_CLASS_NAME = "f-c-r-notes-fields-app-form-parent"

  def react_notes_fields(f)
    react_notes_common(f:)
  end

  def react_notes_form(target)
    react_notes_common(target:)
  end

  def react_atom_setting_id(f)
    if f.object.id.present?
      content_tag(:div,
                  "",
                  hidden: true,
                  class: "f-c-js-atoms-placement-setting",
                  data: {
                    "atom-setting" => "placement",
                    "atom-setting-value-json" => { id: f.object.id, class_name: f.object.class.to_s }.to_json,
                  })
    end
  end

  private
    def react_notes_common(f: nil, target: nil)
      class_name = "folio-react-wrap folio-react-wrap--notes-fields"

      target_with_fallback = target || f.object
      data = target_with_fallback.console_notes.map { |note| Folio::Console::ConsoleNoteSerializer.new(note).serializable_hash[:data] }

      param_base = "#{target_with_fallback.class.base_class.model_name.param_key}[console_notes_attributes]"

      hash = {
        "class" => class_name,
        "data-notes" => data.to_json,
        "data-account-id" => current_account.id,
        "data-param-base" => param_base,
        "data-label" => Folio::ConsoleNote.model_name.human(count: 2),
      }

      if target
        hash["data-target-type"] = target.class.base_class.to_s
        hash["data-target-id"] = target.id
        hash["data-url"] = url_for([:react_update_target, :console, :api, Folio::ConsoleNote])
        hash["data-class-name-parent"] = REACT_NOTE_PARENT_CLASS_NAME
        hash["data-class-name-tooltip-parent"] = REACT_NOTE_TOOLTIP_PARENT_CLASS_NAME
      elsif f
        hash["data-errors-html"] = f.error(:console_notes).to_s.presence
      end

      content_tag(:div, content_tag(:span, nil, class: "folio-loader"), hash)
    end
end
