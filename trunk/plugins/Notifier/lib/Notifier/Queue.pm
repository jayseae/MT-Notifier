# ===========================================================================
# Copyright 2003-2005, Everitz Consulting (mt@everitz.com)
#
# Licensed under the Open Software License version 2.1
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
        'head_subject' => 'varchar(255)',
        'body' => 'text',
    },
    datasource => 'notifier_queue',
    primary_key => 'id',
});

1;
