window.folioConsoleBindSelectize = ($selects) ->
  $selects
    .not('.folio-console-selectize--bound')
    .addClass('folio-console-selectize--bound')
    .each ->
      $this = $(this)
      if @multiple
        $this.selectize
          dropdownParent: 'body'
          maxOptions: 50000
          onChange: -> $this.trigger('selectizeChange')
      else
        $this.selectize
          plugins: ['typing_mode']
          usePlaceholder: true
          dropdownParent: 'body'
          maxOptions: 50000
          onChange: -> $this.trigger('selectizeChange')

window.folioConsoleUnbindSelectize = ($selects) ->
  $selects
    .filter('.folio-console-selectize--bound')
    .removeClass('folio-console-selectize--bound')
    .each -> @selectize.destroy()

$ ->
  $items = $('select').not('.folio-console-selectize--manual')
  window.folioConsoleBindSelectize($items)

  $(document)
    .on 'cocoon:after-insert', (e, insertedItem) ->
      $items = $(insertedItem).find('select')
                              .not('.folio-console-selectize--manual')

      window.folioConsoleBindSelectize($items)

    .on 'cocoon:before-remove', (e, item) ->
      window.folioConsoleUnbindSelectize($(item).find('select'))
