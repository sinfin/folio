window.Folio = window.Folio || {}
window.Folio.Ui = window.Folio.Ui || {}
window.Folio.Ui.Icon = window.Folio.Ui.Icon || {}

window.Folio.Ui.Icon.SVG_NS = 'http://www.w3.org/2000/svg'
window.Folio.Ui.Icon.SVG_XLINK = 'http://www.w3.org/1999/xlink'

window.Folio.Ui.Icon.data = (name, options = {}) => {
  if (!window.Folio.Ui.Icon.svgSpritePath) throw new Error("Missing svgSpritePath. Add cell('folio/ui/icon').render(:_head) to <head>.")

  const data = { name }

  data.defaultSize = window.Folio.Ui.Icon.defaultSizes[name]
  if (!data.defaultSize) throw new Error(`Unknown icon ${name}`)

  data.viewBox = `0 0 ${data.defaultSize.width} ${data.defaultSize.height}`

  data.style = {}

  if (options.height) {
    data.style.height = `${options.height}px`
    data.style.width = 'auto'
  } else if (options.width) {
    data.style.height = 'auto'
    data.style.width = `${options.width}px`
  } else {
    data.style.height = `${data.defaultSize.height}px`
    data.style.width = `${data.defaultSize.width}px`
  }

  data.classNames = ['f-ui-icon', `f-ui-icon--${name}`]

  if (options.class) {
    options.class.split(' ').forEach((className) => data.classNames.push(className))
  }

  data.href = `${window.Folio.Ui.Icon.svgSpritePath}#${name}`

  data.data = options.data || {}

  return data
}

window.Folio.Ui.Icon.create = (name, options = {}) => {
  const data = window.Folio.Ui.Icon.data(name, options)

  const svg = document.createElementNS(window.Folio.Ui.Icon.SVG_NS, 'svg')
  svg.setAttribute('viewBox', data.viewBox)

  Object.keys(data.style).forEach((key) => {
    svg.style[key] = data.style[key]
  })

  data.classNames.forEach((className) => {
    svg.classList.add(className)
  })

  Object.keys(data.data).forEach((key) => {
    svg.dataset[key] = data.data[key]
  })

  const use = document.createElementNS(window.Folio.Ui.Icon.SVG_NS, 'use')
  use.setAttributeNS(window.Folio.Ui.Icon.SVG_XLINK, 'xlink:href', data.href)

  svg.appendChild(use)

  return svg
}
