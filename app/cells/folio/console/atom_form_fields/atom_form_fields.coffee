stripHtml = (html) ->
  $("<div/>").html(html).text()

atomFormBySelect = ($element) ->
  klass = $element.val()
  structure = $element.find(':selected').data('atom-structure')
  $fields = $element.closest('.nested-fields')
  $wrap = $fields.find('.folio-console-smart-col').first()
  hideWrap = true
  klassFilter = """[data-class="#{klass}"]"""

  $content = $fields.find('.folio-console-atom-content')
  $textarea = $content.find('.folio-console-atom-textarea')

  switch structure.content
    when 'redactor'
      hideWrap = false
      $content.removeAttr('hidden')
      $textarea.prop('disabled', false)
      # check if redactor is active
      unless $textarea.hasClass('redactor-source')
        # disable content images on atoms with images/cover
        window.folioConsoleInitRedactor $textarea[0], noImages: structure.images

    when 'string'
      hideWrap = false
      $content.removeAttr('hidden')
      if $textarea.hasClass('redactor-source')
        html = window.folioConsoleRedactorGetContent($textarea[0])
        window.folioConsoleDestroyRedactor($textarea[0])
        $textarea.val(stripHtml(html))
      $textarea.prop('disabled', false)

    else
      $content.attr('hidden', true)
      if $textarea.hasClass('redactor-source')
        window.folioConsoleDestroyRedactor($textarea[0])
      $textarea.prop('disabled', true)

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

  $fields.find('.folio-console-atom-hint')
         .attr('hidden', true)
         .filter(klassFilter)
         .removeAttr('hidden')

  if structure.model
    hideWrap = false
    $model.removeAttr('hidden')
    $selects = $model.find('.folio-console-atom-model-select')
    $activeSelects = $selects.filter(klassFilter)

    $selects
      .not($activeSelects)
      .attr('disabled', true)
      .closest('.form-group')
      .attr('hidden', true)

    $activeSelects
      .prop('disabled', false)
      .closest('.form-group')
      .removeAttr('hidden')
      .each -> atomModelContentPrefill($(this))
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

atomModelContentPrefill = ($modelSelect) ->
  content = $modelSelect.find(':selected').data('content')

  if content
    $textarea = $modelSelect.closest('.nested-fields').find('.folio-console-atom-textarea')

    if $textarea.hasClass('redactor-source')
      window.folioConsoleRedactorSetContent($textarea[0], content)
    else
      # empty = $textarea.val().replace(/\s/g, '').length is 0
      # $textarea.val(content) if empty
      $textarea.val(content)

$(document).on 'cocoon:after-insert', '#atoms', (e, insertedItem) ->
  atomFormBySelect($(insertedItem).find('.folio-console-atom-type-select'))

$(document).on 'change', '.folio-console-atom-type-select', ->
  atomFormBySelect($(this))

$(document).on 'change', '.folio-console-atom-model-select', ->
  atomModelContentPrefill($(this))

$(document).on 'focus', '.folio-console-atom-form-fields .form-control', ->
  $wrap = $(this).closest('.folio-console-atom-form-fields')
  $wrap.addClass('folio-console-atom-form-fields--focused')

$(document).on 'blur', '.folio-console-atom-form-fields .form-control', ->
  $wrap = $(this).closest('.folio-console-atom-form-fields')
  $wrap.removeClass('folio-console-atom-form-fields--focused')

$('.folio-console-atom-type-select').each -> atomFormBySelect($(this))
