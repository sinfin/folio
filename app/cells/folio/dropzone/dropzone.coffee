#= require dropzone/dist/dropzone

initDropzones = ->
  token = document.querySelector('meta[name="csrf-token"]').content

  $('.f-dropzone__dropzone').each ->
    $wrap = $(this)

    options = $.extend {}, $wrap.data('dict'),
      url: $wrap.data('create-url')
      paramName: $wrap.data('param-name')
      addRemoveLinks: true
      createImageThumbnails: $wrap.data('create-thumbnails')
      thumbnailWidth: 250
      thumbnailHeight: 250
      maxFilesize: 100
      maxFiles: $wrap.data('max-files') || null
      timeout: 0
      acceptedFiles: $wrap.data('file-formats') || null
      removedfile: (file) ->
        if file.status isnt 'error'
          try
            id = file.id or JSON.parse(file.xhr.response).id
            url = $wrap.data('destroy-url').replace('ID', id)
            $.ajax
              method: 'DELETE'
              url: url
              success: ->
                $(file.previewElement).remove()
              error: ->
                window.alert($wrap.data('destroy-failure'))
          catch
            window.alert($wrap.data('destroy-failure'))

        $wrap.toggleClass('dz-started', $wrap.find('.dz-preview').length isnt 0)
      headers:
        'X-CSRF-Token': token

    $wrap
      .addClass('dropzone')
      .dropzone options

    @dropzone.on 'error', (file, message) ->
      alert(message)
      $(file.previewElement).remove()
      @removeFile(file)

    if $wrap.data('index-url')
      $.get $wrap.data('index-url'), (res) =>
        if res
          for attachment in res
            file = {
              id: attachment.id,
              name: attachment.file_name,
              size: attachment.file_size,
            }
            @dropzone.files.push file
            @dropzone.emit('addedfile', file)
            if attachment.thumb
              @dropzone.emit('thumbnail', file, attachment.thumb)
            @dropzone.emit('complete', file)

        $wrap.removeClass('f-dropzone__dropzone--loading')

    if $wrap.data('records')
      $wrap.data('records').forEach (attachment) =>
        file = {
          id: attachment.id,
          name: attachment.file_name,
          size: attachment.file_size,
        }
        @dropzone.files.push file
        @dropzone.emit('addedfile', file)
        if attachment.thumb
          @dropzone.emit('thumbnail', file, attachment.thumb)
        @dropzone.emit('complete', file)

destroyDropzones = ->
  $('.f-dropzone__dropzone').each -> @dropzone.destroy()

if Turbolinks?
  $(document)
    .on 'turbolinks:load', initDropzones
    .on 'turbolinks:before-render', destroyDropzones
else
  $ initDropzones
