const SLIDE_ACTIVE_CLASS = 'd-molecule-cards-full-width__slide--active'
const DOT_ACTIVE_CLASS = 'd-molecule-cards-full-width__controls-dot--active'

window.Folio.Stimulus.register('d-molecule-cards-full-width', class extends window.Stimulus.Controller {
  static targets = ['slide', 'controlDot']

  connect () {
    this.currentSlideIndex = 0
    this.updateSlider()
  }

  updateSlider () {
    this.slideTargets.forEach((slide, index) => {
      if (index === this.currentSlideIndex) {
        slide.classList.add(SLIDE_ACTIVE_CLASS)
      } else {
        slide.classList.remove(SLIDE_ACTIVE_CLASS)
      }
    })

    this.controlDotTargets.forEach((dot) => {
      const index = parseInt(dot.dataset.index)

      if (index === this.currentSlideIndex) {
        dot.classList.add(DOT_ACTIVE_CLASS)
      } else {
        dot.classList.remove(DOT_ACTIVE_CLASS)
      }
    })
  }

  onControlDotClick = (event) => {
    this.currentSlideIndex = parseInt(event.currentTarget.dataset.index)
    this.updateSlider()
  }
})
