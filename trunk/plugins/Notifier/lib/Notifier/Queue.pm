# ===========================================================================
# A Movable Type plugin with subscription options for your installation
# Copyright 2003, 2004, 2005, 2006, 2007 Everitz Consulting <everitz.com>.
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
    MT->translate('Subscription Queue');
}

sub class_label_plural {
    MT->translate("Subscription Queue Records");
}

1;
