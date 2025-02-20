// converted via https://coffeescript.org/#try
// once you update it, remove it from package.json standard js ignored files
// TODO jQuery -> stimulus
if ((typeof window.Cookies !== 'undefined' && window.Cookies !== null) && (window.jQuery.fn.modal !== null)) {
  if (window.Cookies.get('image_sensitive_content')) {
    document.documentElement.classList.add('f-html--show-sensitive-content')
  } else {
    window.jQuery(document).on('click.fImageSensitiveContent', '.f-sensitive-content-modal__accept', function (e) {
      e.preventDefault()
      e.stopPropagation()
      window.Cookies.set('image_sensitive_content', '1')
      document.documentElement.classList.add('f-html--show-sensitive-content')
      return window.jQuery(this).closest('.modal').modal('hide')
    })
  }
} else {
  console.error('Include js-cookie and bootstrap modal to allow image sensitive_content functionality.')
}
