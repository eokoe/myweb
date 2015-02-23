package MyWeb::Controller::Root;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

use I18N::AcceptLanguage;
has 'lang_acceptor' => (
    is      => 'rw',
    isa     => 'I18N::AcceptLanguage',
    lazy    => 1,
    default => sub { I18N::AcceptLanguage->new( defaultLanguage => 'pt-br' ) }
);
#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config( namespace => '' );

=encoding utf-8

=head1 NAME

MyWeb::Controller::Root - Root Controller for MyWeb

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=head2 index

The root page (/)

=cut

use utf8;

sub index : Path : Args(0) {
    my ( $self, $c ) = @_;

    $self->root($c);

    if ( $c->user ) {
        $c->detach('/form/login/after_login');
    }
    $c->stash->{page_name} = 'index';

}


sub root_for_ajax : Chained('/') : PathPart('') : CaptureArgs(0) {

}

sub change_lang : Chained('root') PathPart('lang') CaptureArgs(1) {
    my ( $self, $c, $lang ) = @_;
    $c->stash->{lang} = $lang;
}

sub change_lang_redir : Chained('change_lang') PathPart('') Args(0) {
    my ( $self, $c ) = @_;

    my $cur_lang = $c->stash->{lang};
    my %langs = map { $_ => 1 } split /,/, $c->config->{available_langs};
    $cur_lang = 'pt-br' unless exists $langs{$cur_lang};
    my $host = $c->req->uri->host;

    $c->response->cookies->{'cur_lang'} = {
        value   => $cur_lang,
        path    => '/',
        expires => '+3600h',
    };

    my $refer = $c->req->headers->referer;
    if ( $refer && $refer =~ /^https?:\/\/$host/ ) {
        $c->res->redirect($refer);
    }
    else {
        $c->res->redirect( $c->uri_for('/') );
    }
    $c->detach;
}

sub load_lang {
    my ( $self, $c ) = @_;

    my $cur_lang = exists $c->req->cookies->{cur_lang} ? $c->req->cookies->{cur_lang}->value : undef;

    if ( !defined $cur_lang ) {
        my $al = $c->req->headers->header('Accept-language');
        my $language = $self->lang_acceptor->accepts( $al, split /,/, $c->config->{available_langs} );

        $cur_lang = $language;

    }
    else {
        my %langs = map { $_ => 1 } split /,/, $c->config->{available_langs};
        $cur_lang = 'en' unless exists $langs{$cur_lang};
    }

    $c->set_lang($cur_lang);

    $c->response->cookies->{'cur_lang'} = {
        value   => $cur_lang,
        path    => '/',
        expires => '+3600h',
      }
      if !exists $c->req->cookies->{cur_lang} || $c->req->cookies->{cur_lang} ne $cur_lang;

}

sub root : Chained('/') : PathPart('') : CaptureArgs(0) {
    my ( $self, $c ) = @_;

    my $pinfo = $c->request->env->{PATH_INFO};

    # se for a URL do video play, nao carregar algumas coisas..
    #unless ( $pinfo =~ q!^/(usuario|alien)/user-video/mp4$! ) {
    $self->load_lang($c);

    $c->stash->{c_req_path}      = $c->req->path;
    $c->stash->{c_req_authority} = $c->req->uri->scheme . '://' . $c->req->uri->authority;

    unless ($c->req->match eq '/user/index/render'){
        $c->load_status_msgs;
        my $status_msg = $c->stash->{status_msg};
        my $error_msg  = $c->stash->{error_msg};

        @{ $c->stash }{ keys %$status_msg } = values %$status_msg if ref $status_msg eq 'HASH';
        @{ $c->stash }{ keys %$error_msg }  = values %$error_msg  if ref $error_msg eq 'HASH';

    }

    my ( $class, $action ) = ( $c->action->class, $c->action->name );
    $class =~ s/^MyWeb::Controller:://;
    $class =~ s/::/-/g;

    $c->stash->{body_class} = lc "$class $class-$action";

    #}

    if ( $c->user ) {

        if ( $c->user->type && $c->user->type eq 'user' ) {
            $c->stash->{role_controller} = 'user';
        }
        elsif ( $c->user->auth_realm eq 'admin' ) {
            $c->stash->{role_controller} = 'admin';
        }
    }

    $c->stash->{ip_address} = $c->req->header('x-forwarded-for') || $c->req->address;
    ( $c->stash->{ip_address} ) = split /,/, $c->stash->{ip_address}, 2 if $c->stash->{ip_address} =~ /,/;

}

sub default : Path {
    my ( $self, $c ) = @_;

    $self->root($c);
    my $maybe_view = join '/', @{ $c->req->arguments };

    if ( $maybe_view =~ /^(cadastro|login)$/ && $c->user ) {

        if ( !exists $c->req->params->{redirect_to} && !exists $c->req->params->{mid} ) {
            $c->res->redirect('/');

            $c->detach;
        }
        else {
            $c->logout;
        }
    }

    if ( $c->user && $c->user->type eq 'user' ) {
        $c->controller('User')->base($c);
    }

    my $output;
    eval {
        $c->stash->{body_class} .= ' ' . $maybe_view;
        $c->stash->{body_class} =~ s/\//-/g;
        $output = $c->view('TT')->render( $c, "auto/$maybe_view.tt", $c->stash );
    };
    if ( $@ && $@ =~ /not found$/ ) {
        $c->stash->{template} = 'not_found.tt';
        $c->response->status(404);
    }
    elsif ( !$@ ) {
        $c->response->body($output);
    }
    else {
        die $@;
    }
}

sub rest_error : Private {
    my ( $self, $c ) = @_;

    $c->res->status(500);
    $c->stash->{template} = 'rest_error.tt';

    if ( $c->request->is_xhr ) {
        $c->detach( '/form/as_json', [ { error => $c->stash->{error} } ] );
    }
    else {
        $c->detach();
    }

}

=head2 end

Attempt to render a view, if needed.

=cut

sub end : ActionClass('RenderView') {
    my ( $self, $c ) = @_;

    if ( $c->debug && exists $ENV{DUMP_STASH} ) {
        my $x = $c->stash;
        eval('use DDP; p $x;');
    }
}

=head1 AUTHOR

renato,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
