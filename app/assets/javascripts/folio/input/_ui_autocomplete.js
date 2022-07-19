$.widget('ui.autocomplete', $.ui.autocomplete, {
  _renderMenu: function ($ul, items) {
    $ul.attr('class', 'dropdown-menu ui-menu folio-console-autocomplete-input-menu')
    return $.each(items, (index, item) => {
      return this._renderItemData($ul, item)
    })
  },
  _renderItem: function ($ul, item) {
    return $(`<li class="ui-menu-item" title="${item.label}">
      <span class="dropdown-item ui-menu-item-wrapper folio-console-autocomplete-input-menu-item">${item.label}</span>
    </li>`).appendTo($ul)
  },
  _resizeMenu: function () {
    const $ul = this.menu.element
    const width = Math.min($ul.width('').outerWidth() + 1, this.element.outerWidth())
    return $ul.outerWidth(width)
  }
})
