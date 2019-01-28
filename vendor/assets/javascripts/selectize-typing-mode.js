// https://github.com/selectize/selectize.js/issues/748#issuecomment-310153509

/**
 * Typing mode plugin by Luan Fonseca
 * December 2014
 * https://github.com/brianreavis/selectize.js/blob/5d81539d677e8c2411215a1fb81789a8006c77f2/src/plugins/typing_mode/plugin.js#L1
 *
 * Modified by Jess Mann
 * June 2017
 *
 * Selectize version 0.12.4
 */
Selectize.define('typing_mode', function(options) {
  var self = this;

  this.setup = (function() {
    var original = self.setup;
    self.updating = false;

    return function() {
      original.apply(this, arguments);

      this.on('dropdown_open', function() {
        self.previousValue = self.getValue();
        var option = self.getOption(self.previousValue);

        /**
         * Two styles:
         *     1) usePlaceholder gives an immediately blank field to type into
         *     2) default shows the text and allows user to edit last selection
         */
        if (self.settings.usePlaceholder) {
          self.$control_input.attr('placeholder', option.text().trim());
        } else {
          self.$control_input.attr('value', option.text().trim());
        }

        self.$control_input.css({
          opacity: '1',
          width: '100%',
          position: 'relative'
        });
        self.$control.find('.item').hide();

        self.items = [];
        self.setCaret(0);
      });

      this.$control_input.on('blur', function() {
        self.$control.find('.item').show();

        /**
         * I played with testing self.settings.allowEmptyOption
         *     before reverting to the previous value,
         *     but that doesn't seem to be intuitive behavior.
         *
         * Use the current value, or, if empty, set to the previous value
         */
        var value = self.getValue() || self.previousValue;

        /**
         * Avoid infinite loop. self.setValue calls blur() again
         *     even if we pass true to the second param.
         */
        if (self.updating)
          return;

        self.updating = true;
        self.setValue(value);
        self.updating = false;
      });
    };
  })();
});
