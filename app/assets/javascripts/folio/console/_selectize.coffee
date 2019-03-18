window.folioConsoleBindSelectize = ($selects) ->
  $selects
    .not('.folio-console-selectize--bound')
    .addClass('folio-console-selectize--bound')
    .each ->
      if @multiple
        $(this).selectize
          dropdownParent: 'body'
          maxOptions: 50000
      else
        $(this).selectize
          plugins: ['typing_mode']
          usePlaceholder: true
          dropdownParent: 'body'
          maxOptions: 50000

window.folioConsoleUnbindSelectize = ($selects) ->
  $selects
    .filter('.folio-console-selectize--bound')
    .removeClass('folio-console-selectize--bound')
    .each -> @selectize.destroy()
