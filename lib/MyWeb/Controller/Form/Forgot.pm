package MyWeb::Controller::Form::Forgot;
use Moose;
use namespace::autoclean;
use utf8;

BEGIN { extends 'Catalyst::Controller' }

sub base : Chained('/form/root') : PathPart('forgot') : CaptureArgs(0) {
}

sub forgotpass : Chained('base') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;

    my $api = $c->model('API');
    my $hm = { email => $c->req->params->{email}, };

    my $res = $api->get_result(
        $c, ['user/forgot_password/email'],
        method => 'POST',
        body   => $hm
    );

    if ( $res->{error} ) {
        $c->stash->{error}      = $res->{error};
        $c->stash->{form_error} = $res->{form_error};

        $c->detach( '/form/redirect_error', [] );
    }
    else {

        $c->detach(
            '/form/redirect_action_ok',
            [
                \'/esqueceu-enviado',
                undef,
                {},
                $c->loc('As instruções para recuperar seu acesso foram enviadas para o seu email.')
            ]
        );
        $c->detach;
    }

}

__PACKAGE__->meta->make_immutable;

1;
