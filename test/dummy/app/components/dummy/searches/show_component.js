window.Folio.Stimulus.register('d-searches-show', class extends window.Stimulus.Controller {
  static values = {
  }

})

/*(function() {
  var aborted, ajax, debouncedLoad, getCachedResult, load, resultsCache, setCachedResults, timeout;

  resultsCache = [];

  ajax = null;

  aborted = false;

  timeout = null;

  getCachedResult = function(q) {
    var result;
    result = null;
    resultsCache.forEach(function(cached) {
      if (q === cached.q) {
        result = cached;
        return false;
      }
    });
    return result;
  };

  setCachedResults = function(q, $wrap) {
    var cachedResult;
    cachedResult = getCachedResult(q);
    if (cachedResult && (cachedResult.tabs != null) && (cachedResult.results != null)) {
      $wrap.find('.d-searches-show__results-wrap').html(cachedResult.results);
      $wrap.find('.d-searches-show__tabs').html(cachedResult.tabs);
      return true;
    } else {
      return false;
    }
  };

  load = function($input, $form, $wrap) {
    var tabMatch, url, value;
    value = $input.val();
    if (setCachedResults(value, $wrap)) {
      return;
    }
    url = ($form.prop('action')) + "?q=" + value;
    tabMatch = window.location.search.match(/tab=[^&]+/);
    if (tabMatch && tabMatch[0]) {
      url += "&" + tabMatch[0];
    }
    return $.ajax({
      url: url,
      method: 'GET',
      success: function(response, status, jxHr) {
        var $response, cacheEntry, resultsHtml, tabsHtml;
        $response = $(response);
        tabsHtml = $response.find('.d-searches-show__tabs').html();
        resultsHtml = $response.find('.d-searches-show__results-wrap').html();
        $wrap.find('.d-searches-show__tabs').html(tabsHtml);
        $wrap.find('.d-searches-show__results-wrap').html(resultsHtml);
        $wrap.removeClass('d-searches-show--loading');
        cacheEntry = {
          q: value,
          tabs: tabsHtml,
          results: resultsHtml
        };
        resultsCache = resultsCache.slice(0, 4);
        resultsCache.unshift(cacheEntry);
        return Turbolinks.controller.replaceHistoryWithLocationAndRestorationIdentifier(url, Turbolinks.uuid());
      },
      error: function() {
        if (aborted) {
          return aborted = false;
        } else {
          return Turbolinks.visist(($form.prop('action')) + "?q=" + value);
        }
      }
    });
  };

  debouncedLoad = window.Folio.debounce(load, 300);

  $(document).on('turbolinks:load', function() {
    return $('.d-searches-show__input').on('keyup.dSearchesShow change.dSearchesShow', function(e) {
      var perform;
      perform = (function(_this) {
        return function() {
          var $form, $input, $wrap;
          $input = $(_this);
          $form = $input.closest('.d-searches-show__form');
          $wrap = $form.closest('.d-searches-show');
          if (setCachedResults(_this.value, $wrap)) {
            return;
          }
          $wrap.addClass('d-searches-show--loading');
          return debouncedLoad($input, $form, $wrap);
        };
      })(this);
      if (e.type === "change") {
        return timeout = setTimeout(perform, 100);
      } else {
        return perform();
      }
    });
  }).on('turbolinks:request-start', function() {
    var timeeout;
    if (ajax) {
      aborted = true;
      ajax.abort();
      ajax = null;
    }
    if (timeout) {
      clearTimeout(timeout);
      return timeeout = null;
    }
  }).on('turbolinks:before-render', function() {
    return $('.d-searches-show__input').off('keyup.dSearchesShow change.dSearchesShow');
  });

}).call(this);*/
