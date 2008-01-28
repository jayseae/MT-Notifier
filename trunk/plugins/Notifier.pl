# ===========================================================================
# MT-Notifier: Configure subscriptions to your blog.
# A Plugin for Movable Type
#
# Release '2.4.6'
# March 10, 2005
#
# http://jayseae.cxliv.org/notifier/
# http://www.amazon.com/o/registry/2Y29QET3Y472A/
#
# If you find the software useful or even like it, then a simple 'thank you'
# is always appreciated.  A reference back to me is even nicer.  If you find
# a way to make money from the software, do what you feel is right.
#
# Copyright 2003-2005, Chad Everett (software@jayseae.cxliv.org)
# Licensed under the Open Software License version 2.1
# ===========================================================================
package MT::Plugin::Notifier;

use strict;

use MT;
use MT::Plugin;

use vars qw($VERSION);
$VERSION = '2.4.6';

my $about = {
  name => 'MT-Notifier',
  config_link => '../mt-notifier.cgi?__mode=mnu',
  description => 'Subscription options for your installation.',
  doc_link => 'http://jayseae.cxliv.org/notifier/'
}; 

MT->add_plugin(new MT::Plugin($about));

MT::Comment->add_callback('pre_save', 11, $about, \&Notify_Comment);
MT::Entry->add_callback('post_save', 11, $about, \&Notify_Entry);

use MT::Template::Context;
MT::Template::Context->add_tag(NotifierCatID => \&NotifierCatID);

sub NotifierCatID {
  my ($ctx, $args) = @_;
  my $cat_id = '';
  if (my $cat = $ctx->stash('category') || $ctx->stash('archive_category')) {
    $cat_id = $cat->id;
  } elsif (my $entry = $ctx->stash('entry')) {
    require MT::Placement;
    my $placement = MT::Placement->load({
      entry_id => $entry->id,
      is_primary => 1
    });
    $cat_id = $placement->category_id if $placement;
  }
  $cat_id;
}

sub Notify_Comment {
  my ($err, $obj) = @_;
  my $notify = $obj->visible;
  if ($obj->id) {
    $notify = 0;
    require MT::Comment;
    if (my $comment = MT::Comment->load($obj->id)) {
      $notify = 1 if ($obj->visible && !$comment->visible);
    }
  }
  if ($notify) {
    require MT::Blog;
    my $blog = MT::Blog->load($obj->blog_id);
    if ($blog->email_new_comments) {
      require jayseae::notifier;
      jayseae::notifier->notify_comment($err, $obj);
    }
  }
}

sub Notify_Entry {
  my ($err, $obj) = @_;
  if ($obj->id && $obj->status == MT::Entry::RELEASE()) {
    require MT::Blog;
    my $blog = MT::Blog->load($obj->blog_id);
    if ($blog->email_new_comments) {
      require jayseae::notifier;
      jayseae::notifier->notify_entry($err, $obj);
    }
  }
}

1;
