# =======================================================================
# Copyright 2003-2005, Everitz Consulting (mt@everitz.com)
#
# Non-commercial entities and non-profit organizations are granted a no-
# charge license to use the software however they like, and modify it to
# their needs, but redistribution of the software is not allowed under
# any circumstances. No support is included with this no-charge license.
# Contact us if you would like to purchase support for any product so
# licensed.
#
# Under no circumstances and under no legal theory, whether in tort
# (including negligence), contract, or otherwise, shall Everitz
# Consulting be liable to any person for any direct, indirect, special,
# incidental, or consequential damages of any character arising as a
# result of this License or the use of the Original Work including,
# without limitation, damages for loss of goodwill, work stoppage,
# computer failure or malfunction, or any and all other commercial
# damages or losses.
#
# Not to be redistributed without permssion of the copyright holder.
# =======================================================================
package MT::Plugin::Notifier;

use strict;

use MT;
use MT::Plugin;

use vars qw($VERSION);
$VERSION = '2.5.0';

my $about = {
  name => 'MT-Notifier',
  config_link => '../mt-notifier.cgi?__mode=mnu',
  description => 'Subscription options for your installation.',
  doc_link => 'http://www.everitz.com/movable_type.html'
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
      require Everitz::Notifier;
      Everitz::Notifier->notify_comment($err, $obj);
    }
  }
}

sub Notify_Entry {
  my ($err, $obj) = @_;
  if ($obj->id && $obj->status == MT::Entry::RELEASE()) {
    require MT::Blog;
    my $blog = MT::Blog->load($obj->blog_id);
    if ($blog->email_new_comments) {
      require Everitz::Notifier;
      Everitz::Notifier->notify_entry($err, $obj);
    }
  }
}

1;
