# frozen_string_literal: true

class Folio::Console::TransportsController < Folio::Console::BaseController
  before_action :get_record_and_yaml, only: %i[out download]

  def out
  end

  def download
    now = Time.zone.now.strftime("%Y-%m-%d-%H-%M-%S")
    filename = "transport-#{@klass.model_name.param_key}-#{@record.to_param}-#{now}.yml"
    send_data @yaml, type: "text/vnd.yaml", disposition: "attachment; filename=#{filename}"
  end

  private
    def get_record_and_yaml
      @klass = params.require(:class_name).safe_constantize

      unless @klass && @klass < ActiveRecord::Base && @klass.try(:transportable?)
        raise ActionController::ParameterMissing, "Non-transportable record"
      end

      @record = @klass.find(params.require(:id))

      unless @record.try(:transportable?)
        raise ActionController::ParameterMissing, "Non-transportable record"
      end

      @yaml = Folio::Transportable::Transporter.new(@record).to_yaml
    end
end
