atomFormBySelect = ($element) ->
  klass = $element.val()
  form = $element.find(':selected').data('form')
  images = $element.find(':selected').data('images')
  $fields = $element.closest('.nested-fields')

  # $modelSelects = $fields
  #   .find(".atom-model-select:not(.disabled[data-class='#{klass}'])")
  # $modelSelects.addClass('disabled').prop('disabled', true)
  # $modelSelects.parent().addClass('disabled')
  # $modelSelects.parent().hide()

  # $modelSelects = $fields
  #   .find(".atom-model-select.disabled[data-class='#{klass}']")
  # $modelSelects.removeClass('disabled').prop('disabled', false)
  # $modelSelects.parent().removeClass('disabled')
  # $modelSelects.parent().show()

  $content = $fields.find('.folio-console-atom-content')
  $textarea = $content.find('.folio-console-atom-textarea')

  switch form
    when 'redactor'
      $content.removeAttr('hidden')
      # check if redactor is active
      unless $textarea.hasClass('redactor')
        window.folioConsoleInitRedactor($textarea[0])

    when 'string'
      $content.removeAttr('hidden')
      if $textarea.hasClass('redactor')
        window.folioConsoleDestroyRedactor($textarea[0])

    else
      $content.attr('hidden', true)
      if $textarea.hasClass('redactor')
        window.folioConsoleDestroyRedactor($textarea[0])

  # if $modelSelects.length > 0
  #   $modelSelects.trigger('change')

$(document).on 'cocoon:after-insert', '#atoms', (e, insertedItem) ->
  atomFormBySelect($(insertedItem).find('.folio-console-atom-type-select'))

$(document).on 'change', '.folio-console-atom-type-select', ->
  atomFormBySelect($(this))

$ ->
  $('.folio-console-atom-type-select').each -> atomFormBySelect($(this))

# $(document).on 'change', '.atom-model-select', ->
#   $t = $(this)
#   $textarea = $t.closest('.nested-fields')
#                 .find('.node_atoms_content textarea')
#   content = $t.find(':selected').data('content')
#   if content
#     window.folioConsoleRedactorSetContent($textarea[0], content)

