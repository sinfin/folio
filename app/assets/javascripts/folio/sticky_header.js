//= require folio/bind_raf

// converted via https://coffeescript.org/#try

window.makeFolioStickyHeader = function(opts = {}) {
  var $window, diff, makeOnScroll, mqMobile;
  if (!(opts.selector && opts.max && opts.min && opts.mqSelector)) {
    throw 'Invalid makeFolioStickyHeader options';
  }
  opts.step || (opts.step = 10);
  diff = opts.max - opts.min;
  $window = $(window);
  mqMobile = function() {
    return $(opts.mqSelector).is(':visible');
  };
  makeOnScroll = function($window) {
    var onScroll;
    return onScroll = bindRaf(function() {
      var progress, scrollTop;
      scrollTop = $window.scrollTop();
      progress = 0;
      if (scrollTop <= 0) {
        progress = 0;
      } else if (scrollTop > diff) {
        progress = 100;
      } else {
        progress = Math.round(scrollTop / diff * opts.step) * opts.step;
      }
      return $(document.body).attr('data-affix', progress);
    });
  };
  $(document).on('turbolinks:before-render', function() {
    $window.scrollTop(0);
    return $(document.body).attr('data-affix', 0);
  });
  return $(function() {
    var didInit, initScrollHandler, scrollHandler, wasMobile;
    scrollHandler = makeOnScroll($window);
    wasMobile = mqMobile();
    didInit = false;
    initScrollHandler = function() {
      var isMobile, shouldQuit;
      isMobile = mqMobile();
      if ((isMobile === wasMobile) && didInit) {
        return;
      }
      shouldQuit = isMobile && !didInit;
      didInit = true;
      if (shouldQuit) {
        return;
      }
      if (isMobile && !wasMobile) {
        $window.off('scroll.folioStickyHeader', scrollHandler);
      } else {
        $window.on('scroll.folioStickyHeader', scrollHandler);
        scrollHandler();
      }
      return wasMobile = isMobile;
    };
    $window.on('resize orientationchange', initScrollHandler);
    return initScrollHandler();
  });
};
