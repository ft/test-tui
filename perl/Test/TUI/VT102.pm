#!/usr/bin/perl

package Test::TUI::VT102;

use strict;
use warnings;
use diagnostics;
use English '-no_match_vars';

use Term::Cap;

use Exporter;
use base qw{ Exporter };
use vars qw{ @EXPORT_OK };
@EXPORT_OK = qw{ key };

my (%keys,
    $termcap);

$termcap = Term::Cap->Tgetent({ TERM => "vt102",
                                OSPEED => 9600});

%keys = (
    F1 => 'k1',
    F2 => 'k2',
    F3 => 'k3',
    F4 => 'k4',
    F5 => 'k5',
    F6 => 'k6',
    F7 => 'k7',
    F8 => 'k8',
    F9 => 'k9',
    F10 => 'k;',
    F11 => 'F1',
    F12 => 'F2',
    F13 => 'F3',
    F14 => 'F4',
    F15 => 'F5',
    F16 => 'F6',
    F17 => 'F7',
    F18 => 'F8',
    F19 => 'F9',
    F20 => 'FA',
    F21 => 'FB',
    F22 => 'FC',
    F23 => 'FD',
    F24 => 'FE',
    Home => 'kh',
    End => '@7',
    Insert => 'kI',
    Backspace => 'bs',
    Delete => 'dc',
    Up => 'ku',
    Down => 'kd',
    Left => 'kl',
    Right => 'kr',
    PageUp => 'kP',
    PageDown => 'kN'
);

sub key {
    my ($k) = @_;
    my $tc = $keys{$k};
    my $seq = $termcap->{"_$tc"};
    # undef: Test::TUI::VT102 doesn't support $k.
    # empty: The system's `vt102' termcap doesn't support $k.
    return (defined $tc)
               ? ((defined $seq) ? $seq : q{})
               : undef;
}

1;
