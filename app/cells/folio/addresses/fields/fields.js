document.addEventListener('change', (e) => {
  if (e.target.matches('.f-addresses-fields__country-code-input')) {
    const wrap = e.target.closest('.f-addresses-fields__fields-wrap');
    wrap.setAttribute('data-country-code', e.target.value);

    window.Folio.Input.Phone.onAddressCountryCodeChange(wrap, e.target.value);
  }
});