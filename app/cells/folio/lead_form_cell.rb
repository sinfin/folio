module Folio
  class LeadFormCell < FolioCell
    include SimpleForm::ActionViewExtensions::FormHelper
    include Folio::Engine.routes.url_helpers

    def lead
      model || Folio::Lead.new
    end

    def submitted
      !lead.new_record?
    end

    def note
      return options[:note] if options[:note]
      model.note if model
    end

    def message
      return options[:message] if options[:message]
      t('.message')
    end
  end
end
