// converted via https://coffeescript.org/#try
$(document).on('click', '[data-change-value]', function(e) {
  var $targets, $this, target;
  $this = $(this);
  target = $this.data('target');
  if (target === '*') {
    $targets = $this.closest('form').find('input, select');
  } else {
    $targets = $(target);
  }
  $targets.val($this.data('change-value'));
  if ($this.data('change-value-submit') != null) {
    return $this.closest('form').submit();
  }
});
