// converted via https://coffeescript.org/#try
window.bindFolioConsoleClipboardCopyIn = function($wrap) {
  return window.bindFolioConsoleClipboardCopy($wrap.find('.f-c-clipboard-copy'));
};

window.bindFolioConsoleClipboardCopy = function($elements) {
  return $elements.each(function() {
    var clipboard;
    clipboard = new ClipboardJS(this);
    clipboard.on('success', function(e) {
      var $trigger;
      $trigger = $(e.trigger);
      $trigger.addClass('f-c-clipboard-copy--copied');
      return setTimeout((function() {
        return $trigger.removeClass('f-c-clipboard-copy--copied');
      }), 1000);
    });
    return $(this).data('clipboard', clipboard);
  });
};

window.unbindFolioConsoleClipboardCopy = function($elements) {
  return $elements.each(function() {
    var $this, clipboard;
    $this = $(this);
    clipboard = $this.data('clipboard');
    if (clipboard) {
      clipboard.destroy();
      return $this.data('clipboard', null);
    }
  });
};

$(function() {
  if ($('.f-c-clipboard-copy').length) {
    return window.bindFolioConsoleClipboardCopy($('.f-c-clipboard-copy'));
  }
});
