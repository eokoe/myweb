package MyWeb::Controller::Admin::Users;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

sub base : Chained('/admin/base') : PathPart('users') : CaptureArgs(0) {
}

sub object : Chained('base') : PathPart('') : CaptureArgs(1) {
    my ( $self, $c, $id ) = @_;
    my $api = $c->model('API');

    $api->stash_result( $c, [ 'users', $id ], stash => 'myuser' );

}

sub show : Chained('object') PathPart('') : Args(0) {

}

sub index : Chained('base') : PathPart('') : Args(0) {
    my ( $self, $c ) = @_;

    my $api = $c->model('API');

    $api->stash_result(
        $c,
        ['users'],
        params => {
            type => 'user'
        }
    );

    $c->stash->{users} = [ sort { $b->{id} <=> $a->{id} } @{ $c->stash->{users} } ];

}

__PACKAGE__->meta->make_immutable;

1;
