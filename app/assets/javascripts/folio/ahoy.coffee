#= require ahoy

$ ->
  ahoy.trackAll()
  $(document).on 'turbolinks:load', -> ahoy.trackView()
