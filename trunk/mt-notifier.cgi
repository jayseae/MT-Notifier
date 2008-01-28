#!/usr/bin/perl -w

# ---------------------------------------------------------------------------
# MT-Notifier: Configure subscriptions to your blog entries.
# A Plugin for Movable Type
#
# Release 1.4.1
# March 17, 2004
#
# http://www.cxliv.org/jayseae/notifier/
#
# Copyright 2003-2004, Chad Everett (plugins@cxliv.org)
#
# The program is licensed under the Open Software License version 2.0
# http://www.opensource.org/licenses/osl-2.0.php
#
# If you find the software useful or even like it, then a simple 'thank you'
# is always appreciated.  A reference back is even nicer so others can find
# out about me.  If you figure out how you can make money from the software,
# do what you feel is right.  I do have a wish list at Amazon if you are in
# need of an idea.  :)
# ---------------------------------------------------------------------------
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
