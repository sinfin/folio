module Folio
  class LeadFormCell < FolioCell
    include SimpleForm::ActionViewExtensions::FormHelper

    def lead
      model || Folio::Lead.new
    end

    def submitted
      !lead.new_record?
    end
  end
end
