$(document).on 'click', '.folio-console-thumbnail__alt', (e) ->
  e.preventDefault()
  $this = $(this)
  $input = $this.prev('input')
  alt = window.prompt($(['data-alt-prompt']).data('data-alt-prompt'), $input.val())

  if alt isnt null
    $input.val(alt)
    $this.text("alt: #{alt}")

$(document).on 'click', '.folio-console-thumbnail__title-edit', (e) ->
  e.preventDefault()
  $wrap = $(this).closest('.folio-console-thumbnail__inner')
  $input = $wrap.find('input')
  fileName = $input.data('file-name')
  promptText = $(['data-file-title-prompt']).data('file-title-prompt')
  title = window.prompt(promptText, $input.val() or fileName)

  if title isnt null
    $input.val(title)

    title ||= fileName unless title

    if title.length > 30
      truncatedTitle = "#{title.substr(0, 27)}..."
    else
      truncatedTitle = title

    $wrap.find('.folio-console-thumbnail__title').text(truncatedTitle)

$(document).on 'click', '.folio-console-react-picker .f-c-file-list__file, .folio-console-react-picker .folio-console-file-table', (e) ->
  e.preventDefault()
  $(this)
    .closest('.folio-console-react-picker')
    .find('.folio-console-react-picker__button .btn')
    .click()
