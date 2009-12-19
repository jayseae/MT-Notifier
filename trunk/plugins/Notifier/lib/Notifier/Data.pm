# ===========================================================================
# A Movable Type plugin with subscription options for your installation
# Copyright 2003, 2004, 2005, 2006, 2007 Everitz Consulting <everitz.com>.
#
# This program may not be redistributed without permission.
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
    },
    audit => 1,
    datasource => 'notifier_data',
    primary_key => 'id',
});

1;
