# TODO jQuery -> stimulus

if Cookies? and $.fn.modal?
  if Cookies.get('image_sensitive_content')
    document.documentElement.classList.add('f-html--show-sensitive-content')
  else
    $(document).on 'click.fImageSensitiveContent', '.f-sensitive-content-modal__accept', (e) ->
      e.preventDefault()
      e.stopPropagation()
      Cookies.set('image_sensitive_content', '1')
      document.documentElement.classList.add('f-html--show-sensitive-content')
      $(this).closest('.modal').modal('hide')

else
  console.error("Include js-cookie and bootstrap modal to allow image sensitive_content functionality.")
