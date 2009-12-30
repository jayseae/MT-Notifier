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
package Notifier::Data;

use strict;

use MT::Object;
@Notifier::Data::ISA = qw(MT::Object);
__PACKAGE__->install_properties({
    column_defs => {
        'id' => 'integer not null auto_increment',
        'blog_id' => 'integer not null default 0',
        'category_id' => 'integer not null default 0',
        'entry_id' => 'integer not null default 0',
        'email' => 'string(75) not null',
        'cipher' => 'string(75) not null',
        'record' => 'smallint not null default 0',
        'status' => 'smallint not null default 0',
        'type' => 'smallint not null default 0',
        'ip' => 'string(40) not null',
    },
    indexes => {
        blog_id => 1,
        category_id => 1,
        entry_id => 1,
        email => 1,
        cipher => 1,
        record => 1,
        status => 1,
        type => 1,
        ip => 1,
    },
    audit => 1,
    datasource => 'notifier_data',
    primary_key => 'id',
});

sub class_label {
    my $plugin = MT->component('Notifier');
    $plugin->translate('Subscription');
}

sub class_label_plural {
    my $plugin = MT->component('Notifier');
    $plugin->translate('Subscriptions');
}

1;
