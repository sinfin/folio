window.Folio.Stimulus.register('d-molecule-cards-full-width', class extends window.Stimulus.Controller {
  static targets = ['slide', 'controlDot']

  static values = { currentSlideIndex: { type: Number, default: 0 } }

  setCurrentSlide () {
    this.slideTargets.forEach((slide, index) => {
      slide.classList.toggle('d-molecule-cards-full-width__slide--active',
                             index === this.currentSlideIndexValue)
    })
  }

  setCurrentSlideDot () {
    this.controlDotTargets.forEach((dot) => {
      const index = parseInt(dot.dataset.index)

      dot.classList.toggle('d-molecule-cards-full-width__controls-dot--active',
                           index === this.currentSlideIndexValue)
    })
  }

  onControlDotClick = (event) => {
    this.currentSlideIndexValue = parseInt(event.currentTarget.dataset.index)

    this.setCurrentSlide()
    this.setCurrentSlideDot()
  }
})
