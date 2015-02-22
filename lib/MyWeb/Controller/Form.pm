package MyWeb::Controller::Form;
use Moose;
use URI;
use URI::QueryParam;
use JSON;
use utf8;
use strict;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

sub root : Chained('/root') : PathPart('form') : CaptureArgs(0) {
}

sub redirect_action_ok : Private {
    my ( $self, $c, $path, $cap, $params, $msg, %args ) = @_;

    my $mid = $c->set_status_msg( {
        %args, status_msg => $msg
    });


    die "You should not use capture if path is a ref."
        if ref $path eq 'REF' && defined $cap;

    my $uri;

    if (ref $path eq ''){
        $uri = $c->uri_for_action(
            $path,
            $cap,
            {
                ( ref $params eq 'HASH' ? %$params : () ),
                mid => $mid
            }
        );
        die "uri not found" unless $uri;
    }else{
        $uri = URI->new($$path);

        if ( ref $params eq 'HASH' ){
            while (my ($k, $v) = each %$params){
                $uri->query_param( $k, $v );
            }
        }
        $uri->query_param( 'mid', $mid );
    }

    $c->res->redirect($uri);

}

sub as_json : Private {
    my ( $self, $c, $data ) = @_;

    $c->res->header( 'Content-type', 'application/json; charset=utf-8' );

    if ( ref $data eq 'HASH' && exists $data->{error} ) {
        $c->response->status(400);
    }

    $c->res->body( encode_json($data) );

}

sub not_found : Private {
    my ( $self, $c ) = @_;

    $c->response->status(404);

    if ( $c->request->is_xhr ) {
        $c->detach( '/form/as_json', [ { error => 'not found' } ] );
    }
    else {

        $c->stash->{template} = 'not_found.tt';
        $c->detach();
    }
}

sub redirect_error : Private {
    my ( $self, $c, %args ) = @_;

    my $host  = $c->req->uri->host;
    my $refer = $c->req->headers->referer;

    if ( !$refer || $refer !~ /^https?:\/\/$host/i ) {
        $refer = '/erro';
    }

    # opa, o cara nao ta logado, VAI PRA HOME!
    # se tirar, redirect-loop acontece!

    $refer = '/erro'
      if !$c->user && $refer !~ /(login|cadastro|trocar-senha|esqueceu|parceiro)(\?|$)/ && $refer !~ /\/acesso/;

    my $mid = $c->set_error_msg(
        {
            #%args,
            form_error => $c->stash->{form_error},
            body       => $c->req->params,
            error_msg  => $c->stash->{error},
        }
    );

    my $uri = URI->new($refer);
    $uri->query_param( 'mid', $mid );

    if ( $c->request->is_xhr ) {
        $c->detach( '/form/as_json', [ { redirect => $uri->as_string, error => 'redirect_error' } ] );
    }
    else {
        $c->res->redirect( $uri->as_string );
    }

}

sub redirect_relogin : Private {
    my ( $self, $c, %args ) = @_;

    my $host  = $c->req->uri->host;
    my $port  = $c->req->uri->port == 80 ? '' : ":" . $c->req->uri->port;
    my $refer = $c->req->headers->referer;

    if ( !$refer || $refer !~ /^https?:\/\/$host$port/i ) {
        $refer = '/erro';
    }
    if ( $c->req->method eq 'GET' ) {
        $refer = $c->req->uri->as_string;
    }

    my $mid = $c->set_error_msg(
        {
            form_error => {},
            body       => {},
            error_msg  => $c->loc('Sessão expirada. Faça o login novamente.'),
        }
    );

    $refer =~ s/^https?:\/\/$host$port//g;

    my $uri = URI->new('/login');
    $uri->query_param( 'mid',         $mid );
    $uri->query_param( 'redirect_to', $refer );

    if ( $c->request->is_xhr ) {
        $c->detach( '/form/as_json', [ { redirect => $uri->as_string, error => 'redirect_relogin' } ] );
    }
    else {
        $c->res->redirect( $uri->as_string );
    }

}

__PACKAGE__->meta->make_immutable;

1;
