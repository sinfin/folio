# frozen_string_literal: true

class Folio::Api::AresController < Folio::Api::BaseController
  def subject
    subj = Folio::Ares.get!(params.require(:identification_number))
    render json: { data: subj.to_h }
  rescue Folio::Ares::ConnectionError, Folio::Ares::ARESError, Folio::Ares::ParseError, Folio::Ares::InvalidIdentificationNumberError => e
    render_error(e, status: 422)
  end
end
