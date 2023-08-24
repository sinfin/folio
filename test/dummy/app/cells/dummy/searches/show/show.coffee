# TODO jQuery -> stimulus

resultsCache = []
ajax = null
aborted = false
timeout = null

getCachedResult = (q) ->
  result = null

  resultsCache.forEach (cached) ->
    if q is cached.q
      result = cached
      return false

  return result

setCachedResults = (q, $wrap) ->
  cachedResult = getCachedResult(q)

  if cachedResult and cachedResult.tabs? and cachedResult.results?
    $wrap
      .find('.d-searches-show__results-wrap')
      .html(cachedResult.results)

    $wrap
      .find('.d-searches-show__tabs')
      .html(cachedResult.tabs)

    true
  else
    false

load = ($input, $form, $wrap) ->
  value = $input.val()

  return if setCachedResults(value, $wrap)

  url = "#{$form.prop('action')}?q=#{value}"

  tabMatch = window.location.search.match(/tab=[^&]+/)
  if tabMatch and tabMatch[0]
    url += "&#{tabMatch[0]}"

  $.ajax
    url: url
    method: 'GET'
    success: (response, status, jxHr) ->
      $response = $(response)

      tabsHtml = $response.find('.d-searches-show__tabs').html()
      resultsHtml = $response.find('.d-searches-show__results-wrap').html()

      $wrap
        .find('.d-searches-show__tabs')
        .html(tabsHtml)

      $wrap
        .find('.d-searches-show__results-wrap')
        .html(resultsHtml)

      $wrap.removeClass('d-searches-show--loading')

      cacheEntry =
        q: value
        tabs: tabsHtml
        results: resultsHtml

      resultsCache = resultsCache.slice(0, 4)
      resultsCache.unshift(cacheEntry)

      Turbolinks.controller.replaceHistoryWithLocationAndRestorationIdentifier(url, Turbolinks.uuid())

    error: ->
      if aborted
        aborted = false
      else
        Turbolinks.visist("#{$form.prop('action')}?q=#{value}")

debouncedLoad = window.Folio.debounce(load, 300)

$(document)
  .on 'turbolinks:load', ->
    $('.d-searches-show__input').on 'keyup.dSearchesShow change.dSearchesShow', (e) ->
      perform = =>
        $input = $(this)
        $form = $input.closest('.d-searches-show__form')
        $wrap = $form.closest('.d-searches-show')

        return if setCachedResults(@value, $wrap)

        $wrap.addClass('d-searches-show--loading')

        debouncedLoad($input, $form, $wrap)

      if e.type is "change"
        timeout = setTimeout(perform, 100)
      else
        perform()

  .on 'turbolinks:request-start', ->
    if ajax
      aborted = true
      ajax.abort()
      ajax = null

    if timeout
      clearTimeout(timeout)
      timeeout = null

  .on 'turbolinks:before-render', ->
    $('.d-searches-show__input').off 'keyup.dSearchesShow change.dSearchesShow'
