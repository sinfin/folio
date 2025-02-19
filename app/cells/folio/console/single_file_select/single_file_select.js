// converted via https://coffeescript.org/#try
$(document).on('click', '.folio-console-single-file-select__button--add, .folio-console-single-file-select__button--change', function() {
  var $this, $wrap;
  $this = $(this);
  $wrap = $this.closest('.folio-console-single-file-select');
  return $wrap.find('input[type="file"]').click();
});

$(document).on('click', '.folio-console-single-file-select__button--remove', function() {
  var $this, $wrap;
  $this = $(this);
  if (!window.confirm(window.FolioConsole.translations.removePrompt)) {
    return $this.blur();
  }
  $wrap = $this.closest('.folio-console-single-file-select');
  $wrap.find('.folio-console-single-file-select__destroy').val(1);
  $wrap.find('.folio-console-single-file-select__clearable').html('');
  return $wrap.removeClass('folio-console-single-file-select--has-file');
});

$(document).on('change', '.folio-console-single-file-select-file', function() {
  var $this, $wrap, isImage, isVideo, reader;
  if (!(this.files && this.files[0])) {
    return;
  }
  $this = $(this);
  $wrap = $this.closest('.folio-console-single-file-select');
  $wrap.find('.folio-console-single-file-select__destroy').val(null);
  $wrap.addClass('folio-console-single-file-select--has-file');
  $wrap.find('.folio-console-single-file-select__clearable').html('');
  isImage = $wrap.find('.f-c-file-list__img-wrap').length;
  isVideo = $wrap.find('.folio-console-single-file-select__video').length;
  if (isImage || isVideo) {
    if (isImage) {
      $wrap.find('.f-c-file-list__img-wrap').html('<img src="https://doader.s3.amazonaws.com/250x250.gif?" alt="" />');
    }
    reader = new FileReader();
    reader.onload = function(e) {
      var $imageWrap, $video;
      if (isVideo) {
        $video = $wrap.find('.folio-console-single-file-select__video');
        return $video.html(`<video width="auto" height="auto" controls>
  <source src=${e.target.result} type="video/mp4">
</video>`);
      } else if (isImage) {
        $imageWrap = $wrap.find('.f-c-file-list__img-wrap');
        return $imageWrap.html(`<img src=\"${e.target.result}\" alt=\"\" class=\"f-c-file-list__img\" />`);
      }
    };
    return reader.readAsDataURL(this.files[0]);
  } else {
    return $wrap.find('.f-c-file-table__td--main').text(this.files[0].name);
  }
});
