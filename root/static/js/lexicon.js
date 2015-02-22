$(document).ready(function() {

    var lex={};

    $('.loc-words span[data-from]').each(function(i, a){
        var t = $(a);
        lex[t['attr']('data-from')] = t['attr']('data-to');
    });

    String.prototype.loc = function(){
        var text = lex[this+''];

        if (typeof text == "undefined"){
            text = '<span style="color:red"> ?' + this + '</span>';

            if (console){
                console.log('[% span_loc(\'' + this  + '\')|none %]');
            }
        }

        return text;
    }

});
