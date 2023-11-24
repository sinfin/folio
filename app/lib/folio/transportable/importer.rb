# frozen_string_literal: true

class Folio::Transportable::Importer
  attr_accessor :record

  def initialize(yaml_string, site_domain, record = nil)
    @hash = YAML.load(yaml_string).deep_symbolize_keys
    @klass = @hash[:class_name].safe_constantize
    @record = record
    @current_site = Folio::Site.find_by(domain: site_domain)

    unless @klass && @klass < ActiveRecord::Base && @klass.try(:transportable?)
      raise ActionController::ParameterMissing, "Non-transportable record"
    end

    if @record.present?
      unless @record.transportable?
        raise ActionController::ParameterMissing, "Non-transportable record"
      end
    else
      if @hash[:attributes][:type]
        @record = @hash[:attributes][:type].constantize.new
      else
        @record = @klass.new
      end
    end
  end

  def import!
    @record.transaction do
      attachments_data = build_attachments(@hash)
      @record.assign_attributes(@hash[:attributes].without(:id))
      @record.assign_attributes(attachments_data) if attachments_data.present?
      @record.site = find_site if @record.respond_to?(:site=)
      update_atoms
      @record.save
    end
  end

  private
    def update_atoms
      if @record.respond_to?(:atoms)
        if @hash[:atoms].is_a?(Hash)
          @hash[:atoms].each do |key, atoms|
            update_atoms_key(key, atoms)
          end
        else
          update_atoms_key(:atoms, @hash[:atoms])
        end
      end
    end

    def update_atoms_key(key, atoms_hash)
      collection = @record.send(key)
      collection.each(&:mark_for_destruction)

      if atoms_hash.present?
        atoms_hash.each do |atom_data|
          attachments = build_attachments(atom_data)
          collection.build(atom_data.without(:attachments).merge(attachments))
        end
      end
    end

    def build_attachments(data)
      h = {}

      if data[:attachments].present?
        data[:attachments].each do |reflection_key, reflection_data|
          next unless reflection_data
          attributes_key = "#{reflection_key}_attributes".to_sym

          if reflection_data.is_a?(Array)
            h[attributes_key] = reflection_data.map do |file_placement_data|
              {
                file_id: file_for_attachment(file_placement_data[:file]).id,
                alt: file_placement_data[:alt],
                title: file_placement_data[:title],
                position: file_placement_data[:position],
              }
            end
          else
            h[attributes_key] = {
              file_id: file_for_attachment(reflection_data[:file]).id,
              alt: reflection_data[:alt],
              title: reflection_data[:title],
              position: reflection_data[:position],
            }
          end
        end
      end

      h
    end

    def file_for_attachment(file_data)
      file = Folio::File.where(type: file_data[:type]).find_by(id: file_data[:id])

      return file if file && file.file_uid == file_data[:file_uid]

      file = Folio::File.where(type: file_data[:type]).find_by(file_uid: file_data[:file_uid])

      return file if file

      file = Folio::File.where(type: file_data[:type]).find_by("additional_data ->> 'file_uid' = ?", file_data[:file_uid])

      return file if file

      Folio::File.create!(type: file_data[:type],
                          author: file_data[:author],
                          description: file_data[:description],
                          file_url: file_data[:file_url],
                          additional_data: { file_uid: file_data[:file_uid] })
    end

    def find_site
      if @hash[:attributes][:site_id].present?
        Folio::Site.find(@hash[:attributes][:site_id])
      elsif @hash[:attributes][:site_domain].present?
        Folio::Site.find_by(domain: @hash[:attributes][:site_domain])
      elsif @record.site.present?
        @record.site
      else
        @record.site = @current_site
      end
    end
end
