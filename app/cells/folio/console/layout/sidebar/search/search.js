// converted via https://coffeescript.org/#try

(function () {
var $form, $input, $wrap, ESCAPE_KEY, cancel, debouncedSearch, handle, lastValue, search;

ESCAPE_KEY = 27;

lastValue = null;

$input = null;

$wrap = null;

$form = null;

search = function(input) {
  $input || ($input = $(input));
  if ($input.val() === lastValue) {
    return;
  }
  lastValue = $input.val();
  $form || ($form = $input.closest('form'));
  return $.ajax(`${$form.prop('action')}.json`, {
    data: {
      q: lastValue
    },
    method: 'GET',
    success: function(response) {
      return $wrap.find('.f-c-layout-sidebar-search__results-inner').html($(response).find('.f-c-searches-results__ul'));
    },
    complete: function() {
      $wrap.removeClass('f-c-layout-sidebar-search--loading');
      if ($wrap.find('.f-c-searches-results__li').length === 0) {
        return $wrap.addClass('f-c-layout-sidebar-search--error');
      }
    }
  });
};

debouncedSearch = window.Folio.debounce(search, 300);

handle = function(e) {
  $wrap || ($wrap = $('.f-c-layout-sidebar-search'));
  if (this.value === '' || e.keyCode === ESCAPE_KEY) {
    $wrap.removeClass('f-c-layout-sidebar-search--searching f-c-layout-sidebar-search--loading f-c-layout-sidebar-search--error');
    if (e.keyCode === ESCAPE_KEY) {
      $input || ($input = $wrap.find('.f-c-layout-sidebar-search__input'));
      $input.val('');
    }
  } else if (this.value !== lastValue) {
    $wrap.removeClass('f-c-layout-sidebar-search--error');
    $wrap.addClass('f-c-layout-sidebar-search--searching f-c-layout-sidebar-search--loading');
  }
  return debouncedSearch(this);
};

cancel = function(e) {
  e.preventDefault();
  $wrap || ($wrap = $('.f-c-layout-sidebar-search'));
  $input || ($input = $wrap.find('.f-c-layout-sidebar-search__input'));
  $input.val('');
  return $wrap.removeClass('f-c-layout-sidebar-search--error f-c-layout-sidebar-search--searching f-c-layout-sidebar-search--loading');
};

$(document).on('submit', '.f-c-layout-sidebar-search__form', function(e) {
  return e.preventDefault();
}).on('keyup', '.f-c-layout-sidebar-search__input', handle).on('click', '.js-f-c-layout-sidebar-search-cancel', cancel);
})()
