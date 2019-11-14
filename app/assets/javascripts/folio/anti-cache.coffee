read = (url) ->
  localStorage?.getItem?(url)

write = (url, html) ->
  localStorage?.setItem?(url, html)

swapItems = ($old, $new, immediate) ->
  $old.find('[data-anti-cache-item]').each ->
    $item = $(this)
    id = $item.data('anti-cache-item')
    replacement = $new.find("[data-anti-cache-item='#{id}']")
    $item.replaceWith(replacement)

  if immediate
    $old.addClass('folio-anti-cache--done')
  else
    setTimeout (-> $old.addClass('folio-anti-cache--done')), 0

fetchFresh = ($el, url) ->
  $.get url, (res) -> swapItems($el, $(res), false)

performAntiCache = (e) ->
  saveAntiCacheHtml()
  $body = $(e.originalEvent.data.newBody || 'body')
  window.performFolioAntiCache $body.find('[data-anti-cache]')

saveAntiCacheHtml = ->
  $('[data-anti-cache]').each ->
    $el = $(this)
    write $el.data('anti-cache'), $el.html()

window.performFolioAntiCache = ($items) ->
  $items.each ->
    $el = $(this)
    url = $el.data('anti-cache')
    value = read(url)

    swapItems($el, $(value), true) if value

    fetchFresh($el, url)

$(document)
  .one 'turbolinks:load', performAntiCache
  .on 'turbolinks:before-render', performAntiCache
