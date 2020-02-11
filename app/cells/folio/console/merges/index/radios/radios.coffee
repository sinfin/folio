$ ->
  $radios = $('.f-c-merges-index-radios__input')
  return if $radios.length is 0
  $footerLink = $('.f-c-merges-index-footer__btn--link')
  $labelOriginal = $('.f-c-merges-index-footer__label-content--original')
  $labelDuplicate = $('.f-c-merges-index-footer__label-content--duplicate')

  uncheckSibling = ($input) ->
    $input
      .closest('.f-c-merges-index-radios__label')
      .siblings('.f-c-merges-index-radios__label')
      .find('.f-c-merges-index-radios__input')
      .prop('checked', false)

  updateFooterPreview = ($input, $label) ->
    if $input.length
      $wrap = $input.closest('.f-c-merges-index-radios')
      $row = $wrap.next()
      $label.html($wrap.data('label'))
      $img = $row.find('.f-c-index-images__img, .f-c-index-images__missing').first()
      if $img
        $label.prevAll('img').remove()
        $label.before($img.clone())
      $label.closest('.f-c-merges-index-footer__label').prop('hidden', false)
    else
      $label.closest('.f-c-merges-index-footer__label').prop('hidden', true)

  updateFooter = ->
    $checked = $radios.filter(':checked')
    complete = $checked.length is 2

    $footerLink.toggleClass('disabled', not complete)

    $original = $checked.filter('.f-c-merges-index-radios__input--original')
    $duplicate = $checked.filter('.f-c-merges-index-radios__input--duplicate')

    updateFooterPreview($original, $labelOriginal)
    updateFooterPreview($duplicate, $labelDuplicate)

    if complete
      original = $original.data('slug') or $original.val()
      duplicate = $duplicate.data('slug') or $duplicate.val()

      href = $footerLink
        .data('href')
        .replace('/X/', "/#{original}/")
        .replace('/Y/', "/#{duplicate}/")
      $footerLink.prop('href', href)

  $radios.on 'change', ->
    uncheckSibling($(this))
    updateFooter()

  $('.f-c-merges-index-footer__label-remove').on 'click', ->
    $radios
      .filter("[name='merge[#{$(this).data('key')}]']")
      .prop('checked', false)
    updateFooter()

  $footerLink.on 'click', (e) ->
    e.preventDefault() if $(this).hasClass('disabled')
