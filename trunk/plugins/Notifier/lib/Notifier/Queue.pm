# ===========================================================================
# A Movable Type plugin with subscription options for your installation
# Copyright 2003-2010 Everitz Consulting <everitz.com>.
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
    class_type => 'subscription.queue',
    datasource => 'notifier_queue',
    primary_key => 'id',
});

sub class_label {
    my $plugin = MT->component('Notifier');
    $plugin->translate('Subscription Queue');
}

sub class_label_plural {
    my $plugin = MT->component('Notifier');
    $plugin->translate('Subscription Queue Records');
}

sub create {
    my ($app, $hdrs, $body) = @_;
    my $q = Notifier::Queue->new;
    $q->head_from($hdrs->{'From'});
    $q->head_to($hdrs->{'To'});
    $q->head_subject($hdrs->{'Subject'});
    $q->body($body);
    $q->save or return $app->error($q->errstr);
}

sub send {
    my ($app, $limit) = @_;
    my $plugin = MT->component('Notifier');
    my (%terms, %args);
    $args{'limit'} = $limit;
    $args{'direction'} = 'ascend';
    $args{'sort'} = 'id';
    require Notifier::Queue;
    my $iter = Notifier::Queue->load_iter(\%terms, \%args);
    my %sent;
    while (my $q = $iter->()) {
        my %head = (
            'From' => $q->head_from,
            'To' => $q->head_to,
            'Subject' => $q->head_subject
        );
        require MT::Mail;
        MT::Mail->send(\%head, $q->body);
        $sent{$q->head_to} = $q;
    }
    my $count = scalar keys %sent;
    if ($count) {
        my $s = ($count == 1) ? 'Record' : 'Records';
        foreach my $sub (keys (%sent)) {
            my $q = $sent{$sub};
            $q->remove;
        }
        $app->log($plugin->translate(
            "[_1]: Sent [_2] Subscription Queue $s.", $plugin->name, $count)
        );
    }
}

1;
