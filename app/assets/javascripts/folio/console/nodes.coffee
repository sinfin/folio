$ ->
  setPagination = (li, page, total_pages) ->
    if page >= 6
      li.prevAll("li.disabled").show()
    else
      li.prevAll("li.disabled").hide()
    if page >= total_pages - 4
      li.nextAll("li.disabled").hide()
    else
      li.nextAll("li.disabled").show()

    li.nextAll("li:not(.disabled)")
      .add(li.prevAll(':not(.disabled)'))
      .hide()
    li.nextAll("li:not(.disabled)").slice(0, 4)
      .add(li.prevAll("li:not(.disabled)").slice(0, 4))
      .show()

  selectRightForm = (element) ->
    $t = $(element)
    form = $t.find(':selected').data('form')
    $content = $t.closest('.nested-fields').find('.atom-content')
    switch form
      when 'redactor'
        $content.show()
        $textarea = $content.find('textarea')
        # check if redactor is active
        if $textarea.is(':visible')
          $textarea.redactor()
      when 'string'
        $content.show()
        $textarea = $content.find('textarea')
        unless $textarea.is(':visible')
          $textarea.redactor('core.destroy')
      when 'none'
        $content.hide()


  $(document).on 'cocoon:after-insert', (e, insertedItem) ->
    selectRightForm($(insertedItem).find('select.atom-type-select'))

  $(document).on 'change', '.atom-type-select', ->
    selectRightForm(this)

  $('#paginate-images a').on 'ajax:success', (e, data, status, json) ->
    # pagination
    $t = $(this)
    $li = $t.parent()
    $ul = $li.parent()

    # pagination
    $ul.find('li.active').removeClass('active')
    $li.addClass('active')

    page = $li.data('page')
    total_pages = $ul.find('li:not(.disabled)').length
    setPagination($li, page, total_pages)

    # change images
    $t.closest('.modal-body').find('.row > .col-image')
      .each (index) ->
        $template = $(this)
        image = data[index]
        if image
          $template.find('a.card.select-file')
            .data('file-id', image.id)
            .data('file-filesize', image.file_size)
            .data('file-size', image.size)
            .removeClass('active')
          $template.find('img')
            .attr('src', image.thumb)
          $template.removeClass('hidden')
        else
          $template.addClass('hidden')


  $('#paginate-documents a').on 'ajax:success', (e, data, status, json) ->
    # pagination
    $t = $(this)
    $li = $t.parent()
    $ul = $li.parent()

    # pagination
    $ul.find('li.active').removeClass('active')
    $li.addClass('active')

    page = $li.data('page')
    total_pages = $ul.find('li:not(.disabled)').length
    setPagination($li, page, total_pages)

    $t.closest('.modal-body').find('tr.select-file:not(.template)')
      .each (index) ->
        $template = $(this)
        doc = data[index]
        if doc
          $template
            .data('file-id', doc.id)
            .data('file-filesize', doc.file_size)
          $template.find("[name='file_size']").html(doc.file_size)
          $template.find("[name='file_name']").html(doc.file_name)
          $template.removeClass('hidden active')
        else
          $template.addClass('hidden')

  $(document).on 'click', '.select-file', ->
    $image = $(this)
    if $image.hasClass('active')
      $image.removeClass('active')
    else
      $image.addClass('active')

  index_counter = undefined

  $(document).on 'click', '.save-modal', ->
    $modal = $(this).closest('.modal')
    $target = $($modal.data('target'))
    $modal.find('.select-file.active').each () ->
      $file = $(this)
      $copy = $target.find('.file-placement-new').clone()
      index_counter = index_counter || $target.data('fp-index')

      $copy.removeClass('file-placement-new').removeAttr('id hidden')
      $copy.find('img').attr('src', $file.find('img').attr('src'))
      $copy.find('input').each () ->
        $input = $(this)
        $input.prop('disabled', false)
        $input.attr('id', $input.attr('id')
          .replace(/{{i}}/, "#{index_counter}"))
        $input.attr('name', $input.attr('name')
          .replace(/{{i}}/, "#{index_counter}"))
        if $input.attr('type') == 'hidden'
          $input.val($file.data('file-id'))
      $copy.find("[name='file_name']").html($file.data('file-filename'))
      $copy.find("[name='file_size']").html($file.data('file-filesize'))
      $copy.find("[name='size']").html($file.data('file-size'))
      $copy.prependTo($target)
      index_counter++

      # FIXME
      $target.find('.remove-after').hide()

  $(document).on 'show.bs.modal', '#images-modal', (event) ->
    $button = $(event.relatedTarget)
    $(this).data('target', $button.closest('.row'))

  $(document).on 'hidden.bs.modal', '.modal', (event) ->
    $(this).closest('.modal').find('.select-file.active').removeClass('active')

  $(document).on 'click', '.remove', (event) ->
    event.preventDefault()
    $(this).closest('.nested-field').nextAll('.remove-after:first').show()
    $(this).closest('.nested-field').remove()
    index_counter--

  $(document).on 'click', '.btn.destroy', (event) ->
    event.preventDefault()
    $button = $(this)
    $button.find('input[type="hidden"]:first').val(1)
    $button.closest('.nested-fields').fadeOut(500)

  $(document).on 'click', '.btn.destroy-image', (e) ->
    e.preventDefault()
    $button = $(this)
    $button.find('input[type="hidden"]:first').val(1)
    $button.closest('.nested-fields').fadeOut(500)
    $parent = $button.closest('.nested-fields')
    $parent.fadeOut(500, ->
      $parent.nextAll('.remove-after:first').show(500)
    )

  # images modal dropzone
  template = document.querySelector('#image-dropzone-template')
  if template
    $('#new_image').dropzone
      maxFilesize: 10 # MB
      resizeMethod: 'crop'
      paramName: 'file[file]'
      # FIXME: enlarge smaller images?
      thumbnailWidth: 250
      thumbnailHeight: 250
      previewTemplate: template.innerHTML
      addedfile: (file) ->
        return
      thumbnail: (file, dataUrl) ->
        if file.status == 'success'
          $(file.previewElement).find('img').attr('src',dataUrl)
        else
          file.thumbnailUrl = dataUrl
        return file
      success: (file, response) ->
        file.previewElement = Dropzone.createElement(@options.previewTemplate)
        $template = $(file.previewElement)
        $template.find('a.thumbnail.select-file')
          .addClass('active')
          .data('file-id', response.id)
          .data('file-filesize', response.file_size)
          .data('file-size', response.size)
        if file.thumbnailUrl
          $template.find('img').attr('src', file.thumbnailUrl)

        $('#image-dropzone-template')
          .parent()
          .children('.col-image:last-child')
          .remove()
        $('#image-dropzone-template')
          .after($template)
        return file
      error: (file, message) ->
        $('#dropzone-error').removeClass('hidden')
        $('#dropzone-error .alert').html("#{file.upload.filename}: #{message}")
        return file

  # documents modal dropzone
  template = document.querySelector('#document-dropzone-template')
  if template
    $('#new_document').dropzone
      maxFilesize: 1024 # MB
      paramName: 'file[file]'
      createImageThumbnails: false
      previewTemplate: template.outerHTML
      addedfile: (file) ->
        return file
      success: (file, response) ->
        $template = $(@options.previewTemplate).clone()
        $template.removeClass('hidden template').removeAttr('id')
          .addClass('active')
          .data('file-id', response.id)
          .data('file-filesize', response.file_size)
          .data('file-filename', response.file_name)
        $template.find("[name='file_size']").html(response.file_size)
        $template.find("[name='file_name']").html(response.file_name)
        $('#document-dropzone-template').after($template)
        return file
      error: (file, message) ->
        $('#dropzone-error').removeClass('hidden')
        $('#dropzone-error .alert').html("#{file.upload.filename}: #{message}")
        return file
