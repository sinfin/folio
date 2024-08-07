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

  openValueChanged (to, from) {
    if (from === undefined) return

    if (to) {
      this.showTooltip()
    } else {
      this.hideTooltip()
    }
  }

  removeTooltipElement () {
    this.clearClickCallback()

    if (this.cleanup) {
      this.cleanup()
      delete this.cleanup
    }

    if (this.tooltipElement) {
      this.tooltipElement.remove()
      delete this.tooltipElement
    }
  }

  showTooltip () {
    if (!this.tooltipElement) {
      this.createTooltipElement()
    }
  }

  hideTooltip () {
    this.removeTooltipElement()
  }

  clearClickCallback () {
    if (this.clickCallback) {
      if (this.tooltipElement) {
        this.tooltipElement.removeEventListener('click', this.clickCallback)
      }

      delete this.clickCallback
    }
  }

  createTooltipElement () {
    this.tooltipElement = document.importNode(window.Folio.Tooltip.TEMPLATE.content.children[0], true)
    this.tooltipElement.querySelector('.tooltip-inner').innerHTML = this.titleValue
    this.tooltipElement.classList.add(`tooltip--${this.variantValue}`)

    if (this.tooltipClassNameValue) {
      this.tooltipClassNameValue.split(' ').forEach((className) => { this.tooltipElement.classList.add(className) })
    }
    if (this.staticValue) this.tooltipElement.classList.add('tooltip--static')

    document.body.appendChild(this.tooltipElement)

    this.clearClickCallback()

    if (this.staticValue) {
      this.clickCallback = (e) => {
        e.preventDefault()
        this.dispatch('tooltipClick', { detail: { close: () => { this.openValue = false } } })
      }

      this.tooltipElement.addEventListener('click', this.clickCallback)
    }

    this.cleanup = window.FloatingUIDOM.autoUpdate(
      this.element,
      this.tooltipElement,
      () => {
        const options = {
          middleware: [
            window.FloatingUIDOM.offset({ mainAxis: 8 }),
            window.FloatingUIDOM.arrow({ element: this.tooltipElement.querySelector('.tooltip-arrow') })
          ]
        }

        if (this.placementValue === 'auto') {
          options.middleware.push(window.FloatingUIDOM.autoPlacement())
        } else {
          options.placement = this.placementValue
        }

        window.FloatingUIDOM.computePosition(this.element, this.tooltipElement, options).then(({
          x,
          y,
          middlewareData,
          placement
        }) => {
          Object.assign(this.tooltipElement.style, {
            left: `${x}px`,
            top: `${y}px`
          })

          this.tooltipElement.setAttribute('data-popper-placement', placement)

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

            Object.assign(this.tooltipElement.querySelector('.tooltip-arrow').style, {
              left,
              top
            })
          }
        })
      }
    )
  }
})
