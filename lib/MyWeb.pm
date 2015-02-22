package MyWeb;
use Moose;
use CatalystX::RoleApplicator;
use namespace::autoclean;

use Catalyst::Runtime 5.80;

# Set flags and add plugins for the application.
#
# Note that ORDERING IS IMPORTANT here as plugins are initialized in order,
# therefore you almost certainly want to keep ConfigLoader at the head of the
# list if you're using it.
#
#         -Debug: activates the debug mode for very useful log messages
#   ConfigLoader: will load the configuration from a Config::General file in the
#                 application's home directory
# Static::Simple: will serve static files from the application's root
#                 directory

use Catalyst qw/
  ConfigLoader
  Static::Simple

  Assets
  StatusMessage

  Authentication

  +CatalystX::Plugin::Lexicon
  Session::DynamicExpiry
  Session

  Session::Store::File
  Session::State::Cookie
  Session::PerUser

  /;

extends 'Catalyst';

our $VERSION = '0.01';

# Configure the application.
#
# Note that settings in webmyweb.conf (or other external
# configuration file that you set up manually) take precedence
# over this when using ConfigLoader. Thus configuration
# details given here can function as a default configuration,
# with an external configuration file acting as an override for
# local deployment.

__PACKAGE__->config(
    name     => 'MyWeb',
    encoding => 'UTF8',

    # Disable deprecated behavior needed by old applications
    disable_component_resolution_regex_fallback => 1,
    enable_catalyst_header                      => 1,    # Send X-Catalyst header

    'Plugin::Assets' => {

        path        => '/static',
        output_path => 'built/',
        minify      => 1,
        stash_var   => 'assets'
    },
    'View::TT' => {
        expose_methods => [
            'human_bytes', 'human_duration', 'ymd_to_dmy', 'ymd_to_human',
            'value4human', 'day_of_week',    'human_ms',   'human_epoch_interval',
            'md5',         'l',              'format_mobile_number'
        ],
        CACHE_SIZE  => 64,
        COMPILE_DIR => ( -d '/dev/shm' ? '/dev/shm' : '/tmp' ) . '/ximu-ttcache',
      }

);

after 'setup_components' => sub {
    my $app = shift;
    for ( keys %{ $app->components } ) {
        if ( $app->components->{$_}->can('initialize_after_setup') ) {
            $app->components->{$_}->initialize_after_setup($app);
        }
    }
};

after setup_finalize => sub {
    my $app = shift;

    for ( $app->registered_plugins ) {
        if ( $_->can('initialize_after_setup') ) {
            $_->initialize_after_setup($app);
        }
    }
};

use Log::Log4perl qw(:easy);

Log::Log4perl->easy_init(
    {
        level  => $DEBUG,
        layout => '[%P] %d %m%n',
        ( $ENV{ERROR_LOG} && -e $ENV{ERROR_LOG} ? ( file => '>>' . $ENV{ERROR_LOG} ) : () ),
        'utf8' => 1
    }
);

__PACKAGE__->log( get_logger() );

__PACKAGE__->apply_request_class_roles(
    qw(
      Catalyst::TraitFor::Request::XMLHttpRequest
      )
);

# Start the application
__PACKAGE__->setup();

=encoding utf8

=head1 NAME

MyWeb - Catalyst based application

=head1 SYNOPSIS

    script/myweb_server.pl

=head1 DESCRIPTION

[enter your description here]

=head1 SEE ALSO

L<MyWeb::Controller::Root>, L<Catalyst>

=head1 AUTHOR

renato,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
