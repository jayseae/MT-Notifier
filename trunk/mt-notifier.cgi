#!/usr/bin/perl -w

# ===========================================================================
# Copyright 2003-2005, Everitz Consulting (mt@everitz.com)
#
# Licensed under the Open Software License version 2.1
# ===========================================================================

use strict;

my($MT_DIR);
BEGIN {
  if ($0 =~ m!(.*[/\\])!) {
    $MT_DIR = $1;
  } else {
    $MT_DIR = './';
  }
  unshift @INC, $MT_DIR . 'lib';
  unshift @INC, $MT_DIR . 'extlib';
}

eval {
  require Everitz::Notifier;
  my $app = Everitz::Notifier->new (
    Config => $MT_DIR . 'mt.cfg',
    Directory => $MT_DIR
  ) or die Everitz::Notifier->errstr;
  local $SIG{__WARN__} = sub { $app->trace ($_[0]) };
  $app->run;
};

if ($@) {
  print "Content-Type: text/html\n\n";
  print "An error occurred: $@";
}
