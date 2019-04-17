AUTOCOMPLETE_SELECTOR = '.folio-console-string-input--autocomplete'

$.widget 'ui.autocomplete', $.ui.autocomplete,
  _renderMenu: ($ul, items) ->
    $ul.attr('class', 'dropdown-menu ui-menu folio-console-autocomplete-input-menu')
    $.each items, (index, item) =>
      @_renderItemData($ul, item)

  _renderItem: ($ul, item) ->
    $("""
      <li class="ui-menu-item" title="#{item.label}">
        <span class="dropdown-item ui-menu-item-wrapper folio-console-autocomplete-input-menu-item">#{item.label}</span>
      </li>
      """).appendTo($ul)

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

$document = $(document)

$document.on 'cocoon:after-insert', (e, insertedItem) ->
  bindAutocomplete(insertedItem.find(AUTOCOMPLETE_SELECTOR))

$document.on 'cocoon:before-remove', (e, item) ->
  unbindAutocomplete(item.find(AUTOCOMPLETE_SELECTOR))

if Turbolinks?
  $(document)
    .on 'turbolinks:load', ->
      bindAutocomplete($(AUTOCOMPLETE_SELECTOR))

    .on 'turbolinks:before-cache', ->
      unbindAutocomplete($(AUTOCOMPLETE_SELECTOR))

else
  $document.on 'ready', ->
    bindAutocomplete($(AUTOCOMPLETE_SELECTOR))
