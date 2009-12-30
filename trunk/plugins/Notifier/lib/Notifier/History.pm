# ===========================================================================
# A Movable Type plugin with subscription options for your installation
# Copyright 2003-2008 Everitz Consulting <everitz.com>.
#
# This program may not be redistributed without permission.
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
    my $app = MT->instance->app;
    my $plugin = $app->component('Notifier');
    $plugin->translate('Subscription History');
}

sub class_label_plural {
    my $app = MT->instance->app;
    my $plugin = $app->component('Notifier');
    $plugin->translate('Subscription History Records');
}

1;
