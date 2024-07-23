//= require vanilla.kinetic
//= require folio/debounce

window.Dummy = window.Dummy || {}
window.Dummy.Ui = window.Dummy.Ui || {}
window.Dummy.Ui.ScrollList = window.Dummy.Ui.ScrollList || {}
window.Dummy.Ui.ScrollList.touch = false

window.addEventListener('touchstart', () => {
  window.Dummy.Ui.ScrollList.touch = true

  for (const scrollList of document.querySelectorAll('.d-ui-scroll-list[data-d-ui-scroll-list-touch-value="false"]')) {
    scrollList.setAttribute('data-d-ui-scroll-list-touch-value', 'true')
  }
}, { once: true })

window.Folio.Stimulus.register('d-ui-scroll-list', class extends window.Stimulus.Controller {
  static targets = ['outer', 'controlPrev', 'controlNext', 'ul', 'li']

  static values = { touch: Boolean }

  connect () {
    if (window.Dummy.Ui.ScrollList.touch) return
    this.bind()
  }

  disconnect () {
    this.unbind()
  }

  bind () {
    this.debouncedOnScroll = window.Folio.debounce(this.onScroll.bind(this))

    this.vanillaKinetic = new window.VanillaKinetic(this.outerTarget, {
      y: false,
      moved: this.debouncedOnScroll,
      maxvelocity: 1
    })
  }

  unbind () {
    if (this.vanillaKinetic) {
      this.vanillaKinetic.detach()
      delete this.vanillaKinetic
    }
  }

  liTargetConnected (element) {
    for (const draggable of element.querySelectorAll('a, img')) {
      draggable.draggable = false
    }
  }

  touchValueChanged () {
    if (this.touchValue) {
      this.unbind()
    } else {
      this.bind()
    }
  }

  onScroll () {
    this.toggleControlsClassNames()
  }

  toggleControlsClassNames () {
    this.controlPrevTarget.classList.toggle('d-ui-scroll-list__control--disabled',
      this.outerTarget.scrollLeft === 0)

    const maxScrollLeft = this.outerTarget.scrollWidth - this.outerTarget.clientWidth

    this.controlNextTarget.classList.toggle('d-ui-scroll-list__control--disabled',
      this.outerTarget.scrollLeft === maxScrollLeft)
  }

  onControlClick (e, direction) {
    e.preventDefault()

    const baseLeft = this.outerTarget.scrollLeft + (direction * window.innerWidth * 2 / 3)

    // align li
    let targetLeft = null

    if (baseLeft > 0) {
      this.liTargets.forEach(li => {
        if (targetLeft !== null) return

        if (li.offsetLeft <= baseLeft && baseLeft < li.offsetLeft + li.offsetWidth) {
          targetLeft = li.offsetLeft

          // shift by gap
          const computedGap = window.getComputedStyle(this.ulTarget).gap
          if (computedGap && typeof computedGap === 'string' && computedGap.indexOf('px') !== -1) {
            targetLeft -= parseFloat(computedGap)
          }
        }
      })
    }

    this.outerTarget.scrollTo({
      left: targetLeft === null ? baseLeft : targetLeft,
      behavior: 'smooth'
    })
  }

  onNextClick (e) {
    this.onControlClick(e, 1)
  }

  onPrevClick (e) {
    this.onControlClick(e, -1)
  }
})
