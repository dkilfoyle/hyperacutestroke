var datetimeInputBinding = new Shiny.InputBinding();

$.extend(datetimeInputBinding, {
  
  find: function(scope) {
    return $(scope).find('.datetimepicker');
  },
  
  getValue: function(el) {
    //var date = $(el).data("DateTimePicker").date()
    var date = $(el).text();
    return (date);
  },
  
  // value must be an unambiguous string like '2001-01-01', or a Date object.
  setValue: function(el, value) {
    console.log("setvalue");
    console.log($(el));
    $(el).data("DateTimePicker").date(value);
  },
  
  receiveMessage: function(el, data) {
    var $input = $(el).find('input');
    
    console.log("message");

    if (data.hasOwnProperty('value'))
      this.setValue(el, data.value);

    $(el).trigger('change');
  },
  
  subscribe: function(el, callback) {
    $(el).on('keyup.datetimeInputBinding input.datetimeInputBinding', function(event) {
      // Use normal debouncing policy when typing
      callback(false);
    });
    $(el).on('dp.change.datetimeInputBinding change', function(event) {
      // Send immediately when clicked
      console.log("dp.change.datetimeInputBinding");
      callback(true);
    });
  },
  
  unsubscribe: function(el) {
    $(el).off('.datetimeInputBinding');
  },
  
  getRatePolicy: function() {
    return {
      policy: 'debounce',
      delay: 250
    };
  },
  
  initialize: function(el) {
    console.log("init");
    console.log($(el));
    $(el).datetimepicker({format: 'DD/MM/YYYY HH:mm', useCurrent: true, allowInputToggle: true});
  }
   
});

Shiny.inputBindings.register(datetimeInputBinding, 'shiny.datetimeInput');