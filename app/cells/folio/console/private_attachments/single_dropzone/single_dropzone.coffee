$ ->
  $uploads = $('.f-c-private-attachments-single-dropzone__upload')
  return if $uploads.length is 0

  $(document).on 'click', '.f-c-private-attachments-single-dropzone__destroy', (e) ->
    e.preventDefault()
    $el = $(this)

    if window.confirm($el.data('destroy-confirm'))
      $wrap = $el.closest('.f-c-private-attachments-single-dropzone')
      $wrap.addClass('f-c-private-attachments-single-dropzone--loading')

      $.ajax
        method: 'DELETE'
        url: $el.data('url')
        success: (res) ->
          $dz = $wrap.find('.f-c-private-attachments-single-dropzone__upload')
          Dropzone.forElement($dz[0]).destroy() if $dz[0]
          $res = $(res)
          $wrap.replaceWith($res)
          $upload = $res.find('.f-c-private-attachments-single-dropzone__upload')
          initDropzone($upload) if $upload.length
        error: (jxHr) ->
          json = JSON.parse(jxHr.responseText)
          alert(json.errors[0].detail) if json.errors
          $wrap.removeClass('f-c-private-attachments-single-dropzone--loading')

  token = document
    .querySelector('meta[name="csrf-token"]')
    .getAttribute('content')

  initDropzone = ($el) ->
    $el.dropzone
      url: $el.data('url')
      paramName: $el.data('paramname')
      params: $el.data('params')
      createImageThumbnails: false
      maxFiles: 1
      timeout: 0
      maxFilesize: 100
      headers:
        'X-CSRF-Token': token
      addedfile: ->
        $el
          .closest('.f-c-private-attachments-single-dropzone')
          .addClass('f-c-private-attachments-single-dropzone--loading')
      success: (_file, res) ->
        if res.errors
          $el
            .closest('.f-c-private-attachments-single-dropzone')
            .removeClass('f-c-private-attachments-single-dropzone--loading')
          alert(res.errors[0].detail)
        else
          Dropzone.forElement($el[0]).destroy()
          $res = $(res)
          $el.closest('.f-c-private-attachments-single-dropzone').replaceWith($res)
          $upload = $res.find('.f-c-private-attachments-single-dropzone__upload')
          initDropzone($upload) if $upload.length

      error: (file, res) ->
        $el
          .closest('.f-c-private-attachments-single-dropzone')
          .removeClass('f-c-private-attachments-single-dropzone--loading')
        alert(res.errors[0].detail) if res.errors

  $uploads.each ->
    initDropzone($(this))
