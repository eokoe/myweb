package MyWeb::Controller::Admin;
use Moose;
use namespace::autoclean;
use URI;
use utf8;

BEGIN { extends 'Catalyst::Controller' }

sub base : Chained('/root') : PathPart('admin') : CaptureArgs(0) {
    my ( $self, $c ) = @_;

    if ( !$c->user || $c->user->type ne 'admin' ) {
        $c->logout;
        $c->stash->{error} = $c->loc('Sessão expirada, faça o login novamente');
        $c->detach( '/form/redirect_relogin', [] );
    }

    my $api = $c->model('API');
    $c->stash->{template_wrapper} = 'admin';
    $c->stash->{role_controller}  = 'admin';

    if ( $c->req->method eq 'POST' ) {
        return;
    }

}

__PACKAGE__->meta->make_immutable;

1;
