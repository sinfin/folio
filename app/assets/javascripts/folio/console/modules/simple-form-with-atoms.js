// converted via https://coffeescript.org/#try

(function () {
var editSetting, receiveMessage, selectTab, sendMessage, setHeight;

sendMessage = function(data) {
  return $('.f-c-simple-form-with-atoms__iframe, .f-c-merges-form-row__atoms-iframe').each(function() {
    return this.contentWindow.postMessage(data, window.origin);
  });
};

$(document).one('click', '.f-c-simple-form-with-atoms__form', function(e) {
  return $('.f-c-simple-form-with-atoms').addClass('f-c-simple-form-with-atoms--expanded-form');
}).on('click', '.f-c-simple-form-with-atoms__overlay-dismiss', function(e) {
  e.preventDefault();
  return window.postMessage({
    type: 'closeForm'
  }, window.origin);
}).on('click', '.f-c-simple-form-with-atoms__form-toggle, .f-c-simple-form-with-atoms__title--clickable', function(e) {
  e.preventDefault();
  return $('.f-c-simple-form-with-atoms').toggleClass('f-c-simple-form-with-atoms--expanded-form');
}).on('keyup', '.f-c-js-atoms-placement-label', function(e) {
  var $this;
  e.preventDefault();
  $this = $(this);
  return sendMessage({
    type: 'updateLabel',
    locale: $this.data('locale') || null,
    value: $this.val()
  });
}).on('keyup', '.f-c-js-atoms-placement-perex', function(e) {
  var $this;
  e.preventDefault();
  $this = $(this);
  return sendMessage({
    type: 'updatePerex',
    locale: $this.data('locale') || null,
    value: $this.val()
  });
}).on('change folioConsoleCustomChange folioCustomChange', '.f-c-js-atoms-placement-setting', function(e) {
  window.postMessage({
    type: 'refreshPreview'
  }, window.origin);
  // used to refresh react select async options
  return window.setTimeout((function() {
    return $(document).trigger('folioAtomSettingChanged');
  }), 0);
});

selectTab = function($el) {
  var $tab, id;
  $tab = $el.closest('.tab-pane');
  if ($tab.length && !$tab.hasClass('active')) {
    id = $tab.attr('id');
    return $('.nav-tabs .nav-link').filter(function() {
      return this.href.split('#').pop() === id;
    }).click();
  }
};

editSetting = function(locale, key) {
  var $scroll, $setting, callback;
  $('.f-c-simple-form-with-atoms').addClass('f-c-simple-form-with-atoms--expanded-form');
  if (key === 'label') {
    $setting = $('.f-c-js-atoms-placement-label');
  } else if (key === 'perex') {
    $setting = $('.f-c-js-atoms-placement-perex');
  } else {
    $setting = $('.f-c-js-atoms-placement-setting').filter(`[data-atom-setting='${key}']`);
  }
  if (locale) {
    $setting = $setting.filter(`[data-locale='${locale}']`);
  }
  if ($setting.length) {
    selectTab($setting);
    $scroll = $(document.documentElement);
    callback = function() {
      setTimeout((function() {
        return $setting.addClass('f-c-js-atoms-placement-setting--highlighted');
      }), 0);
      setTimeout((function() {
        return $setting.removeClass('f-c-js-atoms-placement-setting--highlighted');
      }), 300);
      if ($setting.hasClass('selectized')) {
        return $setting[0].selectize.focus();
      } else if ($setting.hasClass('redactor-source')) {
        return $R($setting[0], 'editor.startFocus');
      } else {
        return $setting.focus();
      }
    };
    if ($scroll.scrollTop() > $(window).height() / 2) {
      return $scroll.animate({
        scrollTop: 0
      }, callback);
    } else {
      return callback();
    }
  }
};

setHeight = function() {
  var $iframes, minHeight;
  $iframes = $('.f-c-simple-form-with-atoms__iframe, .f-c-merges-form-row__atoms-iframe');
  minHeight = 0;
  $iframes.each(function() {
    var height;
    if (!this.contentWindow.jQuery) {
      return;
    }
    height = this.contentWindow.jQuery('.f-c-atoms-previews').outerHeight(true);
    if (typeof height === 'number') {
      return minHeight = Math.max(minHeight, height);
    }
  });
  return $iframes.css('min-height', minHeight);
};

receiveMessage = function(e) {
  if (e.origin !== window.origin) {
    return;
  }
  switch (e.data.type) {
    case 'setHeight':
      return setHeight();
    case 'editSetting':
      return editSetting(e.data.locale, e.data.setting);
  }
};

window.addEventListener('message', receiveMessage, false);
})()
