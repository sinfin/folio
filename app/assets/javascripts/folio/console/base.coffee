#= require jquery
#= require jquery_ujs
#= require bootstrap-sprockets
#= require dropzone
#= require cocoon
# = require redactor
#= require ./redactor-init

$ ->
  $(document).on 'change', '#filter-form', ->
    $(this).submit()
    
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
      
      $copy.removeClass('hidden file-placement-new').removeAttr('id')
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

  # disable auto discover
  Dropzone.autoDiscover = false
  # grap our upload form by its id
  $('#new_file').dropzone
    maxFilesize: 10 # MB
    paramName: 'file[file]'
  
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
          .data('file-size', "#{response.file_width} × #{response.file_height}px")
        if file.thumbnailUrl
          $template.find('img').attr('src', file.thumbnailUrl)
        $('#image-dropzone-template').after($template)
        return file
      error: (file, message) ->
        $('#dropzone-error').removeClass('hidden')
        $('#dropzone-error .alert').html("#{file.upload.filename}: #{message}")
        return file
  
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
        $template.removeClass('hidden').removeAttr('id')
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
