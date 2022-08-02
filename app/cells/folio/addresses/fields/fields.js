$(document)
  .on('change', '.f-addresses-fields__country-code-input', (e) => {
    const $wrap = $(e.currentTarget).closest('.f-addresses-fields__fields-wrap')
    $wrap.attr('data-country-code', e.currentTarget.value)

    window.Folio.Input.Phone.onAddressCountryCodeChange($wrap, e.currentTarget.value)
  })
