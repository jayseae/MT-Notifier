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
package Notifier::Upgrader;

use strict;

use Notifier;

sub _set_blog_id {
  require Notifier::Data;
  my $iter = Notifier::Data->load_iter();
  while (my $obj = $iter->()) {
    next if ($obj->blog_id);
    if (my $entry_id = $obj->entry_id()) {
      require MT::Entry;
      if (my $entry = MT::Entry->load($entry_id)) {
        $obj->blog_id($entry->blog_id);
      }
    }
    if (my $category_id = $obj->category_id()) {
      require MT::Category;
      if (my $category = MT::Category->load($category_id)) {
        $obj->blog_id($category->blog_id);
      }
    }
    $obj->cipher(Notifier::produce_cipher(
      'a'.$obj->email.'b'.$obj->blog_id.'c'.$obj->category_id.'d'.$obj->entry_id
    ));
    $obj->save;
  }
}

sub _set_history {
  my $set;
  require MT::Entry;
  my $iter = MT::Entry->load_iter();
  while (my $entry = $iter->()) {
    my $pinged = $entry->pinged_urls;
    $set = 0;
    $set = 1 if ($pinged && $pinged =~ m/$Notifier::SENTSRV1/);
    $set = 1 if ($pinged && $pinged =~ m/$Notifier::SENTSRV2/);
    $set = 1 if ($pinged && $pinged =~ m/$Notifier::SENTSRV3/);
    return unless ($set);
    require Notifier::Data;
    my $blog_id = $entry->blog_id;
    my $entry_id = $entry->id;
    my @subs =
      map { $_ }
      Notifier::Data->load({
        blog_id => $blog_id,
        record => Notifier::SUBSCRIBE,
        status => Notifier::RUNNING
      });
    require MT::Placement;
    my @places = MT::Placement->load({
      entry_id => $entry_id
    });
    foreach my $place (@places) {
      my @category_subs = Notifier::Data->load({
        category_id => $place->category_id,
        record => Notifier::SUBSCRIBE,
        status => Notifier::RUNNING
      });
      foreach (@category_subs) {
        push @subs, $_;
      }
    }
    my $users = scalar @subs;
    next unless ($users);
    require Notifier::History;
    foreach my $sub (@subs) {
      my $data = Notifier::Data->load({
        email => $sub->email,
        record => Notifier::SUBSCRIBE
      });
      next unless ($data);
      next if ($data->entry_id);
      my $history = Notifier::History->load({
        data_id => $data->id,
        entry_id => $entry_id
      });
      next if ($history);
      $history = Notifier::History->new;
      $history->data_id($data->id);
      $history->comment_id(0);
      $history->entry_id($entry_id);
      $history->save;
    }
  }
}

1;
