#= require jquery
#= require jquery_ujs
#= require bootstrap-sprockets
#= require dropzone
#= require cocoon
#= require redactor

#= require ./redactor-init
#= require ./redactor-imagemanager
#= require ./nodes
#= require ./files

$ ->
  # disable auto discover
  Dropzone.autoDiscover = false

  $(document).on 'change', '#filter-form', ->
    $(this).submit()

  $(document).on 'click', '.btn.position-up', ->
    $this_atom = $(this).closest('.nested-fields')
    $that_atom = $this_atom.prevAll(".nested-fields:first")

    pos = $this_atom.find('.position').val()
    $that_atom.find('.position').val(pos)
    $this_atom.find('.position').val(pos - 1)
    $this_atom.after($that_atom)

  $(document).on 'click', '.btn.position-down', ->
    $this_atom = $(this).closest('.nested-fields')
    $that_atom = $this_atom.nextAll(".nested-fields:first")

    pos = $that_atom.find('.position').val()
    $this_atom.find('.position').val(pos)
    $that_atom.find('.position').val(pos - 1)
    $that_atom.after($this_atom)

  $(document).on 'cocoon:after-insert', (e, insertedItem) ->
    pos = +$(insertedItem).prevAll(".nested-fields:first").find('.position').val()
    $(insertedItem).find('.position').val(pos + 1)
    $(insertedItem).find('.redactor').each ->
      $(this).redactor()
