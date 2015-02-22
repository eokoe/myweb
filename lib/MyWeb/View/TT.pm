package MyWeb::View::TT;
use Moose;
use namespace::autoclean;
use utf8;

extends 'Catalyst::View::TT';
use Format::Human::Bytes;
use Template::AutoFilter;
use DateTime;

use Digest::MD5 qw/md5_hex/;

__PACKAGE__->config(
    TEMPLATE_EXTENSION => '.tt',
    WRAPPER            => 'wrapper.tt',
    render_die         => 1,

    CLASS    => 'Template::AutoFilter',
    ENCODING => 'UTF8',

    PRE_PROCESS => 'macros.tt',

    INCLUDE_PATH => [ MyWeb->path_to( 'root', 'src' ) ],
    TIMER        => 0,
    render_die   => 1,
);

sub md5 {
    my ( $self, $c, $txt ) = @_;
    md5_hex($txt);
}

sub human_bytes {
    my ( $self, $c, $bytes ) = @_;

    return Format::Human::Bytes::base2( $bytes, 0 );
}

sub human_ms {
    my ( $self, $c, $secs ) = @_;

    if ( $secs < 1 ) {
        $secs = int( $secs * 100 );
        return "${secs}ms";
    }
    if    ( $secs >= 365 * 24 * 60 * 60 ) { return sprintf '%.1fy', $secs / ( 365 * 24 * 60 * 60 ) }
    elsif ( $secs >= 24 * 60 * 60 )       { return sprintf '%.1fd', $secs / ( 24 * 60 * 60 ) }
    elsif ( $secs >= 60 * 60 )            { return sprintf '%.1fh', $secs / ( 60 * 60 ) }
    elsif ( $secs >= 60 )                 { return sprintf '%.1fm', $secs / (60) }
    else                                  { return sprintf '%.1fs', $secs }

}

sub human_epoch_interval {
    my ( $self, $c, $int ) = @_;

    my $days = $int > 0 ? int( $int / 86400 ) : 0;
    $int -= $days * 86400;

    my $hours = $int > 0 ? int( $int / 3600 ) : 0;
    $int -= $hours * 3600;

    my $minutes = $int > 0 ? int( $int / 60 ) : 0;

    $int -= int( $minutes * 60 );

    my $lang = $c->get_lang;

    my $week = {
        'pt-br' => {
            'dia'  => 'dia',
            'dias' => 'dias',
        },
        'en' => {
            'dia'  => 'day',
            'dias' => 'days',
        },
        'es' => {
            'dia'  => 'día',
            'dias' => 'días',
        },
    };

    my $str = '';
    $str .= ($days) . ' ' . ( $days > 1 ? $week->{$lang}{'dias'} : $week->{$lang}{'dia'} ) . ' ' if $days;
    $str .= ($hours) . 'h '   if $hours;
    $str .= ($minutes) . 'm ' if $minutes;
    $str .= ($int) . 's '     if $int;

    return $str;
}

sub human_duration {
    my ( $self, $c, $str ) = @_;
    $str = "$str";

    $str =~ s/\..+$//;

    my @parts = split /:/, $str;

    my @fmt = qw/h m s/;

    while ( scalar @parts < 3 ) {
        unshift @parts, '00';
    }

    $str = '';
    for my $i ( 0 .. 2 ) {
        next if !$parts[$i] || $parts[$i] eq '00';

        $str .= $parts[$i] . $fmt[$i] . ' ';
    }
    $str =~ s/:$//;
    $str =~ s/\s+$//;

    return $str;
}

sub day_of_week {
    my ( $self, $c, $lang, $date ) = @_;

    my $week = {
        'pt-br' => {
            1 => 'Segunda-feira',
            2 => 'Terça-feira',
            3 => 'Quarta-feira',
            4 => 'Quinta-feira',
            5 => 'Sexta-feira',
            6 => 'Sábado',
            7 => 'Domingo'
        },
        'en' => {
            1 => 'Monday',
            2 => 'Tuesday',
            3 => 'Wednesday',
            4 => 'Thursday',
            5 => 'Friday',
            6 => 'Saturday',
            7 => 'Sunday'
        },
        'es' => {
            1 => 'Lunes',
            2 => 'Martes',
            3 => 'Miércoles',
            4 => 'Jueves',
            5 => 'Friday',
            6 => 'Sábado',
            7 => 'Domingo'
        },
    };
    $date =~ /(\d{4})-(\d{2})-(\d{2})/;

    my $dt = DateTime->new( year => $1, month => $2, day => $3 );

    return $week->{$lang}{ $dt->day_of_week };
}

sub ymd_to_dmy {
    my ( $self, $c, $str ) = @_;
    return '' unless $str;

    $str = "$str";
    $str =~ s/(\d{4})-(\d{2})-(\d{2})/$3\/$2\/$1/;

    return $str;

}

sub ymd_to_human {
    my ( $self, $c, $str ) = @_;
    return '' unless $str;

    $str = "$str";
    $str =~ s/(\d{4})-(\d{2})-(\d{2})/$3\/$2\/$1/;

    $str =~ s/T/ /;

    if ( length $str > 16 ) {

        substr( $str, 16, 3 ) = '';
    }

    return substr( $str, 0, 10 + 6 );

}

sub format_mobile_number {
    my ( $self, $c, $str ) = @_;
    return '' unless $str;

    $str =~ s/[^\d]//;

    if ( length($str) == 10 ) {
        return '(' . substr( $str, 0, 2 ) . ') ' . substr( $str, 2, 4 ) . '-' . substr( $str, 6, 4 );
    }
    elsif ( length($str) == 11 ) {
        return '(' . substr( $str, 0, 2 ) . ') ' . substr( $str, 2, 5 ) . '-' . substr( $str, 7, 4 );
    }
    return $str;

}

sub l {
    my ( $self, $c, $text, @args ) = @_;
    return unless $text;

    return $c->loc( $text, @args ) || $text;
}

sub value4human {
    my ( $self, $c, $value, $variable_type, $zero_zero ) = @_;
    return $value if $variable_type eq 'str' || $value =~ /[a-z]/;

    my $pre = '';
    my $mid = '';
    my $end = '';
    if ( $variable_type eq 'num' ) {
        return 0 if $value < 0.0001;

        if ( $value =~ /^(\d+)\.(\d+)$/ ) {
            $pre = $1;
            $end = substr( $2, 0, 2 );
            if ( $end eq '00' && $2 ) {
                $end = substr( $2, 0, 3 );
            }
            $end = '00' if $zero_zero && $end eq '';
            $end .= '0' if $zero_zero && length $end == 1;
            $mid = ',';
        }
        else {
            $pre = $value;
        }
    }
    else {
        $pre = int $value;
    }

    if ( length($pre) > 3 ) {
        $pre = reverse $pre;         # reverse the number's digits
        $pre =~ s/(\d{3})/$1\./g;    # insert dot every 3 digits, from beginning
        $pre = reverse $pre;         # Reverse the result
        $pre =~ s/^\.//;             # remove leading dot, if any
    }

    return "$pre$mid$end";
}

=head1 NAME

MyWeb::View::TT - TT View for MyWeb

=head1 DESCRIPTION

TT View for MyWeb.

=head1 SEE ALSO

L<MyWeb>

=head1 AUTHOR

renato,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
