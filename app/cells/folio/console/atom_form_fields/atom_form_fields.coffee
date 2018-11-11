stripHtml = (html) ->
  $("<div/>").html(html).text()

atomFormBySelect = ($element) ->
  klass = $element.val()
  structure = $element.find(':selected').data('atom-structure')
  $fields = $element.closest('.nested-fields')
  $wrap = $fields.find('.folio-console-atom-main-fields').first()
  hideWrap = true
  klassFilter = """[data-class="#{klass}"]"""

  placeholders = $fields.data('placeholders')[klass]

  $content = $fields.find('.folio-console-atom-content')
  $textarea = $content.find('.folio-console-atom-textarea')

  switch structure.content
    when 'redactor'
      hideWrap = false
      $content.find('.form-control').attr('placeholder', placeholders.content)
      $content.removeAttr('hidden')
      $textarea.prop('disabled', false)
      # check if redactor is active
      unless $textarea.hasClass('redactor-source')
        # disable content images on atoms with images/cover
        $textarea.each ->
          window.folioConsoleInitRedactor this, basic: structure.images

    when 'string'
      hideWrap = false
      $content.find('.form-control').attr('placeholder', placeholders.content)
      $content.removeAttr('hidden')
      if $textarea.hasClass('redactor-source')
        $textarea.each ->
          html = window.folioConsoleRedactorGetContent(this)
          window.folioConsoleDestroyRedactor(this)
          $(this).val(stripHtml(html))
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
      $title.find('.form-control')
        .attr('placeholder', placeholders.title)
        .prop('disabled', false)
    else
      $title.attr('hidden', true)
      $title.find('.form-control').prop('disabled', true)

  $perex = $fields.find('.folio-console-atom-perex')

  switch structure.perex
    when 'string'
      hideWrap = false
      $perex.removeAttr('hidden')
      $perex.find('.form-control')
        .attr('placeholder', placeholders.perex)
        .prop('disabled', false)
    else
      $perex.attr('hidden', true)
      $perex.find('.form-control').prop('disabled', true)

  $model = $fields.find('.folio-console-atom-model')

  $fields
    .find('.folio-console-atom-hint')
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

  $fileFields = $fields.find('.folio-console-atom-fields')

  for key in ['cover', 'document', 'images', 'documents']
    $fileField = $fileFields.filter(".folio-console-atom-fields--#{key}")
    if structure[key]
      hideWrap = false
      $fileField.removeAttr('hidden')
    else
      $fileField.attr('hidden', true)

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
