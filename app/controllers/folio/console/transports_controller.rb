# frozen_string_literal: true

class Folio::Console::TransportsController < Folio::Console::BaseController
  before_action :get_record

  def out
    @yaml = Folio::Transportable::Exporter.new(@record).to_yaml
  end

  def download
    @yaml = Folio::Transportable::Exporter.new(@record).to_yaml

    now = Time.zone.now.strftime("%Y-%m-%d-%H-%M-%S")
    filename = "transport-#{@klass.model_name.param_key}-#{@record.to_param}-#{now}.yml"
    send_data @yaml, type: "text/vnd.yaml", disposition: "attachment; filename=#{filename}"
  end

  def in
  end

  def transport
    @yaml_string = params.require(:yaml_string)

    @importer = Folio::Transportable::Importer.new(@yaml_string, current_site.domain, @record)

    if @importer.import!
      url = url_for([:edit, :console, @importer.record])
      redirect_to url, flash: { notice: t(".success") }
    else
      flash.now[:alert] = t(".failure")
      render :in
    end
  end

  private
    def get_record
      if params[:class_name].present? && params[:id].present?
        @class_name = params[:class_name]
        @id = params[:id]

        @klass = @class_name.safe_constantize
        @record = @klass.find(@id)

        unless @klass && @klass < ActiveRecord::Base && @klass.try(:transportable?)
          raise ActionController::ParameterMissing, "Non-transportable record"
        end

        unless @record.try(:transportable?)
          raise ActionController::ParameterMissing, "Non-transportable record"
        end
      end
    end
end
