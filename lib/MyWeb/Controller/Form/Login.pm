package MyWeb::Controller::Form::Login;
use Moose;
use namespace::autoclean;
use utf8;

BEGIN { extends 'Catalyst::Controller' }

sub base : Chained('/form/root') : PathPart('login') : CaptureArgs(0) {
}

sub login : Chained('base') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;

    $c->stash->{ip_address} = $c->req->header('x-forwarded-for') || $c->req->address;
    ( $c->stash->{ip_address} ) = split /,/, $c->stash->{ip_address}, 2 if $c->stash->{ip_address} =~ /,/;
    if ( $c->authenticate( $c->req->params ) ) {
        if ( $c->req->param('remember') ) {
            $c->session_time_to_live(2629743)    # 1 month
        }
        else {
            $c->session_time_to_live(14400)      # 4h
        }

        $self->after_login($c);

    }
    else {
        $c->detach( '/form/redirect_error', [] );
    }
}

sub after_login : Private {
    my ( $self, $c ) = @_;
    my $url = \'/';
    my $api = $c->model('API');

    if ( $c->user->type eq 'user' ) {
        $url = '/user/dashboard/index';
    }
    elsif ( $c->user->type eq 'admin' ) {
        $url = '/admin/dashboard/index';

    }
    else {
        $c->res->body( 'unsupported user-type:' . $c->user->type );
        $c->logout;
        $c->detach;
    }

    if ( $c->req->params->{redirect_to} && $c->req->params->{redirect_to} =~ /^\// ) {
        $url = $c->req->params->{redirect_to};
        $c->res->redirect($url);
        $c->detach;
    }

    $c->detach( '/form/redirect_action_ok', [ $url, [], {}, 'Login ok' ] );
}

__PACKAGE__->meta->make_immutable;

1;
