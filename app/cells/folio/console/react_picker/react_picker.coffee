$(document)
  .on 'click', '.folio-console-thumbnail__description', (e) ->
    e.preventDefault()
    e.stopPropagation()

    $this = $(this)
    $input = $this.prev('input')
    description = window.prompt($(['data-description-prompt']).data('data-description-prompt'), $input.val())

    if description isnt null
      $input.val(description)
      $this.find('.folio-console-thumbnail__description-val').text(description)

  .on 'click', '.folio-console-thumbnail__title-edit', (e) ->
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

  .on 'click', '.folio-console-react-picker .f-c-file-list__file, .folio-console-react-picker .f-c-file-table', (e) ->
    e.preventDefault()
    $(this)
      .closest('.folio-console-react-picker')
      .find('.folio-console-react-picker__button .btn')
      .click()

  .on 'click', '.folio-console-react-picker .f-c-file-list__file-btn--destroy', (e) ->
    e.stopPropagation()

  .on 'single-nested-change', '.folio-console-react-picker[data-atom-setting] .folio-console-react-picker__files', (e) ->
    window.postMessage({ type: 'refreshPreview' })
