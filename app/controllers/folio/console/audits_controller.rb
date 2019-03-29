# frozen_string_literal: true

class Folio::Console::AuditsController < Folio::Console::BaseController
  folio_console_controller_for 'Audited::Audit'
  before_action :find_audited
  before_action do
    add_breadcrumb(@audited.model_name.human(count: 2),
                   url_for([:console, @audited.class]))
    add_breadcrumb(@audited.title,
                   url_for([:console, @audited, action: :edit]))
    add_breadcrumb(I18n.t('folio.console.audits.title'),
                   url_for([:console, @audited, :audits]))
  end

  def index
    @audits = @audited.revisions.reverse
  end

  private

    def find_audited
      audited_class = params[:audited_class].safe_constantize
      audited_to_param = audited_class.to_s.demodulize.parameterize
      @audits_partial_name = "folio/console/#{audited_to_param.pluralize}/audits"

      @audited = audited_class.find(params[:"#{audited_to_param}_id"])
    end

    attr_reader :audits_partial_name
    helper_method :audits_partial_name
end
