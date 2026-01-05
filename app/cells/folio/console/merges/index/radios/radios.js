// converted via https://coffeescript.org/#try
// once you update it, remove it from package.json standard js ignored files
window.jQuery(function () {
  let $footerLink, $labelDuplicate, $labelOriginal, $radios, uncheckSibling, updateFooter, updateFooterPreview
  $radios = window.jQuery('.f-c-merges-index-radios__input')
  if ($radios.length === 0) {
    return
  }
  $footerLink = window.jQuery('.f-c-merges-index-footer__btn--link')
  $labelOriginal = window.jQuery('.f-c-merges-index-footer__label-content--original')
  $labelDuplicate = window.jQuery('.f-c-merges-index-footer__label-content--duplicate')
  uncheckSibling = function ($input) {
    return $input.closest('.f-c-merges-index-radios__label').siblings('.f-c-merges-index-radios__label').find('.f-c-merges-index-radios__input').prop('checked', false)
  }
  updateFooterPreview = function ($input, $label) {
    let $img, $row, $wrap
    if ($input.length) {
      $wrap = $input.closest('.f-c-merges-index-radios')
      $row = $wrap.next()
      $label.html($wrap.data('label'))
      $img = $row.find('.f-c-index-images__img, .f-c-index-images__missing').first()
      if ($img) {
        $label.prevAll('img').remove()
        $label.before($img.clone())
      }
      return $label.closest('.f-c-merges-index-footer__label').prop('hidden', false)
    } else {
      return $label.closest('.f-c-merges-index-footer__label').prop('hidden', true)
    }
  }
  updateFooter = function () {
    let $checked, $duplicate, $original, complete, duplicate, href, original
    $checked = $radios.filter(':checked')
    complete = $checked.length === 2
    $footerLink.toggleClass('disabled', !complete)
    $original = $checked.filter('.f-c-merges-index-radios__input--original')
    $duplicate = $checked.filter('.f-c-merges-index-radios__input--duplicate')
    updateFooterPreview($original, $labelOriginal)
    updateFooterPreview($duplicate, $labelDuplicate)
    if (complete) {
      original = $original.data('slug') || $original.val()
      duplicate = $duplicate.data('slug') || $duplicate.val()
      href = $footerLink.data('href').replace('/X/', `/${original}/`).replace('/Y/', `/${duplicate}/`)
      return $footerLink.prop('href', href)
    }
  }
  $radios.on('change', function () {
    uncheckSibling(window.jQuery(this))
    return updateFooter()
  })
  window.jQuery('.f-c-merges-index-footer__label-remove').on('click', function () {
    $radios.filter(`[name='merge[${$(this).data('key')}]']`).prop('checked', false)
    return updateFooter()
  })
  return $footerLink.on('click', function (e) {
    if (window.jQuery(this).hasClass('disabled')) {
      return e.preventDefault()
    }
  })
})
