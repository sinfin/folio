# frozen_string_literal: true

module Folio::Console::ReactHelper
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

  def react_ancestry(klass, max_nesting_depth: 2)
    raw cell("folio/console/react_ancestry",
             klass,
             max_nesting_depth:)
  end

  def console_form_atoms(f, audited_audit_active: false)
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

        atoms[key].sort_by! { |a| a[:position] || 0 }
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

      atoms[:atoms].sort_by! { |a| a[:position] || 0 }
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
      structures: Folio::Atom.structures_for(klass: f.object.class, site: Folio::Current.site),
      placementType: f.object.class.to_s,
      className: f.object.class.to_s,
      auditedAuditActive: audited_audit_active,
    }

    content_tag(:div, nil, "class" => "f-c-atoms folio-react-wrap",
                "data-mode" => "atoms",
                "data-atoms" => data.to_json)
  end

  def react_files(file_type, selected_placements, attachmentable:, type:, atom_setting: nil)
    placements = if selected_placements.present?
      ordered = if selected_placements.is_a?(ActiveRecord::Relation)
        selected_placements.ordered
      else
        selected_placements
      end

      selected_index = 0

      ordered.map do |fp|
        {
          id: fp.id,
          selectedAt: fp.id.nil? ? (selected_index += 1) : nil,
          file_id: fp.file.id,
          alt: fp.alt,
          title: fp.title,
          file: Folio::Console::FileSerializer.new(fp.file)
                                              .serializable_hash[:data],
        }.compact
      end.to_json
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
                "data-can-destroy-files" => can_now?(:destroy, Folio::File) ? "1" : nil)
  end

  def react_ordered_multiselect(f,
                                relation_name,
                                atom_setting: nil,
                                scope: nil,
                                default_scope: nil,
                                order_scope: :ordered,
                                sortable: true,
                                max_items: nil,
                                required: nil,
                                label: nil,
                                menu_placement: :bottom,
                                collection: nil,
                                group_method: nil,
                                group_label_method: nil,
                                label_method: :to_console_label,
                                value_method: :id,
                                selected_through_records: nil,
                                virtual: nil)
    unless max_items.nil? || (max_items.is_a?(Integer) && max_items.positive?)
      raise ArgumentError, "max_items must be a positive integer or nil"
    end

    class_name = "folio-react-wrap folio-react-wrap--ordered-multiselect"

    unless sortable
      class_name += " folio-react-wrap--ordered-multiselect-not-sortable"
    end

    items = []
    removed_items = []
    options = nil
    data_serialization = nil
    data_input_name = nil
    param_base = nil
    foreign_key = nil

    if virtual
      class_names = virtual.fetch(:class_name)
      data_serialization = virtual.fetch(:serialization, :array).to_s
      data_input_name = virtual.fetch(:input_name)

      if data_serialization == "scalar"
        if max_items && max_items != 1
          raise ArgumentError, "scalar serialization only supports max_items: 1"
        end

        max_items = 1
      end

      items = Array(virtual.fetch(:selected)).map do |record|
        item_label = react_ordered_multiselect_value(record, label_method)
        value = react_ordered_multiselect_value(record, value_method)

        {
          id: nil,
          label: item_label.to_s,
          value:,
          _destroy: false,
        }
      end

      options = react_ordered_multiselect_options(collection,
                                                  group_method:,
                                                  group_label_method:,
                                                  label_method:,
                                                  value_method:,
                                                  through_klass: nil) if collection
    else
      klass = f.object.class
      reflection = klass.reflections[relation_name.to_s]
      through = reflection.options[:through]

      if through.nil?
        raise StandardError, "Only supported for :through relations"
      end

      through_klass = reflection.class_name.constantize
      param_base = "#{f.object_name}[#{through}_attributes]"
      foreign_key = reflection.foreign_key
      class_names = through_klass.to_s

      (selected_through_records || f.object.send(through)).each do |record|
        through_record = through_klass.find(record.send(reflection.foreign_key))
        hash = {
          id: record.id,
          label: through_record.to_console_label,
          value: through_record.id,
          _destroy: record.marked_for_destruction?,
        }

        if hash[:_destroy]
          if hash[:id]
            removed_items << hash
          end
        else
          items << hash
        end
      end

      options = react_ordered_multiselect_options(collection,
                                                  group_method:,
                                                  group_label_method:,
                                                  label_method:,
                                                  value_method:,
                                                  through_klass:) if collection
    end

    url = unless options
      react_ordered_multiselect_url(class_names:,
                                    scope:,
                                    default_scope:,
                                    order_scope:,
                                    label_method:)
    end

    input_options = {}
    input_options[:required] = required unless required.nil?
    input_options[:label] = label unless label.nil? || label == true
    input_options[:full_error_html] = { class: "d-block" }

    react_wrap = content_tag(
      :div,
      content_tag(:span, nil, class: "folio-loader"),
      "class" => "#{class_name} form-control",
      "data-name" => "#{f.object_name}[#{relation_name}]",
      "data-param-base" => param_base,
      "data-foreign-key" => foreign_key,
      "data-removed-items" => removed_items.to_json,
      "data-items" => items.to_json,
      "data-url" => url,
      "data-options" => options&.to_json,
      "data-sortable" => sortable ? "1" : "0",
      "data-max-items" => max_items,
      "data-menu-placement" => menu_placement,
      "data-atom-setting" => atom_setting,
      "data-serialization" => data_serialization,
      "data-input-name" => data_input_name
    )

    f.input(relation_name, input_options) do
      react_wrap
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
    return unless f.object.id.present?

    content_tag(:div,
                "",
                hidden: true,
                class: "f-c-js-atoms-placement-setting",
                data: {
                  "atom-setting" => "placement",
                  "atom-setting-value-json" => { id: f.object.id, class_name: f.object.class.to_s }.to_json,
                })
  end

  private
    def react_ordered_multiselect_options(collection,
                                          group_method:,
                                          group_label_method:,
                                          label_method:,
                                          value_method:,
                                          through_klass:)
      records = collection.respond_to?(:call) ? collection.call : collection

      if group_method
        records.to_a.filter_map do |group|
          group_options = react_ordered_multiselect_value(group, group_method).to_a.map do |record|
            react_ordered_multiselect_option(record,
                                             label_method:,
                                             value_method:,
                                             through_klass:)
          end

          next if group_options.blank?

          {
            label: react_ordered_multiselect_value(group, group_label_method || label_method).to_s,
            options: group_options,
          }
        end
      else
        records.to_a.map do |record|
          react_ordered_multiselect_option(record,
                                           label_method:,
                                           value_method:,
                                           through_klass:)
        end
      end
    end

    def react_ordered_multiselect_option(record,
                                         label_method:,
                                         value_method:,
                                         through_klass:)
      label = react_ordered_multiselect_value(record, label_method)
      value = react_ordered_multiselect_value(record, value_method)

      {
        id: value,
        label: label.to_s,
        text: label.to_s,
        value:,
        type: record.respond_to?(:to_model) ? record.class.to_s : through_klass.to_s,
      }
    end

    def react_ordered_multiselect_value(record, method)
      return method.call(record) if method.respond_to?(:call)

      if record.is_a?(Array)
        case method
        when :to_console_label, :label, :first
          record.first
        when :id, :value, :last
          record.last
        else
          record.public_send(method) if record.respond_to?(method)
        end
      elsif record.respond_to?(method)
        record.public_send(method)
      elsif record.respond_to?(:[])
        record[method]
      end
    end

    def react_ordered_multiselect_url(class_names:,
                                      scope:,
                                      default_scope:,
                                      order_scope:,
                                      label_method:)
      options = {
        class_names:,
        scope:,
        default_scope:,
        order_scope:,
        only_path: true,
      }

      if label_method.present? &&
         label_method != :to_console_label &&
         label_method != "to_console_label" &&
         !label_method.respond_to?(:call)
        options[:label_method] = label_method
      end

      Folio::Engine.routes.url_helpers.url_for([
                                                 :react_select,
                                                 :console,
                                                 :api,
                                                 :autocomplete,
                                                 options
                                               ])
    end

    def react_notes_common(f: nil, target: nil)
      class_name = "folio-react-wrap folio-react-wrap--notes-fields"

      target_with_fallback = target || f.object
      data = target_with_fallback.console_notes.map do |note|
        Folio::Console::ConsoleNoteSerializer.new(note).serializable_hash[:data]
      end

      param_base = "#{target_with_fallback.class.base_class.model_name.param_key}[console_notes_attributes]"

      hash = {
        "class" => class_name,
        "data-notes" => data.to_json,
        "data-account-id" => Folio::Current.user.id,
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
