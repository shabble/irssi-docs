#!/usr/bin/env perl

use strict;
use warnings;
use File::Spec;
use feature qw/say/;

use Data::Dumper;

my $input_file = $ARGV[0]
  // File::Spec->catfile($ENV{HOME}, qw/sources irssi-git docs signals.txt/);

sub run {

    my $data = parse_signals_doc($input_file);
    my $clean = clean_arguments($data);

    #print Dumper($clean);
    say "total signals: " . scalar keys %$clean;
    say "\"$_\"" for (sort keys %$clean);
}


sub parse_signals_doc {
    my ($input_file) = @_;
    open my $fh, '<', $input_file or die "Coudln't open $input_file: $!";

    my $data = {};

    my ($counter, $section, $file, $signal);
    my ($prelim_section);

    $counter = 0;

    while (my $line = <$fh>) {

        chomp $line;
        $counter++;

        next unless $counter > 2;
        next if $line =~ m/^\s*$/;

        if (defined $prelim_section) {
            if ($line =~ m/^(-+)$/) {
                if (length $1 == length $prelim_section) {
                    $section = $prelim_section;
                    $file = "CORE" if $section eq 'core'; # hax.
                    $prelim_section = undef;
                } else {
                    die "Something fucked up: $prelim_section not right"
                }
                next;
            } else {
                die "Error parsing: $prelim_section followed by $line";
            }
        } elsif ($line =~ m/^([\w ]+)$/) {
            $prelim_section = $1;
            next;
        }

        if ($section) {
            if ($line =~ m/^\*/) {
                next;  # comment line
            } elsif ($line =~ m/^\(/) {
                next;  #other comment
            } elsif ($line =~ m/^(.*?):\s*$/) {
                $file = $1;
                next;
            }
        }

        if ($section and $file) {
            if ($line =~ m/^\s*"([^"]+)"(?:<cmd>)?(,?.*)$/) {
                $data->{$section}->{$file}->{$1} = $2;
            } else {
                print STDERR "Failed to parse: $line\n";
            }
        }
    }
    close $fh;
    say STDERR "handled: $counter lines";
    return $data;
}

sub clean_arguments {
    my ($data) = @_;
    # collapse first 2 structures, to just signal -> args
    my $condensed = {};
    foreach my $sec (keys %$data) {
        my $section = $data->{$sec};
        foreach my $file (keys %$section) {
            my $signals = $section->{$file};
            while (my ($sigs, $args) = (each (%$signals))) {
                #print "Signal: $sigs: \n";
                $condensed->{$sigs} = process_args($args)
            }
        }
    }
    return $condensed;
}

sub process_args {
    my ($args_str) = @_;
    $args_str =~ s/^\s*,\s*//;
    $args_str =~ s/\s*$//;

    my @results;
    #print "args: $args_str\n";
    my @args = split /\s*,\s*/, $args_str;
    foreach my $arg (@args) {
        if ($arg =~ m/^(\S*?)\s+(\S*?)$/) {
            my ($type, $name) = ($1, $2);
            if ($name =~ s/^\*//) {
                $type .= ' *';
            }
            push @results, { name => $name, type => $type };
        } else {
            push @results, { type => $arg };
        }
    }
#    print Dumper(\@results);
    return \@results;
}

run();
