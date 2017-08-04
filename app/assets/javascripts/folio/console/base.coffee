#= require jquery
#= require jquery_ujs
#= require bootstrap-sprockets

$ ->

  $(document).on 'change', '#filter-form', ->
    $(this).submit()
