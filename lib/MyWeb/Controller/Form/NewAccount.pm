package MyWeb::Controller::Form::NewAccount;
use Moose;
use namespace::autoclean;
use utf8;

BEGIN { extends 'Catalyst::Controller' }

sub base : Chained('/form/root') : PathPart('newaccount') : CaptureArgs(0) {
}

sub login : Chained('base') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;

    my $api  = $c->model('API');
    my $form = $c->model('Form');

    my $hm = { %{ $c->req->params }, role => 'user' };

    $form->only_number( $hm, 'mobile_number' );


    my $res = $api->get_result(
        $c, ['users'],
        method => 'POST',
        body   => $hm
    );

    if ( $res->{error} ) {
        $c->stash->{error}      = $res->{error};
        $c->stash->{form_error} = $res->{form_error};

        $c->detach( '/form/redirect_error', [] );
    }
    else {

        $c->detach('/form/login/login');
    }
}

__PACKAGE__->meta->make_immutable;

1;
