# ===========================================================================
# A Movable Type plugin with subscription options for your installation
# Copyright 2003-2008 Everitz Consulting <everitz.com>.
#
# This program is free software:  You may redistribute it and/or modify it
# it under the terms of the Artistic License version 2 as published by the
# Open Source Initiative.
#
# This program is distributed in the hope that it will be useful but does
# NOT INCLUDE ANY WARRANTY; Without even the implied warranty of FITNESS
# FOR A PARTICULAR PURPOSE.
#
# You should have received a copy of the Artistic License with this program.
# If not, see <http://www.opensource.org/licenses/artistic-license-2.0.php>.
# ===========================================================================
package Notifier::History;

use strict;

use MT::Object;
@Notifier::History::ISA = qw(MT::Object);
__PACKAGE__->install_properties({
    column_defs => {
        'id' => 'integer not null auto_increment',
        'data_id' => 'integer not null default 0',
        'entry_id' => 'integer not null default 0',
        'comment_id' => 'integer not null default 0',
    },
    indexes => {
        data_id => 1,
        entry_id => 1,
        comment_id => 1,
    },
    audit => 1,
    datasource => 'notifier_history',
    primary_key => 'id',
});

sub class_label {
    my $plugin = MT->component('Notifier');
    $plugin->translate('Subscription History');
}

sub class_label_plural {
    my $plugin = MT->component('Notifier');
    $plugin->translate('Subscription History Records');
}

1;
