// converted via https://coffeescript.org/#try
$(function() {
  var $layoutButtons, receiveMessage, sendMessage;
  $layoutButtons = $('.f-c-atoms-layout-switch__button');
  if ($layoutButtons.length === 0) {
    return;
  }
  sendMessage = function() {
    var msg;
    msg = {
      type: 'setMediaQuery'
    };
    if ($layoutButtons.is(':visible')) {
      msg.width = $(window).width();
    }
    return $('.f-c-simple-form-with-atoms__iframe').each(function() {
      return this.contentWindow.postMessage(msg, window.origin);
    });
  };
  $layoutButtons.on('click', function(e) {
    var $button, layout;
    e.preventDefault();
    $button = $(this);
    $button.siblings().removeClass('f-c-atoms-layout-switch__button--active');
    $button.addClass('f-c-atoms-layout-switch__button--active');
    layout = $button.data('layout');
    Cookies.set('f_c_atoms_layout_switch', layout);
    $button.closest('.f-c-simple-form-with-atoms').removeClass('f-c-simple-form-with-atoms--layout-vertical f-c-simple-form-with-atoms--layout-horizontal').addClass(`f-c-simple-form-with-atoms--layout-${layout}`);
    return sendMessage();
  });
  sendMessage();
  $(window).on('resize orientationchange', function() {
    return sendMessage();
  });
  receiveMessage = function(e) {
    if (e.origin !== window.origin) {
      return;
    }
    switch (e.data.type) {
      case 'requestMediaQuery':
        return sendMessage();
    }
  };
  return window.addEventListener('message', receiveMessage, false);
});
