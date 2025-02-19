// converted via https://coffeescript.org/#try

(function () {
$(function() {
  var $uploads, initDropzone, token;
  $uploads = $('.f-c-private-attachments-single-dropzone__upload');
  if ($uploads.length === 0) {
    return;
  }
  $(document).on('click', '.f-c-private-attachments-single-dropzone__destroy', function(e) {
    var $el, $wrap;
    e.preventDefault();
    $el = $(this);
    if (window.confirm($el.data('destroy-confirm'))) {
      $wrap = $el.closest('.f-c-private-attachments-single-dropzone');
      $wrap.addClass('f-c-private-attachments-single-dropzone--loading');
      return $.ajax({
        method: 'DELETE',
        url: $el.data('url'),
        success: function(res) {
          var $dz, $res, $upload;
          $dz = $wrap.find('.f-c-private-attachments-single-dropzone__upload');
          if ($dz[0]) {
            Dropzone.forElement($dz[0]).destroy();
          }
          $res = $(res);
          $wrap.replaceWith($res);
          $upload = $res.find('.f-c-private-attachments-single-dropzone__upload');
          if ($upload.length) {
            return initDropzone($upload);
          }
        },
        error: function(jxHr) {
          var json;
          json = JSON.parse(jxHr.responseText);
          if (json.errors) {
            alert(json.errors[0].detail);
          }
          return $wrap.removeClass('f-c-private-attachments-single-dropzone--loading');
        }
      });
    }
  });
  token = document.querySelector('meta[name="csrf-token"]').getAttribute('content');
  initDropzone = function($el) {
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
      addedfile: function() {
        return $el.closest('.f-c-private-attachments-single-dropzone').addClass('f-c-private-attachments-single-dropzone--loading');
      },
      success: function(_file, res) {
        var $res, $upload;
        if (res.errors) {
          $el.closest('.f-c-private-attachments-single-dropzone').removeClass('f-c-private-attachments-single-dropzone--loading');
          return alert(res.errors[0].detail);
        } else {
          Dropzone.forElement($el[0]).destroy();
          $res = $(res);
          $el.closest('.f-c-private-attachments-single-dropzone').replaceWith($res);
          $upload = $res.find('.f-c-private-attachments-single-dropzone__upload');
          if ($upload.length) {
            return initDropzone($upload);
          }
        }
      },
      error: function(file, res) {
        $el.closest('.f-c-private-attachments-single-dropzone').removeClass('f-c-private-attachments-single-dropzone--loading');
        if (res.errors) {
          return alert(res.errors[0].detail);
        }
      }
    });
  };
  return $uploads.each(function() {
    return initDropzone($(this));
  });
});
})()
