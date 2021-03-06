$(document).on 'click', '[data-destroy-association]', (e) ->
  $this = $(this)

  unless window.confirm(window.FolioConsole.translations.removePrompt)
    return $this.blur()

  $fields = $this.closest('.nested-fields')

  $fields.find('input').filter(->
    this.name.indexOf('[_destroy]') isnt -1
  ).val(1)

  $fields.attr('hidden', true)
  $this.closest('[data-cocoon-single-nested]').trigger('single-nested-change')
