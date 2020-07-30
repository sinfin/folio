REMOTE_AUTOCOMPLETE_SELECTOR = '.folio-console-string-input--remote-autocomplete'
AUTOCOMPLETE_SELECTOR = '.folio-console-string-input--autocomplete'
NUMERAL_SELECTOR = '.folio-console-string-input--numeral'
CONTENT_TEMPLATES_SELECTOR = '.folio-console-string-input--content-templates'

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
      minLength: 0
      source: (request, response) ->
        $.ajax
          url: $this.data('remote-autocomplete')
          dataType: "json"
          data:
            q: request.term
          success: (data) ->
            response(data.data)
      select: (e, ui) ->
        setTimeout (-> $this.trigger('remoteAutocompleteDidSelect')), 0
        $form = $this.closest('[data-auto-submit], .f-c-index-header__form')
        if $form.length
          setTimeout (-> $form.submit()), 0

    $this.on 'focus.folioConsoleRemoteAutocomplete', ->
      $this.autocomplete('search')

window.folioConsoleUnbindRemoteAutocomplete = ($elements) ->
  $elements
    .off('change')
    .off('focus.folioConsoleRemoteAutocomplete')
    .autocomplete('destroy')

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
    $this.data('cleave', new Cleave(this, cleaveOpts))

window.folioConsoleUnbindNumeralInput = ($elements) ->
  $elements.each ->
    $this = $(this)

    $this.prop('type', $this.data('type')) if $this.data('type')
    $this.prop('name', $this.data('name')) if $this.data('name')

    cleave = $this.data('cleave')
    if cleave
      cleave.destroy()
      $this.data('cleave', null)

    $hidden = $this.next('input[type="hidden"]')
    if $hidden.length
      $this.val($hidden.val())
      $hidden.remove()

window.folioConsoleBindNumeralInputIn = ($wrap) ->
  window.folioConsoleBindNumeralInput $wrap.find(NUMERAL_SELECTOR)

window.folioConsoleUnbindNumeralInputIn = ($wrap) ->
  window.folioConsoleUnbindNumeralInput $wrap.find(NUMERAL_SELECTOR)

window.folioConsoleBindContentTemplatesInput = ($elements) ->
  $elements.each ->
    $input = $(this)
    $wrap = $input.closest('.f-c-translated-inputs')
    $wrap = $input.closest('.form-group') if $wrap.length is 0
    return if $wrap.hasClass('f-c-js-content-templates-bound')
    $wrap.addClass('f-c-js-content-templates-bound')
    $label = $wrap.find('label')
    $menu = $('<div class="dropdown-menu f-c-content-templates-dropdown__menu" />')
    items = $input.data('content-templates').map (ary) ->
      $a = $("""<a href="#" class="dropdown-item f-c-content-templates-dropdown__item"></a>""")
      $a.text(ary.join(' / '))
      $a.data('value', ary)
      $menu.append($a)

    $flex = $("""
      <div class="f-c-content-templates-dropdown">
        <span class="ml-3 small f-c-content-templates-dropdown__toggle dropdown-toggle" data-toggle="dropdown">
          #{window.FolioConsole.translations.contentTemplates}
        </button>
      </div>
    """)
    $label.before($flex)
    $flex.prepend($label)
    $flex.append($menu)

window.folioConsoleUnbindContentTemplatesInput = ($elements) ->

$(document).on 'click', '.f-c-content-templates-dropdown__item', (e) ->
  e.preventDefault()
  $this = $(this)
  data = $this.data('value')
  return unless data
  return unless data.length

  $this
    .closest('.form-group, .f-c-translated-inputs')
    .find(CONTENT_TEMPLATES_SELECTOR)
    .each (i, el) ->
      $(el).val(data[i]) if data[i]

$(document)
  .on 'cocoon:after-insert', (e, insertedItem) ->
    bindAutocomplete(insertedItem.find(AUTOCOMPLETE_SELECTOR))
    window.folioConsoleBindContentTemplatesInput(insertedItem.find(CONTENT_TEMPLATES_SELECTOR))
    window.folioConsoleBindNumeralInput(insertedItem.find(NUMERAL_SELECTOR))
    window.folioConsoleBindRemoteAutocomplete(insertedItem.find(REMOTE_AUTOCOMPLETE_SELECTOR))

  .on 'cocoon:before-remove', (e, item) ->
    unbindAutocomplete(item.find(AUTOCOMPLETE_SELECTOR))
    window.folioConsoleUnbindContentTemplatesInput(item.find(CONTENT_TEMPLATES_SELECTOR))
    window.folioConsoleUnbindNumeralInput(item.find(NUMERAL_SELECTOR))
    window.folioConsoleUnbindRemoteAutocomplete(item.find(REMOTE_AUTOCOMPLETE_SELECTOR))

if Turbolinks?
  $(document)
    .on 'turbolinks:load', ->
      bindAutocomplete($(AUTOCOMPLETE_SELECTOR))
      window.folioConsoleBindNumeralInput($(NUMERAL_SELECTOR))
      window.folioConsoleBindContentTemplatesInput($(CONTENT_TEMPLATES_SELECTOR))
      window.folioConsoleBindRemoteAutocomplete($(REMOTE_AUTOCOMPLETE_SELECTOR))

    .on 'turbolinks:before-cache', ->
      unbindAutocomplete($(AUTOCOMPLETE_SELECTOR))
      window.folioConsoleUnbindNumeralInput($(NUMERAL_SELECTOR))
      window.folioConsoleUnbindContentTemplatesInput($(CONTENT_TEMPLATES_SELECTOR))
      window.folioConsoleUnbindRemoteAutocomplete($(REMOTE_AUTOCOMPLETE_SELECTOR))

else
  $ ->
    bindAutocomplete($(AUTOCOMPLETE_SELECTOR))
    window.folioConsoleBindNumeralInput($(NUMERAL_SELECTOR))
    window.folioConsoleBindContentTemplatesInput($(CONTENT_TEMPLATES_SELECTOR))
    window.folioConsoleBindRemoteAutocomplete($(REMOTE_AUTOCOMPLETE_SELECTOR))
