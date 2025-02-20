// converted via https://coffeescript.org/#try
// once you update it, remove it from package.json standard js ignored files

(function () {
  window.jQuery(function () {
    let $uploads, initDropzone, token
    $uploads = window.jQuery('.f-c-private-attachments-single-dropzone__upload')
    if ($uploads.length === 0) {
      return
    }
    window.jQuery(document).on('click', '.f-c-private-attachments-single-dropzone__destroy', function (e) {
      let $el, $wrap
      e.preventDefault()
      $el = window.jQuery(this)
      if (window.confirm($el.data('destroy-confirm'))) {
        $wrap = $el.closest('.f-c-private-attachments-single-dropzone')
        $wrap.addClass('f-c-private-attachments-single-dropzone--loading')
        return window.jQuery.ajax({
          method: 'DELETE',
          url: $el.data('url'),
          success: function (res) {
            let $dz, $res, $upload
            $dz = $wrap.find('.f-c-private-attachments-single-dropzone__upload')
            if ($dz[0]) {
              Dropzone.forElement($dz[0]).destroy()
            }
            $res = window.jQuery(res)
            $wrap.replaceWith($res)
            $upload = $res.find('.f-c-private-attachments-single-dropzone__upload')
            if ($upload.length) {
              return initDropzone($upload)
            }
          },
          error: function (jxHr) {
            let json
            json = JSON.parse(jxHr.responseText)
            if (json.errors) {
              alert(json.errors[0].detail)
            }
            return $wrap.removeClass('f-c-private-attachments-single-dropzone--loading')
          }
        })
      }
    })
    token = document.querySelector('meta[name="csrf-token"]').getAttribute('content')
    initDropzone = function ($el) {
      return $el.dropzone({
        url: $el.data('url'),
        paramName: $el.data('paramname'),
        params: $el.data('params'),
        createImageThumbnails: false,
        maxFiles: 1,
        timeout: 0,
        maxFilesize: 100,
        headers: {
          'X-CSRF-Token': token
        },
        addedfile: function () {
          return $el.closest('.f-c-private-attachments-single-dropzone').addClass('f-c-private-attachments-single-dropzone--loading')
        },
        success: function (_file, res) {
          let $res, $upload
          if (res.errors) {
            $el.closest('.f-c-private-attachments-single-dropzone').removeClass('f-c-private-attachments-single-dropzone--loading')
            return alert(res.errors[0].detail)
          } else {
            Dropzone.forElement($el[0]).destroy()
            $res = window.jQuery(res)
            $el.closest('.f-c-private-attachments-single-dropzone').replaceWith($res)
            $upload = $res.find('.f-c-private-attachments-single-dropzone__upload')
            if ($upload.length) {
              return initDropzone($upload)
            }
          }
        },
        error: function (file, res) {
          $el.closest('.f-c-private-attachments-single-dropzone').removeClass('f-c-private-attachments-single-dropzone--loading')
          if (res.errors) {
            return alert(res.errors[0].detail)
          }
        }
      })
    }
    return $uploads.each(function () {
      return initDropzone(window.jQuery(this))
    })
  })
})()
