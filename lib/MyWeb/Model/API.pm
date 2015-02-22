package MyWeb::Model::API;
use base 'Catalyst::Model';
use Moose;
use utf8;
use URI;

use URI::QueryParam;
use Encode;
use DateTime;
use JSON::MaybeXS;
use Stash::REST;
use LWP;
use Data::Dumper;

has ua => (
    is      => 'rw',
    isa     => 'Any',
    lazy    => 1,
    builder => '_build_ua',
);

has stash_rest => (
    is      => 'rw',
    isa     => 'Any',
    lazy    => 1,
    builder => '_build_stash_rest',
);

has my_config => (
    is  => 'rw',
    isa => 'HashRef',
);

sub _build_ua {
    my $self = shift;
    my $ua   = LWP::UserAgent->new;
    $ua->agent("MyWeb");
    $ua->timeout(50);
    return $ua;
}

sub initialize_after_setup {
    my ( $self, $app ) = @_;
    $app->log->debug('Initializing Model::API...');
    $self->my_config( $app->config );

    die "ERROR: please configure api_url\n" unless $app->config->{api_url};

    $app->config->{api_url} .= '/' unless $app->config->{api_url} =~ /\/$/;
}

=pod

faz uma requisicao GET para listagens e carrega o retorno na stash

=cut

sub _build_stash_rest {
    my ($self) = @_;
    my $obj = Stash::REST->new(
        do_request => sub {
            my $req = shift;

            $req->uri( $req->uri->abs( $self->my_config->{api_url} ) );

            return $self->ua->request($req);
        },
        decode_response => sub {
            my $res = shift;
            return decode_json( $res->content );
        }
    );
    $obj->add_trigger( process_response => \&_process_response );
    return $obj;
}

sub _process_response {
    my ( $class, $opt ) = @_;

    $opt->{conf}{_self}{_res} = $opt->{res};
    $opt->{conf}{_self}{_req} = $opt->{req};

    if ( $ENV{TRACE} ) {
        eval('use DDP; my $x = $opt->{req}->as_string; p $x;');
        eval('use DDP; my $x = $opt->{res}->as_string; p $x;');
    }
}

sub stash_result {
    my ( $self, $c, $endpoint, %opts ) = @_;

    $endpoint = join( '/', @$endpoint ) if ( ref $endpoint eq 'ARRAY' );

    if ( exists $opts{body} && ref $opts{body} eq 'HASH' ) {
        $opts{body} = { %{ $opts{body} } };

        while ( my ( $k, $v ) = each %{ $opts{body} } ) {
            $v = '' unless defined $v;
            $opts{body}{$k} = encode( 'UTF-8', $v );
        }

        # hash to array
        $opts{body} = [ %{ $opts{body} } ];
    }
    $opts{data} = delete $opts{body} if exists $opts{body};
    $opts{params} = [ %{ $opts{params} } ] if exists $opts{params} && ref $opts{params} eq 'HASH';

    my @headers = $self->_generate_headers($c);

    if ( exists $opts{auto_json} && $opts{auto_json} && ref $opts{data} eq 'ARRAY' ) {
        $opts{data} = encode_json { @{ $opts{data} } };
        push @headers, 'Content-Type', 'application/json';
    }

    $self->stash_rest->fixed_headers( [@headers] );

    my $method = lc( $opts{method} || 'get' );
    my $stashname = delete $opts{stash};

    $endpoint = '/' . $endpoint;
    my $submethod = "rest_$method";
    my $result = eval { $self->stash_rest->$submethod( $endpoint, %opts, skip_response_tests => 1, _self => $self ) };
    my $res    = $self->{_res};
    my $req    = $self->{_req};

    if ( $ENV{TRACE} ) {
        eval('use DDP; p $result;');
    }

    if ($@) {
        $c->stash( error => "$method $endpoint", error_content => $@ );
        $c->log->error( join ', ', 'Error on ', Dumper($req), Dumper($res), "$@" );
        $c->detach('/rest_error');
    }

    if ( $res->code == 403 ) {
        $c->logout if $res->content !~ /access denied/;
        $c->detach( '/form/redirect_relogin', [] );
    }

    if ( !exists $opts{exp_code} && $res->code !~ /^(200|201|202|204|404|410|400)$/ ) {

        $c->log->error( join ', ', 'Error on ', Dumper($req), Dumper($res), "invalid response code" );
        $c->stash(
            error         => "ERROR WHILE $method $endpoint CODE ${\$res->code}",
            error_content => $res->content,
            error_code    => $res->code,
            error_url     => $endpoint
        );
        $c->detach('/rest_error');
    }

    return ($res) if wantarray && $opts{get_as_content};
    return $res->content if $opts{get_as_content};

    return if $res->code =~ /^(410|204)$/;

    if ( $res->code =~ /^[45]/ && $opts{get_as_content} ) {
        $c->log->error( join ', ', 'Error on ', Dumper($req), Dumper($res), "invalid response code" );
    }

    $c->detach('/form/not_found') if !exists $opts{not_found_is_ok} && $res->code == 404;

    if ( exists $opts{exp_code} && $res->code !~ $opts{exp_code} ) {
        return undef if $opts{get_result};

        $c->log->error( join ', ', 'Error on ', Dumper($req), Dumper($res), "invalid response code" );

        $c->stash(
            error      => "ERROR WHILE $method $endpoint CODE ${\$res->code} ISN'T $opts{exp_code}",
            error_code => $res->code,
            error_url  => $endpoint
        );
        $c->detach('/rest_error');
    }

    # tratando caso espcial do retorno em json do bad-request
    if ( $res->code == 400 && ref $result->{form_error} eq 'HASH' ) {
        $result->{error} = $c->loc('Alguns campos não foram preenchidos corretamente.');
        $result->{error_is_form_error} = 1;
    }

    return $result if $opts{get_result};

    my $ref = $stashname ? $c->stash->{$stashname} ||= {} : $c->stash;

    # merge hashs without rewrite a new
    @{$ref}{ keys %$result } = values %$result;

    # TODO:
    #     my $tries = 15;
    #     my $res;
    #     while ($tries) {
    #         $res = $self->ua->request($req);
    #
    #         if ( $res->code == 400 && $res->{_msg} eq "Couldn't connect to server" ) {
    #             $tries--;
    #             sleep 1;
    #         }
    #         else {
    #             last;
    #         }
    #     }

    return 1;
}

sub get_result {
    my ( $self, $c, $endpoint, %opts ) = @_;

    return $self->stash_result( $c, $endpoint, %opts, get_result => 1 );
}

sub _api_key {
    my ( $self, $c ) = @_;

    if ( !$c->user ) {
        return $c->config->{api_user_api_key};
    }
    else {
        return $c->user->api_key;
    }
}

sub _generate_headers {
    my ( $self, $c ) = @_;

    my $api_key = $self->_api_key($c);

    my $real_ip = $c->stash->{ip_address};

    return (
        'X-API-Version', 1,
        'X-API-Key',     $api_key,

        ( $real_ip ? ( 'x-real-ip' => $real_ip ) : () ),
    );

}

1;
