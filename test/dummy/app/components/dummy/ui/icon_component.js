window.Dummy = window.Dummy || {}
window.Dummy.Ui = window.Dummy.Ui || {}
window.Dummy.Ui.Icon = window.Dummy.Ui.Icon || {}

window.Dummy.Ui.Icon.SVG_NS = 'http://www.w3.org/2000/svg'
window.Dummy.Ui.Icon.SVG_XLINK = 'http://www.w3.org/1999/xlink'

window.Dummy.Ui.Icon.data = (name, options = {}) => {
  if (!window.Dummy.Ui.Icon.svgSpritePath) throw new Error('Missing svgSpritePath. Add render(Dummy::Ui::IconComponent.new(head_html: true)) to <head>.')

  const data = { name }

  data.defaultSize = window.Dummy.Ui.Icon.defaultSizes[name]
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

  data.classNames = ['d-ui-icon', `d-ui-icon--${name}`]

  if (options.class) {
    options.class.split(' ').forEach((className) => data.classNames.push(className))
  }

  data.href = `${window.Dummy.Ui.Icon.svgSpritePath}#${name}`

  data.data = options.data || {}

  return data
}

window.Dummy.Ui.Icon.create = (name, options = {}) => {
  const data = window.Dummy.Ui.Icon.data(name, options)

  const svg = document.createElementNS(window.Dummy.Ui.Icon.SVG_NS, 'svg')
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

  const use = document.createElementNS(window.Dummy.Ui.Icon.SVG_NS, 'use')
  use.setAttributeNS(window.Dummy.Ui.Icon.SVG_XLINK, 'xlink:href', data.href)

  svg.appendChild(use)

  return svg
}
