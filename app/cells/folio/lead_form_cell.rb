# frozen_string_literal: true

module Folio
  class LeadFormCell < SavingFolioCell
    include SimpleForm::ActionViewExtensions::FormHelper
    include Engine.routes.url_helpers

    def lead
      @lead ||= (model || Lead.new)
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

    def remember_option_keys
      [:note, :message, :name]
    end
  end
end
