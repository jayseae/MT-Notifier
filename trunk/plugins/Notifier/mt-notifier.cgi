#!/usr/bin/perl -w
  
# ===========================================================================
# A Movable Type plugin with subscription options for your installation
# Copyright 2003, 2004, 2005, 2006, 2007 Everitz Consulting <everitz.com>.
#
# This program may not be redistributed without permission.
# ===========================================================================

use strict;
use lib 'lib', ($ENV{MT_HOME} ? "$ENV{MT_HOME}/lib" : '../../lib');
use MT::Bootstrap App => 'Notifier';

__END__
