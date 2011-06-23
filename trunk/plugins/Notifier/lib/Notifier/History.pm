# ===========================================================================
# A Movable Type plugin with subscription options for your installation
# Copyright 2003-2011 Everitz Consulting <everitz.com>.
#
# This program is distributed in the hope that it will be useful but does
# NOT INCLUDE ANY WARRANTY; Without even the implied warranty of FITNESS
# FOR A PARTICULAR PURPOSE.
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
        'data_id' => 'integer not null',
        'entry_id' => 'integer not null',
        'comment_id' => 'integer not null',
    },
    defaults => {
        data_id => 0,
        entry_id => 0,
        comment_id => 0,
    },
    indexes => {
        data_id => 1,
        entry_id => 1,
        comment_id => 1,
    },
    audit => 1,
    class_type => 'subscription.history',
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

sub create {
    my ($app, $cols) = @_;
    my $h = Notifier::History->new;
    $h->set_values($cols);
    $h->save or return $app->error($h->errstr);
}

1;
