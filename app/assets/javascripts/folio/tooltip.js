//= require floating-ui-core
//= require floating-ui-dom

window.Folio = window.Folio || {}
window.Folio.Tooltip = window.Folio.Tooltip || {}
window.Folio.Tooltip.TEMPLATE_HTML = window.Folio.Tooltip.TEMPLATE_HTML || `
  <div class="tooltip custom-tooltip bs-tooltip-auto show fade f-tooltip" role="tooltip" style="position: absolute; width: max-content; top: 0; left: 0">
    <div class="tooltip-arrow" style="position: absolute"></div>
    <div class="tooltip-inner">{CONTENT}</div>
  </div>
`

if (!window.Folio.Tooltip.TEMPLATE) {
  window.Folio.Tooltip.TEMPLATE = document.createElement('template')
  window.Folio.Tooltip.TEMPLATE.innerHTML = window.Folio.Tooltip.TEMPLATE_HTML
}

window.Folio.Tooltip.removeStimulusFromElement = ({ element }) => {
  if (!element) return
  if (!element.dataset.controller) return
  if (!element.dataset.controller.indexOf('f-tooltip') === -1) return

  if (element.dataset.controller === 'f-tooltip') {
    delete element.dataset.controller
  } else {
    element.dataset.controller = element.dataset.controller.replace(/ *f-tooltip */, '')
  }

  if (element.dataset.action) {
    if (element.dataset.action == 'mouseenter->f-tooltip#mouseenter mouseleave->f-tooltip#mouseleave') {
      delete element.dataset.action
    } else {
      element.dataset.action = element.dataset.action.replace(/ *mouseenter->f-tooltip#mouseenter mouseleave->f-tooltip#mouseleave */, '')
    }
  }

  Object.keys(element.dataset).forEach((key) => {
    if (key.indexOf('fTooltip') === 0) {
      delete element.dataset[key]
    }
  })
}

window.Folio.Tooltip.initStimulusForElement = ({ element, title, placement }) => {
  if (!element || !title) return

  element.dataset.fTooltipTitleValue = title

  if (placement) {
    element.dataset.fTooltipPlacementValue = placement
  }

  if (element.dataset.controller) {
    element.dataset.controller += " f-tooltip"
  } else {
    element.dataset.controller = "f-tooltip"
  }

  if (element.dataset.action) {
    element.dataset.action += ' mouseenter->f-tooltip#mouseenter mouseleave->f-tooltip#mouseleave'
  } else {
    element.dataset.action = 'mouseenter->f-tooltip#mouseenter mouseleave->f-tooltip#mouseleave'
  }
}

window.Folio.Tooltip.createTooltip = ({ element, title, placement, variant, tooltipClassName, staticTooltip, clickCallback }) => {
  const data = { element }

  data.tooltipElement = document.importNode(window.Folio.Tooltip.TEMPLATE.content.children[0], true)
  data.tooltipElement.querySelector('.tooltip-inner').innerHTML = title
  data.tooltipElement.classList.add(`tooltip--${variant}`)

  if (tooltipClassName) {
    tooltipClassName.split(' ').forEach((className) => { data.tooltipElement.classList.add(className) })
  }

  if (staticTooltip) {
    data.tooltipElement.classList.add('tooltip--static')
  }

  document.body.appendChild(data.tooltipElement)

  if (clickCallback) {
    data.clickCallback = clickCallback
    data.tooltipElement.addEventListener('click', data.clickCallback)
  }

  data.cleanup = window.FloatingUIDOM.autoUpdate(
    data.element,
    data.tooltipElement,
    () => {
      const options = {
        middleware: [
          window.FloatingUIDOM.offset({ mainAxis: 8 }),
          window.FloatingUIDOM.arrow({ element: data.tooltipElement.querySelector('.tooltip-arrow') })
        ]
      }

      if (placement === 'auto') {
        options.middleware.push(window.FloatingUIDOM.autoPlacement())
      } else {
        options.placement = placement
      }

      window.FloatingUIDOM.computePosition(element, data.tooltipElement, options).then(({
        x,
        y,
        middlewareData,
        placement
      }) => {
        Object.assign(data.tooltipElement.style, {
          left: `${x}px`,
          top: `${y}px`
        })

        data.tooltipElement.setAttribute('data-popper-placement', placement)

        if (middlewareData.arrow) {
          let left, top

          if (typeof middlewareData.arrow.x === 'number') {
            left = `${middlewareData.arrow.x}px`
          } else {
            left = ''
          }

          if (typeof middlewareData.arrow.y === 'number') {
            top = `${middlewareData.arrow.y}px`
          } else {
            top = ''
          }

          switch (placement) {
            case 'top':
              top = ''
              break
            case 'right':
              left = ''
              break
            case 'bottom':
              top = ''
              break
            case 'left':
              left = ''
              break
          }

          Object.assign(data.tooltipElement.querySelector('.tooltip-arrow').style, {
            left,
            top
          })
        }
      })
    }
  )

  element.folioTooltipData = data

  return element
}

window.Folio.Tooltip.removeTooltip = ({ element }) => {
  if (!element.folioTooltipData) return

  if (element.folioTooltipData.clickCallback) {
    element.folioTooltipData.tooltipElement.removeEventListener('click', element.folioTooltipData.clickCallback)
  }

  if (element.folioTooltipData.cleanup) {
    element.folioTooltipData.cleanup()
    delete element.folioTooltipData.cleanup
  }

  if (element.folioTooltipData.tooltipElement) {
    element.folioTooltipData.tooltipElement.remove()
    delete element.folioTooltipData.tooltipElement
  }

  delete element.folioTooltipData

  return element
}

window.Folio.Stimulus.register('f-tooltip', class extends window.Stimulus.Controller {
  static values = {
    title: String,
    placement: { type: String, default: 'auto' },
    trigger: { type: String, default: 'hover' },
    open: { type: Boolean, default: false },
    static: { type: Boolean, default: false },
    variant: { type: String, default: 'default' },
    tooltipClassName: { type: String, default: '' }
  }

  disconnect () {
    this.removeTooltipElement()
  }

  mouseleave () {
    this.openValue = false
  }

  mouseenter () {
    this.openValue = true
  }

  click () {
    this.openValue = !this.openValue
  }

  openValueChanged (to, from) {
    if (from === undefined) return

    if (to) {
      this.showTooltip()
    } else {
      this.hideTooltip()
    }
  }

  removeTooltipElement () {
    window.Folio.Tooltip.removeTooltip({ element: this.element })
  }

  showTooltip () {
    window.Folio.Tooltip.createTooltip({
      element: this.element,
      title: this.titleValue,
      placement: this.placementValue,
      variant: this.variantValue,
      tooltipClassName: this.tooltipClassNameValue,
      staticTooltip: this.staticValue,
      clickCallback: this.staticValue ? () => {
        this.dispatch('tooltipClick', { detail: { close: () => { this.openValue = false } } })
      } : null,
    })
  }

  hideTooltip () {
    this.removeTooltipElement()
  }
})
