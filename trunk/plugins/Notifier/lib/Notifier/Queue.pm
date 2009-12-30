# ===========================================================================
# A Movable Type plugin with subscription options for your installation
# Copyright 2003-2008 Everitz Consulting <everitz.com>.
#
# This program may not be redistributed without permission.
# ===========================================================================
package Notifier::Queue;

use strict;

use MT::Object;
@Notifier::Queue::ISA = qw(MT::Object);
__PACKAGE__->install_properties({
    column_defs => {
        'id' => 'integer not null auto_increment',
        'head_content' => 'string(75)',
        'head_from' => 'string(75) not null',
        'head_to' => 'string(75) not null',
        'head_subject' => 'text',
        'body' => 'text',
    },
    audit => 1,
    datasource => 'notifier_queue',
    primary_key => 'id',
});

sub class_label {
    my $app = MT->instance->app;
    my $plugin = $app->component('Notifier');
    $plugin->translate('Subscription Queue');
}

sub class_label_plural {
    my $app = MT->instance->app;
    my $plugin = $app->component('Notifier');
    $plugin->translate('Subscription Queue Records');
}

1;
