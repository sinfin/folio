// inspired by Modernizr

window.Folio = window.Folio || {}
window.Folio.Webp = {}

window.Folio.Webp.supported = null

window.Folio.Webp.uri = 'data:image/webp;base64,UklGRiQAAABXRUJQVlA4IBgAAAAwAQCdASoBAAEAAwA0JaQAA3AA/vuUAAA='
window.Folio.Webp.image = new Image()

window.Folio.Webp.image.onerror = () => {
  window.Folio.Webp.supported = false
  window.Folio.Webp.image = null
  window.Folio.Webp.src = null
}

window.Folio.Webp.image.onload = (e) => {
  if (e.type === 'load') {
    window.Folio.Webp.supported = window.Folio.Webp.image.width === 1
    window.Folio.Webp.image = null
    window.Folio.Webp.src = null
  }
}

window.Folio.Webp.image.src = window.Folio.Webp.uri
