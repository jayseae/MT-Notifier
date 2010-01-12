#!/usr/bin/perl -w

# ===========================================================================
# A Movable Type plugin with subscription options for your installation
# Copyright 2003-2010 Everitz Consulting <everitz.com>.
#
# This program may not be redistributed without permission.
# ===========================================================================

use strict;
use lib 'lib', ($ENV{MT_HOME} ? "$ENV{MT_HOME}/lib" : '../../lib');
use MT::Bootstrap;

use Getopt::Long;
use MT;
use Notifier::Queue;

my $help_message = <<HELP_TEXT;
mt-notifier-queue.cgi Usage:

mt-notifier-queue.cgi [--limit=#]
HELP_TEXT

my $help = 0;
my $limit;

GetOptions('help' => \$help, 'limit=i' => \$limit);

my $mt = MT->new()
    or die MT->errstr;

if ($help) {
    print "\n$help_message\n";
} elsif (defined($limit)) {
    Notifier::Queue::send($mt, $limit);
} else {
    Notifier::Queue::send($mt);
}

1;

__END__