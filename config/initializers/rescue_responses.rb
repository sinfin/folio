# frozen_string_literal: true

Rails.configuration.action_dispatch.rescue_responses["ActionController::ParameterMissing"] = :bad_request
Rails.configuration.action_dispatch.rescue_responses["CanCan::AccessDenied"] = :unauthorized
