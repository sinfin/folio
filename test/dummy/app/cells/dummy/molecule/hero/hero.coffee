bindSlick = ->
  $('.d-molecule-hero__slider--has-more')
    .each ->
      $this = $(this)

      $this
        .find('.f-lazyload')
        .each ->
          window.folioLazyloadInstances.forEach (instance) =>
            instance.load(this)

      $this
        .removeClass('d-molecule-hero__slider--loading')
        .addClass('d-molecule-hero__slider--slick')
        .slick
          arrows: true
          dots: true
          infinite: true
          slidesToShow: 1
          slidesToScroll: 1
          prevArrow: $this.siblings('.d-molecule-hero__arrow--left')
          nextArrow: $this.siblings('.d-molecule-hero__arrow--right')
          appendDots: $this.siblings('.d-molecule-hero__dots').find('.d-molecule-hero__dots-container')
          dotsClass: 'd-molecule-hero__dots-inner'

destroySlick = ($el) ->
  $('d-molecule-hero__slider--slick')
    .slick('unslick')
    .removeClass('d-molecule-hero__slider--slick')
    .addClass('d-molecule-hero__slider--loading')

$(document)
  .on 'folioAtomsLoad', bindSlick
  .on 'folioAtomsUnload', destroySlick
