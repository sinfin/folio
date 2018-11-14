window.folioConsoleAtom ?= {}

window.folioConsoleAtom.atomModelContentPrefill = ($modelSelect) ->
  content = $modelSelect.find(':selected').data('content')

  if content
    $textarea = $modelSelect.closest('.nested-fields').find('.folio-console-atom-textarea')

    if $textarea.hasClass('redactor-source')
      window.folioConsoleRedactorSetContent($textarea[0], content)
    else
      $textarea.val(content)
