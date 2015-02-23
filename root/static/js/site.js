var nua = navigator.userAgent;
var isAndroid = (nua.indexOf('Mozilla/5.0') > -1 && nua.indexOf('Android ') > -1 && nua.indexOf('AppleWebKit') > -1 && nua.indexOf('Chrome') === -1)
if (isAndroid) {
    $('select.form-control').removeClass('form-control').css('width', '100%')
}

$(function(){

    $(".icon-status, .tooltiped").tooltip();
    $(".do-tooltip").tooltip();

    $("#bt-cadastro").bind("click",function(e){
        var msg = "";
        if ($("#elm_name").val().split(' ').length < 2){
            msg = "Digite seu nome completo.".loc();
        }else if (!$("#elm_email").val()){
            msg = "Você precisa preencher o e-email.".loc();
        /*}else if ($("#elm_password").val().length < 5){
            msg = "A senha precisa conter no mínimo 5 caracteres.".loc();
            */
        }else if (!$("#i_agree").prop("checked")){
            msg = "Você precisa concordar com os Termos de uso para prosseguir com o cadastro.".loc();
        }
        /*else if (! ($("#elm_password").val() == $("#elm_password_confirm").val())){
            msg = "Confira as senhas!".loc();
        }
        */

        if (msg != ""){
            e.preventDefault();
            if($(".main-container .alert").length <= 0){
                $(".main-container").prepend("<div class='alert alert-danger'></div>");
            }
            $(".main-container .alert").html("<p>" + msg + "</p>");
			var timer = setTimeout(function(){
				$("#bt-cadastro").button('reset');
			},500);
            window.scrollTo(0,0);
        }
    });

    $('#elm_mobile_number').focusout(function(){
        var phone, element;
        element = $(this);
        element.unmask();
        phone = element.val().replace(/\D/g, '');
        if(phone.length > 10) {
            element.mask("(99) 99999-999?9");
        } else {
            element.mask("(99) 9999-9999?9");
        }
    }).trigger('focusout');


    $('button[data-loading-text]').click(function () {
        $(this).button('loading');
    });


    $(".datetime-utc").each(function(index,item){
        var offset = (jstz.determine().minutes() / 60);

        var date_tmp = $(this).attr('data-datetime').split("T"),
            date_date = date_tmp[0].split("-"),
            date_hours = date_tmp[1].split(":");
        var givenDate = new Date(date_date[0],(date_date[1]-1),date_date[2],date_hours[0],date_hours[1]);

        // apply offset
        var hours = givenDate.getHours();
        hours += offset;
        givenDate.setHours(hours);

        // format the date
        var localDateString = $.format.date(givenDate, 'dd/MM/yyyy HH:mm');

        $(this).text(localDateString).removeClass("hidden");
    });


});
