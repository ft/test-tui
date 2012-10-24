#!/usr/bin/perl

package Test::TUI::Inspect;

use strict;
use warnings;
use diagnostics;
use English '-no_match_vars';

use Test::TUI;

use Exporter;
use base qw{ Exporter };
use vars qw{ @EXPORT_OK };
@EXPORT_OK = qw{ terminal_line
                 terminal_plain_line
                 terminal_status };

sub terminal_line {
    my $terminal = Test::TUI::__get_terminal();
    return $terminal->row_text(@_);
}

sub terminal_plain_line {
    my $terminal = Test::TUI::__get_terminal();
    return $terminal->row_plaintext(@_);
}

sub terminal_status {
    my $terminal = Test::TUI::__get_terminal();
    my $pty = Test::TUI::__get_pty();
    return { state => 'inactive' } if (!defined $pty || !$pty->is_active());
    return { state => 'active',
             lines => $terminal->rows(),
             columns => $terminal->cols(),
             cursor_x => $terminal->x(),
             cursor_y => $terminal->y(),
             cursor_state => $terminal->cursor() };
}

1;
