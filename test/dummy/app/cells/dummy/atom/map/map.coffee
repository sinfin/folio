script = null
API_KEY = 'API_KEY_TODO'

window.dAtomMapInit = ->
  $('.d-atom-map__map').each ->
    [lat, lng] = $(this).data('latlng').split(',')
    latlng = new google.maps.LatLng(parseFloat(lat), parseFloat(lng))

    options =
      center: latlng
      zoom: 11

    map = new google.maps.Map(this, options)

    marker = new google.maps.Marker
      position: latlng
      map: map

$(document)
  .on 'turbolinks:load', ->
    $map = $('.d-atom-map__map')
    return unless $map.length

    if script
      window.dAtomMapInit()
    else
      script = document.createElement('script')
      script.src = "https://maps.googleapis.com/maps/api/js?key=#{ API_KEY }&callback=dAtomMapInit"
      script.async = true
      document.head.appendChild(script)

  .on 'turbolinks:before-cache', ->
    $map = $('.d-atom-map__map')
    return unless $map.length
    $map.html('')
