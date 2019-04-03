read = (url) ->
  localStorage?.getItem?(url)

write = (url, html) ->
  localStorage?.setItem?(url, html)

swapItems = ($old, $new) ->
  $old.find('[data-anti-cache-item]').each ->
    $item = $(this)
    id = $item.data('anti-cache-item')
    replacement = $new.find("[data-anti-cache-item='#{id}']")
    $item.replaceWith(replacement)

  $old.addClass('folio-anti-cache--done')

fetchFresh = ($el, url) ->
  $.get url, (res) -> swapItems($el, $(res))

performAntiCache = (e) ->
  $body = $(e.originalEvent.data.newBody || 'body')

  $body.find('[data-anti-cache]').each ->
    $el = $(this)
    url = $el.data('anti-cache')
    value = read(url)

    swapItems($el, $(value)) if value

    fetchFresh($el, url)

saveAntiCacheHtml = ->
  $('[data-anti-cache]').each ->
    $el = $(this)
    write $el.data('anti-cache'), $el.html()

$(document)
  .one 'turbolinks:load', performAntiCache
  .on 'turbolinks:before-render', performAntiCache
  .on 'turbolinks:before-cache', saveAntiCacheHtml

