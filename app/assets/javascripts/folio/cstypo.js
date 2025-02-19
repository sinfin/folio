// converted via https://coffeescript.org/#try

(function () {
$.fn.cstypo = function() {
  var regexp;
  regexp = /([szkvaiou%])/i;
  return this.each(function() {
    var $this, replaced, words;
    $this = $(this);
    words = $this.html().split(' ');
    replaced = jQuery.map(words, function(word) {
      if (word.length === 1 && word.match(regexp)) {
        return word.replace(regexp, '$1&nbsp;');
      } else {
        return word + ' ';
      }
    });
    return $this.html(replaced.join(''));
  });
};

if ($('html').prop('lang') === 'cs') {
  $(document).on('turbolinks:load', function() {
    return $('p').cstypo();
  });
}
})()
