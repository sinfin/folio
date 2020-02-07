REMOTE_AUTOCOMPLETE_SELECTOR = '.folio-console-string-input--remote-autocomplete'
AUTOCOMPLETE_SELECTOR = '.folio-console-string-input--autocomplete'
NUMERAL_SELECTOR = '.folio-console-string-input--numeral'

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

window.folioConsoleBindRemoteAutocomplete = ($elements) ->
  $elements.each ->
    $this = $(this)
    $this.autocomplete
      source: (request, response) ->
        $.ajax
          url: $this.data('remote-autocomplete')
          dataType: "json"
          data:
            q: request.term
          success: (data) ->
            response(data.data)
      select: (e, ui) ->
        $form = $this.closest('[data-auto-submit], .f-c-index-header__form')
        if $form.length
          setTimeout (-> $form.submit()), 0

window.folioConsoleUnbindRemoteAutocomplete = ($elements) ->
  $elements.off('change').autocomplete('destroy')

cleaveOpts =
  numeral: true
  numeralDecimalScale: 6
  delimiter: ' '
  onValueChanged: (e) ->
    @element.nextElementSibling.value = e.target.rawValue

window.folioConsoleBindNumeralInput = ($elements) ->
  $elements.each ->
    $this = $(this)
    name = @name
    $this
      .data('type', @type)
      .data('name', name)
      .removeAttr('name')
      .prop('type', 'string')
    $this.after """<input type="hidden" name="#{name}" value="#{@value}">"""
    cleave = new Cleave(this, cleaveOpts)

window.folioConsoleUnbindNumeralInput = ($elements) ->
  $elements.each ->
    $this = $(this)

    $this.prop('type', $this.data('type')) if $this.data('type')
    $this.prop('name', $this.data('name')) if $this.data('name')

    $hidden = $this.next('input[type="hidden"]')
    if $hidden.length
      $this.val($hidden.val())
      $hidden.remove()

    cleave = $this.data('cleave')
    if cleave
      cleave.destroy()
      $this.data('cleave', null)

window.folioConsoleBindNumeralInputIn = ($wrap) ->
  window.folioConsoleBindNumeralInput $wrap.find(NUMERAL_SELECTOR)

window.folioConsoleUnbindNumeralInputIn = ($wrap) ->
  window.folioConsoleUnbindNumeralInput $wrap.find(NUMERAL_SELECTOR)

$(document)
  .on 'cocoon:after-insert', (e, insertedItem) ->
    bindAutocomplete(insertedItem.find(AUTOCOMPLETE_SELECTOR))
    window.folioConsoleBindNumeralInput(insertedItem.find(NUMERAL_SELECTOR))
    window.folioConsoleBindRemoteAutocomplete(insertedItem.find(REMOTE_AUTOCOMPLETE_SELECTOR))

  .on 'cocoon:before-remove', (e, item) ->
    unbindAutocomplete(item.find(AUTOCOMPLETE_SELECTOR))
    window.folioConsoleUnbindNumeralInput(item.find(NUMERAL_SELECTOR))
    window.folioConsoleUnbindRemoteAutocomplete(item.find(REMOTE_AUTOCOMPLETE_SELECTOR))

if Turbolinks?
  $(document)
    .on 'turbolinks:load', ->
      bindAutocomplete($(AUTOCOMPLETE_SELECTOR))
      window.folioConsoleBindNumeralInput($(NUMERAL_SELECTOR))
      window.folioConsoleBindRemoteAutocomplete($(REMOTE_AUTOCOMPLETE_SELECTOR))

    .on 'turbolinks:before-cache', ->
      unbindAutocomplete($(AUTOCOMPLETE_SELECTOR))
      window.folioConsoleUnbindNumeralInput($(NUMERAL_SELECTOR))
      window.folioConsoleUnbindRemoteAutocomplete($(REMOTE_AUTOCOMPLETE_SELECTOR))

else
  $ ->
    bindAutocomplete($(AUTOCOMPLETE_SELECTOR))
    window.folioConsoleBindNumeralInput($(NUMERAL_SELECTOR))
    window.folioConsoleBindRemoteAutocomplete($(REMOTE_AUTOCOMPLETE_SELECTOR))
