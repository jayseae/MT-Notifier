# ===========================================================================
# A Movable Type plugin with subscription options for your installation
# Copyright 2003-2009 Everitz Consulting <everitz.com>.
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
    my $plugin = MT::Plugin::Notifier->instance;
    $plugin->translate('Subscription Queue');
}

sub class_label_plural {
    my $plugin = MT::Plugin::Notifier->instance;
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
    my $plugin = MT::Plugin::Notifier->instance;
    my (%terms, %args);
    $args{'limit'} = $limit;
    $args{'direction'} = 'ascend';
    $args{'sort'} = 'id';
    require Notifier::Queue;
    my $iter = Notifier::Queue->load_iter(\%terms, \%args);
    my $count = 0;
    while (my $q = $iter->()) {
        my %head = (
            'From' => $q->head_from,
            'To' => $q->head_to,
            'Subject' => $q->head_subject
        );
        require MT::Mail;
        MT::Mail->send(\%head, $q->body);
        $q->remove;
        $count++;
    }
    my $s = ($count == 1) ? 'Record' : 'Records';
    $app->log($plugin->translate(
        "[_1]: Sent [_2] Subscription Queue $s.", $plugin->name, $count)
    );
}

1;
