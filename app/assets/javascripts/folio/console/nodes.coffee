$ ->
  $(document).on 'change', '.atom-type-select', ->
    $content = $(this).closest('.nested-fields').find('.atom-content')
    switch this.value
      when 'Folio::Atom::Text'
        $content.redactor()
      when 'Folio::Atom::Embedded'
        $content.redactor('core.destroy')

  $('#paginate-images a').on 'ajax:success', (e, data, status, json) ->
    # pagination
    $t = $(this)
    $li = $t.parent()
    $li.parent().find('li.active').removeClass('active')
    $li.addClass('active')

    $t.closest('.modal-body').find('.row > .col-image')
      .each (index) ->
        $template = $(this)
        image = data[index]
        if image
          $template.find('a.thumbnail.select-file')
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
    $li.parent().find('li.active').removeClass('active')
    $li.addClass('active')

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
        $input.attr('id', $input.attr('id').replace(/{{i}}/, "#{index_counter}"))
        $input.attr('name', $input.attr('name').replace(/{{i}}/, "#{index_counter}"))
        $input.val($file.data('file-id')) if $input.attr('type') == 'hidden'
      $copy.find("[name='file_name']").html($file.data('file-filename'))
      $copy.find("[name='file_size']").html($file.data('file-filesize'))
      $copy.find("[name='size']").html($file.data('file-size'))
      $copy.appendTo($target)
      index_counter++

  $(document).on 'hidden.bs.modal', '.modal', (event) ->
    $(this).closest('.modal').find('.select-file.active').removeClass('active')

  $(document).on 'click', '.remove-file-placement', ->
    $(this).closest('.nested-field').remove()
    index_counter--

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

        $('#image-dropzone-template').parent().children('.col-image:last-child').remove()
        $('#image-dropzone-template').after($template)
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
