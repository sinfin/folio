window.Folio = window.Folio || {}
window.Folio.Ui = window.Folio.Ui || {}
window.Folio.Ui.Icon = window.Folio.Ui.Icon || {}

window.Folio.Ui.Icon.SVG_NS = 'http://www.w3.org/2000/svg'
window.Folio.Ui.Icon.SVG_XLINK = 'http://www.w3.org/1999/xlink'

window.Folio.Ui.Icon.create = (name, options = {}) => {
  if (!window.Folio.Ui.Icon.svgSpritePath) throw new Error("Missing svgSpritePath. Add cell('folio/ui/icon').render(:_head) to <head>.")

  const defaultSize = window.Folio.Ui.Icon.defaultSizes[name]
  if (!defaultSize) throw new Error(`Unknown icon ${name}`)

  const svg = document.createElementNS(window.Folio.Ui.Icon.SVG_NS, 'svg')
  svg.setAttribute('viewBox', `0 0 ${defaultSize.width} ${defaultSize.height}`)

  if (options.height) {
    svg.style.height = `${options.height}px`
    svg.style.width = 'auto'
  } else if (options.width) {
    svg.style.height = 'auto'
    svg.style.width = `${options.width}px`
  } else {
    svg.style.height = defaultSize.height
    svg.style.width = defaultSize.width
  }

  svg.classList.add('f-ui-icon')
  svg.classList.add(`f-ui-icon--${name}`)

  if (options.class) svg.classList.add(options.class)

  const use = document.createElementNS(window.Folio.Ui.Icon.SVG_NS, 'use')
  use.setAttributeNS(window.Folio.Ui.Icon.SVG_XLINK,
    'xlink:href',
                     `${window.Folio.Ui.Icon.svgSpritePath}#${name}`)

  svg.appendChild(use)

  return svg
}
