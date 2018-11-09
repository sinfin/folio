window.folioFreshCsrfToken =
  loading: false
  value: null
  tokenParam: $('meta[name="csrf-param"]').prop('content')

  withToken: (callback) ->
    return if @loading
    return callback(@value) if @value
    @getToken(callback)

  getToken: (callback) ->
    @loading = true
    $.get('/csrf').then (value) =>
      @value = value
      @loading = false
      $('meta[name="csrf-token"]').prop('content', value)
      callback(value) if callback

  preloadToken: ->
    return if @loading
    return if @value
    @getToken()

$ ->
  $(document).one 'focus touchstart', 'form', ->
    window.folioFreshCsrfToken.preloadToken()
