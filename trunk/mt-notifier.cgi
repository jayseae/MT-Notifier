#!/usr/bin/perl -w

# ===========================================================================
# MT-Notifier: Configure subscriptions to your blog.
# A Plugin for Movable Type
#
# Release '2.4.3'
# January 21, 2005
#
# http://jayseae.cxliv.org/notifier/
# http://www.amazon.com/o/registry/2Y29QET3Y472A/
#
# If you find the software useful or even like it, then a simple 'thank you'
# is always appreciated.  A reference back to me is even nicer.  If you find
# a way to make money from the software, do what you feel is right.
#
# Copyright 2003-2005, Chad Everett (software@jayseae.cxliv.org)
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
  require jayseae::notifier;
  my $app = jayseae::notifier->new (
    Config => $MT_DIR . 'mt.cfg',
    Directory => $MT_DIR
  ) or die jayseae::notifier->errstr;
  local $SIG{__WARN__} = sub { $app->trace ($_[0]) };
  $app->run;
};

if ($@) {
  print "Content-Type: text/html\n\n";
  print "An error occurred: $@";
}
