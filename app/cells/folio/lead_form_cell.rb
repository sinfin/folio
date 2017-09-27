module Folio
  class LeadFormCell < FolioCell
    include SimpleForm::ActionViewExtensions::FormHelper

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
  end
end
