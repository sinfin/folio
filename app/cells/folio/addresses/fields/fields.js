$(document)
  .on('change', '.f-addresses-fields__country-code-input', (e) => {
    $(e.currentTarget)
      .closest('.f-addresses-fields__fields-wrap')
      .attr('data-country-code', e.currentTarget.value)
  })
