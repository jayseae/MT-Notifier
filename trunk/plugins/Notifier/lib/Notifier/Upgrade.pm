# ===========================================================================
# A Movable Type plugin with subscription options for your installation
# Copyright 2003-2010 Everitz Consulting <everitz.com>.
#
# This program may not be redistributed without permission.
# ===========================================================================
package Notifier::Upgrade;

use strict;

sub set_blog_id {
    require Notifier::Data;
    require Notifier::Util;
    my $iter = Notifier::Data->load_iter();
    while (my $obj = $iter->()) {
        next if ($obj->blog_id);
        if (my $entry_id = $obj->entry_id()) {
            require MT::Entry;
            my $entry = MT::Entry->get_by_key({
                id => $entry_id
            });
            if ($entry) {
                $obj->blog_id($entry->blog_id);
            }
        }
        if (my $category_id = $obj->category_id()) {
            require MT::Category;
            my $category = MT::Category->get_by_key({
                id => $category_id
            });
            if ($category) {
                $obj->blog_id($category->blog_id);
            }
        }
        $obj->cipher(Notifier::Util::produce_cipher(
            'a'.$obj->email.'b'.$obj->blog_id.'c'.$obj->category_id.'d'.$obj->entry_id
        ));
        $obj->save;
    }
}

sub set_blog_status {
    require MT::Blog;
    my $iter = MT::Blog->load_iter();
    while (my $obj = $iter->()) {
        my $blog_id = $obj->id;
        next unless ($blog_id);
        my $plugin = MT->component('Notifier');
        my $blog_status = $plugin->get_config_value('blog_disabled', 'blog:'.$blog_id);
        $plugin->set_config_value('blog_status', ($blog_status == 1) ? 0 : 1, 'blog:'.$blog_id);
    }
}

sub set_history {
    require MT::Entry;
    require Notifier::Data;
    require Notifier::History;
    # map entry id to hash key, blog id to hash value
    my %entries = map { $_->id => $_->blog_id } MT::Entry->load({
        # only load published entries
        status => MT::Entry::RELEASE(),
    });
    my $iter = Notifier::Data->load_iter({
        # only load subs that are verified
        record => Notifier::Data::SUBSCRIBE(),
        status => Notifier::Data::RUNNING(),
    });
    while (my $data = $iter->()) {
        foreach my $entry_id (keys %entries) {
            my %terms;
            # check entry_id, skip unless equal to sub blog_id
            next unless ($entries{$entry_id} == $data->blog_id);
            # load history terms: id, comment id (0), entry id
            $terms{'data_id'} = $data->id;
            $terms{'comment_id'} = 0;
            $terms{'entry_id'} = $entry_id;
            # check for existing history record, skip if none
            my $history = Notifier::History->load(\%terms);
            next if ($history);
            # no history? create a new record
            Notifier::History->create(\%terms);
        }
    }
}

sub set_ip {
    require Notifier::Data;
    my $iter = Notifier::Data->load_iter();
    while (my $obj = $iter->()) {
        next if ($obj->ip);
        $obj->ip('0.0.0.0');
        $obj->save;
    }
}

1;