# frozen_string_literal: true

MessageBus.user_id_lookup do |env|
  req = Rack::Request.new(env)

  if req.session && req.session["warden.user.user.key"] && req.session["warden.user.user.key"][0][0]
    user = Folio::User.find(req.session["warden.user.user.key"][0][0])
    user.id
  end
end
