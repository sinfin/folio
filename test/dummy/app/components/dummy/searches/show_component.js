window.Folio.Stimulus.register('d-searches-show', class extends window.Stimulus.Controller {
  static values = {
    autocompleteResults: []
  }

  loadAutocompleteResults(input, form, wrap) {
    const value = input.value;
    const cachedResult = this.autocompleteResultsValue.find(result => result.q === value);

    if (cachedResult && cachedResult.tabs != null && cachedResult.results != null) {
      wrap.querySelector('.d-searches-show__results-wrap').innerHTML = cachedResult.results;
      wrap.querySelector('.d-searches-show__tabs').innerHTML = cachedResult.tabs;
      return;
    }

    let url = `${form.getAttribute('action')}?q=${value}`;
    const tabMatch = window.location.search.match(/tab=[^&]+/);

    if (tabMatch && tabMatch[0]) {
      url += `&${tabMatch[0]}`;
    }

    fetch(url)
      .then(response => response.text())
      .then(response => {
        const parser = new DOMParser();
        const doc = parser.parseFromString(response, 'text/html');
        const tabsHtml = doc.querySelector('.d-searches-show__tabs').innerHTML;
        const resultsHtml = doc.querySelector('.d-searches-show__results-wrap').innerHTML;

        wrap.querySelector('.d-searches-show__tabs').innerHTML = tabsHtml;
        wrap.querySelector('.d-searches-show__results-wrap').innerHTML = resultsHtml;
        wrap.classList.remove('d-searches-show--loading');

        const cacheEntry = {
          q: value,
          tabs: tabsHtml,
          results: resultsHtml
        };

        this.autocompleteResultsValue.unshift(cacheEntry);
        this.autocompleteResultsValue = this.autocompleteResultsValue.slice(0, 4);
        Turbolinks.controller.replaceHistoryWithLocationAndRestorationIdentifier(url, Turbolinks.uuid());
      })
      .catch(error => {
        if (error.name !== 'AbortError') {
          Turbolinks.visit(`${form.getAttribute('action')}?q=${value}`);
        }
      });
  }

  debouncedLoadAutocompleteResults = window.Folio.debounce(this.loadAutocompleteResults, 300);

  connect() {
    const input = this.element.querySelector('.d-searches-show__input');
    input.addEventListener('input', () => {
      const form = input.closest('.d-searches-show__form');
      const wrap = form.closest('.d-searches-show');
      wrap.classList.add('d-searches-show--loading');
      this.debouncedLoadAutocompleteResults(input, form, wrap);
    });
  }

  disconnect() {
    const input = this.element.querySelector('.d-searches-show__input');
    input.removeEventListener('input', () => {});
  }
});
