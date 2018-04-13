atomFormBySelect = ($element) ->
  klass = $element.val()
  structure = $element.find(':selected').data('atom-structure')
  $fields = $element.closest('.nested-fields')
  $wrap = $fields.find('.folio-console-smart-col').first()
  hideWrap = true

  $content = $fields.find('.folio-console-atom-content')
  $textarea = $content.find('.folio-console-atom-textarea')

  switch structure.content
    when 'redactor'
      hideWrap = false
      $content.removeAttr('hidden')
      # check if redactor is active
      unless $textarea.hasClass('redactor')
        # disable content images on atoms with images/cover
        window.folioConsoleInitRedactor $textarea[0], noImages: structure.images

    when 'string'
      hideWrap = false
      $content.removeAttr('hidden')
      if $textarea.hasClass('redactor')
        window.folioConsoleDestroyRedactor($textarea[0])

    else
      $content.attr('hidden', true)
      if $textarea.hasClass('redactor')
        window.folioConsoleDestroyRedactor($textarea[0])

  $title = $fields.find('.folio-console-atom-title')

  switch structure.title
    when 'string'
      hideWrap = false
      $title.removeAttr('hidden')
      $title.find('.form-control').prop('disabled', false)
    else
      $title.attr('hidden', true)
      $title.find('.form-control').prop('disabled', true)

  $model = $fields.find('.folio-console-atom-model')

  if structure.model
    hideWrap = false
    $model.removeAttr('hidden')
    $selects = $model.find('.folio-console-atom-model-select')
    $activeSelects = $selects.filter("""[data-class="#{klass}"]""")
    $activeSelects
      .prop('disabled', false)
      .closest('.form-group')
      .removeAttr('hidden')
    $selects
      .not($activeSelects)
      .attr('disabled', true)
      .closest('.form-group')
      .attr('hidden', true)
  else
    $model.attr('hidden', true)

  $images = $fields.find('.folio-console-atom-images')

  switch structure.images
    when 'single'
      $images.filter('.folio-console-atom-images-single').removeAttr('hidden')
      $images.not('.folio-console-atom-images-single').attr('hidden', true)
    when 'multi'
      $images.filter('.folio-console-atom-images-multi').removeAttr('hidden')
      $images.not('.folio-console-atom-images-multi').attr('hidden', true)
    else
      $images.attr('hidden', true)

  $documents = $fields.find('.folio-console-atom-documents')

  switch structure.documents
    when 'single'
      $documents.filter('.folio-console-atom-documents-single').removeAttr('hidden')
      $documents.not('.folio-console-atom-documents-single').attr('hidden', true)
    when 'multi'
      $documents.filter('.folio-console-atom-documents-multi').removeAttr('hidden')
      $documents.not('.folio-console-atom-documents-multi').attr('hidden', true)
    else
      $documents.attr('hidden', true)

  if hideWrap
    $wrap.attr('hidden', true)
  else
    $wrap.removeAttr('hidden')

  # if $modelSelects.length > 0
  #   $modelSelects.trigger('change')

$(document).on 'cocoon:after-insert', '#atoms', (e, insertedItem) ->
  atomFormBySelect($(insertedItem).find('.folio-console-atom-type-select'))

$(document).on 'change', '.folio-console-atom-type-select', ->
  atomFormBySelect($(this))

$('.folio-console-atom-type-select').each -> atomFormBySelect($(this))

# $(document).on 'change', '.atom-model-select', ->
#   $t = $(this)
#   $textarea = $t.closest('.nested-fields')
#                 .find('.node_atoms_content textarea')
#   content = $t.find(':selected').data('content')
#   if content
#     window.folioConsoleRedactorSetContent($textarea[0], content)

