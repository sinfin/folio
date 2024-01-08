window.Folio.Stimulus.register('d-molecule-cards-full-width', class extends window.Stimulus.Controller {
  static targets = ['slide', 'controlDot']
  static values = {
    initialSlideIndex: Number,
    slideActiveClass: String,
    slideDotActiveClass: String
  }

  connect () {
    this.currentSlideIndex = this.initialSlideIndexValue
  }

  setCurrentSlide () {
    this.slideTargets.forEach((slide, index) => {
      if (index === this.currentSlideIndex) {
        slide.classList.add(this.slideActiveClassValue)
      } else {
        slide.classList.remove(this.slideActiveClassValue)
      }
    })
  }

  setCurrentSlideDot () {
    this.controlDotTargets.forEach((dot) => {
      const index = parseInt(dot.dataset.index)

      if (index === this.currentSlideIndex) {
        dot.classList.add(this.slideDotActiveClassValue)
      } else {
        dot.classList.remove(this.slideDotActiveClassValue)
      }
    })
  }

  onControlDotClick = (event) => {
    this.currentSlideIndex = parseInt(event.currentTarget.dataset.index)

    this.setCurrentSlide()
    this.setCurrentSlideDot()
  }
})
