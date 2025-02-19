// converted via https://coffeescript.org/#try

(function () {
$(function() {
  return $('.f-c-lazy-dom').each(function() {
    var $this;
    $this = $(this);
    $this.addClass('f-c-lazy-dom--loading');
    return $.ajax({
      method: 'GET',
      url: $this.data('lazy-dom-url'),
      success: function(data) {
        $this.html(data);
        $this.trigger('folio:lazy-dom-loaded');
        return window.updateAllFolioLazyLoadInstances();
      },
      error: function(jxHr) {
        $this.html(`<p class=\"f-c-lazy-dom__title\">${$this.data('error')}</p>${jxHr.status}: ${jxHr.statusText}`);
        return $this.addClass('f-c-lazy-dom--error');
      },
      complete: function() {
        return $this.removeClass('f-c-lazy-dom--loading');
      }
    });
  });
});
})()
