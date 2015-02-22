package MyWeb::Controller::User;
use Moose;
use namespace::autoclean;
use URI;
use utf8;

BEGIN { extends 'Catalyst::Controller' }

sub base : Chained('/root') : PathPart('usuario') : CaptureArgs(0) {
    my ( $self, $c ) = @_;

    if ( !$c->user || $c->user->type ne 'user' ) {
        $c->logout;
        $c->stash->{error} = $c->loc('Sessão expirada, faça o login novamente');
        $c->detach( '/form/redirect_relogin', [] );
    }

    $c->stash->{template_wrapper} = 'user';
    $c->stash->{role_controller}  = 'user';

    if ( $c->req->method eq 'POST' ) {
        return;
    }

}

__PACKAGE__->meta->make_immutable;

1;
