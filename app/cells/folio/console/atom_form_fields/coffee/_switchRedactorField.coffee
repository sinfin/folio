window.folioConsoleAtom ?= {}

stripHtml = (html) ->
  $("<div/>").html(html).text()

window.folioConsoleAtom.switchRedactorField = ({ structure, $field, placeholder }) ->
  $textarea = $field.find('.folio-console-atom-textarea')

  switch structure
    when 'redactor'
      present = true
      $field.find('.form-control').attr('placeholder', placeholder)
      $field.removeAttr('hidden')
      $textarea.prop('disabled', false)
      # check if redactor is active
      unless $textarea.hasClass('redactor-source')
        $textarea.each ->
          window.folioConsoleInitRedactor this, basic: true

    when 'string'
      present = true
      $field.find('.form-control').attr('placeholder', placeholder)
      $field.removeAttr('hidden')
      if $textarea.hasClass('redactor-source')
        $textarea.each ->
          html = window.folioConsoleRedactorGetContent(this)
          window.folioConsoleDestroyRedactor(this)
          $(this).val(stripHtml(html))
      $textarea.prop('disabled', false)

    else
      present = false
      $field.attr('hidden', true)
      if $textarea.hasClass('redactor-source')
        window.folioConsoleDestroyRedactor($textarea[0])
      $textarea.prop('disabled', true)

  return present
