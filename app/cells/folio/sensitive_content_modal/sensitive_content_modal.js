// converted via https://coffeescript.org/#try
// TODO jQuery -> stimulus
if ((typeof Cookies !== "undefined" && Cookies !== null) && ($.fn.modal != null)) {
  if (Cookies.get('image_sensitive_content')) {
    document.documentElement.classList.add('f-html--show-sensitive-content');
  } else {
    $(document).on('click.fImageSensitiveContent', '.f-sensitive-content-modal__accept', function(e) {
      e.preventDefault();
      e.stopPropagation();
      Cookies.set('image_sensitive_content', '1');
      document.documentElement.classList.add('f-html--show-sensitive-content');
      return $(this).closest('.modal').modal('hide');
    });
  }
} else {
  console.error("Include js-cookie and bootstrap modal to allow image sensitive_content functionality.");
}
