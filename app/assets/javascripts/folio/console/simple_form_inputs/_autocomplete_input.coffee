AUTOCOMPLETE_SELECTOR = '.folio-console-autocomplete-input'

$.widget 'ui.autocomplete', $.ui.autocomplete,
  _renderMenu: ($ul, items) ->
    $ul.attr('class', 'dropdown-menu ui-menu folio-console-autocomplete-input-menu')
    $.each items, (index, item) =>
      @_renderItemData($ul, item)

  _renderItem: ($ul, item) ->
    $("<li class=\"ui-menu-item\"><span class=\"dropdown-item ui-menu-item-wrapper\">#{item.label}</span></li>").appendTo($ul)

  _resizeMenu: ->
    $ul = @menu.element
    width = Math.min($ul.width("").outerWidth() + 1, @element.outerWidth())
    $ul.outerWidth(width)

bindAutocomplete = ($elements) ->
  $elements.each ->
    $this = $(this)
    $this.autocomplete
      source: $this.data('autocomplete')

unbindAutocomplete = ($elements) ->
  $elements.autocomplete('destroy')

$(document)
  .on 'ready', ->
    bindAutocomplete($(AUTOCOMPLETE_SELECTOR))

  .on 'cocoon:after-insert', (e, insertedItem) ->
    bindAutocomplete(insertedItem.find(AUTOCOMPLETE_SELECTOR))

  .on 'cocoon:before-remove', (e, item) ->
    unbindAutocomplete(item.find(AUTOCOMPLETE_SELECTOR))
