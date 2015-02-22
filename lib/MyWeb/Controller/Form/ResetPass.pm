package MyWeb::Controller::Form::ResetPass;
use Moose;
use namespace::autoclean;
use utf8;

BEGIN { extends 'Catalyst::Controller' }

sub base : Chained('/form/root') : PathPart('resetpass') : CaptureArgs(0) {
}

sub resetpass : Chained('base') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;

    $c->stash->{ip_address} = $c->req->header('x-forwarded-for') || $c->req->address;
    ( $c->stash->{ip_address} ) = split /,/, $c->stash->{ip_address}, 2 if $c->stash->{ip_address} =~ /,/;

    my $api = $c->model('API');
    my $hm  = {
        ( map { $_ => $c->req->params->{$_} } qw/email secret_key password password_confirm/ ),
        ip => $c->stash->{ip_address},
    };

    my $res = $api->get_result(
        $c, ['user/forgot_password/reset_password'],
        method => 'POST',
        body   => $hm
    );

    if ( $res->{error} ) {
        $c->stash->{error}      = $res->{error};
        $c->stash->{form_error} = $res->{form_error};

        $c->detach( '/form/redirect_error', [] );
    }
    else {

        $c->detach( '/form/redirect_action_ok',
            [ \'/login', undef, {}, $c->loc('Senha alterada com sucesso. Faça o login agora!') ] );
        $c->detach;
    }

}

__PACKAGE__->meta->make_immutable;

1;
