# frozen_string_literal: true

Rails.configuration.action_dispatch.rescue_responses['CanCan::AccessDenied'] = :unauthorized
