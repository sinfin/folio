# inspired by Modernizr

uri = 'data:image/webp;base64,UklGRiQAAABXRUJQVlA4IBgAAAAwAQCdASoBAAEAAwA0JaQAA3AA/vuUAAA='
image = new Image()

window.FolioWebpSupported = null

image.onerror = ->
  window.FolioWebpSupported = false

image.onload = (e) ->
  if e.type is 'load'
    window.FolioWebpSupported = image.width is 1

image.src = uri
