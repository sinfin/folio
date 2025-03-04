const clearPlugin = (_, tdClasses) => {
  const oldBuildWidget = tdClasses.Display.prototype._buildWidget

  tdClasses.Display.prototype._buildWidget = function () {
    oldBuildWidget.call(this)
    const label = (window.Folio.Input.DateTime.i18n && window.Folio.Input.DateTime.i18n.clearDate) || 'Clear date'

    const clearWidget = document.createElement('div')

    clearWidget.classList.add('tempus-dominus-widget__clear', 'clear-container', 'td-half')
    clearWidget.setAttribute('data-action', 'clear')

    const icon = this._iconTag(this.optionsStore.options.display.icons.clear)
    icon.classList.add('tempus-dominus-widget__clear-icon')

    clearWidget.appendChild(icon)
    clearWidget.appendChild(document.createTextNode(label))

    const target = this._widget.querySelector('.time-container') || this._widget.querySelector('.date-container')
    target.after(clearWidget)
  }
}

window.tempusDominus.extend(clearPlugin)
