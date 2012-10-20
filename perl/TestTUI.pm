#!/usr/bin/perl

# Driver for testing Text-User-Interfaces (e.g. curses applications).

use strict;
use warnings;
use diagnostics;
use English '-no_match_vars';

use Data::Dumper;
use IO::Pty::Easy;
use Term::VT102;
use Time::HiRes qw{ gettimeofday };
use POSIX qw{ floor :sys_wait_h };

use Exporter;
use base qw{ Exporter };
use vars qw{ @EXPORT_OK };
@EXPORT_OK = qw{ application_under_test
                 run_test_script
                 test_script
                 expect_wait
                 testtuiset };

my (@application_under_test,
    @script,
    %setters,
    $pty,
    $terminal,
    $write_timeout,
    $read_timeout,
    $until_timeout,
    $until_fraction,
    $exit_timeout,
    $expect_wait,
    $trace,
    $child_pid,
    $child_status);

sub REAPER {
    my $pid;

    while (($pid = waitpid(-1, WNOHANG)) > 0) {
        if ($pid == $child_pid) {
            $child_status = $CHILD_ERROR;
        }
    }
    $SIG{CHLD} = \&REAPER;
}
$SIG{CHLD} = \&REAPER;

$expect_wait = 200;
$until_timeout = 1000;
$until_fraction = $until_timeout / 10;
$read_timeout = 2 / 1000;
$write_timeout = 500 / 1000;
$exit_timeout = 5e3;
$trace = 0;

sub application_under_test {
    @application_under_test = @_;
}

sub test_script {
    my ($script) = @_;
    @script = @{ $script };
}

sub testtuiset {
    my ($data) = @_;

    if (ref $data ne q{HASH}) {
        print "testtuiset: argument needs to be a hashref.\n";
        clean_exit(42);
    }

    foreach my $key (sort keys %{ $data }) {
        if (defined $setters{$key}) {
            $setters{$key}->($data->{$key});
        } else {
            print "testtuiset: Unknown parameter `$key'.\n";
            clean_exit(42);
        }
    }
}

%setters = (
    expect_wait => sub { $expect_wait = $_[0] },
    until_timeout => sub { $until_timeout = $_[0] },
    until_fraction => sub { $until_fraction = $_[0] },
    write_timeout => sub { $write_timeout = $_[0] / 1000 },
    read_timeout => sub { $read_timeout = $_[0] / 1000 },
    trace => sub { $trace = ($_[0] != 0) ? 1 : 0 }
);

sub print_if {
    my ($cond, @rest) = @_;
    print @rest if ($cond);
}

sub trace {
    print_if($trace, @_);
}

sub use_if_defined {
    my ($what, $else) = @_;

    return $what if (defined $what);
    return $else;
}

sub tt_index {
    my ($idx) = @_;
    print "That is entry #$idx in the test-script (index starting at 0).\n";
}

sub tt_dump {
    my ($head, $thing) = @_;
    print "$head\n";
    print "----------\n";
    print Dumper($thing);
    print "----------\n";
}

sub read_a_bit {
    my $data = $pty->read($read_timeout);
    $terminal->process($data);
}

sub tt_wait {
    my ($duration) = @_;
    my $timestamp = get_msec_timestamp();

    while (!timeouted($duration, $timestamp)) {
        read_a_bit();
    }
}

sub get_msec_timestamp {
    my ($sec, $usec) = gettimeofday();
    return ($sec * 1000) + ($usec / 1000);
}

sub timeouted {
    my ($timeout, $timestamp) = @_;
    my $new = get_msec_timestamp();
    return $new > ($timestamp + $timeout);
}

sub unexpected_death {
    my ($thing, $num) = @_;

    tt_dump("Application under test:", \@application_under_test);
    tt_dump(
        "...died unexpectedly before the following could be handled:", $thing);
    print "That is entry #$num in the test-script (index starting at 0).\n";
    clean_exit(23);
}

sub broken_test_script {
    my ($thing, $num) = @_;
    tt_dump("Unknown/Disallowed entry in test-script:", $thing);
    tt_index($num);
    print "...giving up.\n";
    clean_exit(42);
}

sub pty_write {
    my ($string) = @_;
    my ($rc);

    trace("stdin> [$string]\n");
    $rc = $pty->write($string, $write_timeout);
    if (!defined $rc) {
        print "Write to application-under-test timeouted ($write_timeout).\n";
        clean_exit(11);
    } elsif ($rc == 0) {
        print "Write to application-under-test failed.\n";
        clean_exit(12);
    }

    return $rc;
}

sub check {
    my ($condition) = @_;
    my ($expect, $actual, $type, $line, $start, $end);

    if (!defined $condition->{line}) {
        tt_dump("Condition without `line' definition:", $condition);
        clean_exit(42);
    }

    $line = $condition->{line};
    $start = use_if_defined($condition->{column}, 1);
    if (defined $condition->{length}) {
        $end = $start + $condition->{length} - 1;
    } else {
        $end = use_if_defined($condition->{end}, $terminal->cols());
    }

    TYPES: foreach my $iter (qw{ string regexp }) {
        if (defined $condition->{$iter}) {
            $expect = $condition->{$iter};
            $type = $iter;
            last TYPES;
        }
    }

    if (!defined $expect) {
        tt_dump("Unknown condition in:", $condition);
        clean_exit(42);
    }

    $actual = $terminal->row_plaintext($line, $start, $end);

    trace("   -!- check: expect($expect), actual($actual)\n");
    if ($type eq q{regexp}) {
        return $actual =~ m/$expect/;
    } else {
        return $actual eq $expect;
    }
}

sub fail {
    my ($who, $rc, $condition) = @_;
    tt_dump("test failed in `$who' step:", $condition);
    for my $i (1 .. $terminal->rows()) {
        print $terminal->row_plaintext($i), "\n";
    }
    clean_exit($rc);
}

sub deal_expect {
    my ($data) = @_;
    my ($condition, $wait);

    $condition = $data->{expect};
    $wait = (defined $data->{wait}) ? $data->{wait} : $expect_wait;

    tt_wait($wait);
    if (!check($condition)) {
        fail(q{expect}, 1, $condition);
    }
}

sub deal_until {
    my ($data) = @_;
    my ($condition, $timeout, $timestamp);

    $timestamp = get_msec_timestamp();
    $condition = $data->{until};
    $timeout = (defined $data->{timeout}) ? $data->{timeout} : $until_timeout;
    do {
        my ($data);
        if (timeouted($timeout, $timestamp)) {
            fail(q{until}, 2, $condition);
        }
        tt_wait($until_fraction);
    } while (!check($condition));
}

sub deal_programexit {
    my ($code) = @_;
    my $timestamp = get_msec_timestamp();

    while (!defined $child_status) {
        if (timeouted($exit_timeout, $timestamp)) {
            fail(q{programexit}, 2, $code);
        }
    }

    trace("   -!- expected return-code: $code, actual: $child_status\n");
    if ($child_status != $code) {
        fail(q{programexit}, 1, $code);
    }
}

sub deal {
    my ($thing, $num) = @_;

    if (ref $thing eq q{}) {
        pty_write($thing);
    } elsif (ref $thing eq q{HASH}) {
        if (defined $thing->{until}) {
            deal_until($thing);
        } elsif (defined $thing->{expect}) {
            deal_expect($thing);
        } elsif (defined $thing->{wait}) {
            trace("   -!- wait " . $thing->{wait} . "\n");
            tt_wait($thing->{wait});
        } elsif (defined $thing->{programexit}) {
            trace("   -!- wait-for-exit ($child_pid)\n");
            deal_programexit($thing->{programexit});
        } else {
            broken_test_script($thing, $num);
        }
    } else {
        broken_test_script($thing, $num);
    }
}

sub clean_exit {
    my ($rc) = @_;
    $pty->close() if (defined $pty);
    exit $rc;
}

sub run_test_script {
    my ($i);
    $ENV{TERM} = q{vt102};
    $terminal = Term::VT102->new(cols => 80,
                                 rows => 24);
    $pty = IO::Pty::Easy->new(handle_pty_size => 1,
                              raw => 0);
    $pty->spawn(@application_under_test);
    $child_pid = $pty->pid();
    $i = 0;
    foreach my $thing (@script) {
        unexpected_death($thing, $i) unless ($pty->is_active
                                             || defined $thing->{programexit});
        deal($thing, $i);
        $i++;
    }
    # \o/ ...we made it!
    clean_exit(0);
}

1;
