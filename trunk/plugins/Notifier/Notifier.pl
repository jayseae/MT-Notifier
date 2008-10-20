# ===========================================================================
# Copyright 2003-2005, Everitz Consulting (mt@everitz.com)
#
# Licensed under the Open Software License version 2.1
# ===========================================================================
package MT::Plugin::Notifier;

use base qw(MT::Plugin);
use strict;

use MT;
use Notifier;

my $notifier;
my $about = {
  name => 'MT-Notifier',
  description => 'Subscription options for your Movable Type installation.',
  author_name => 'Everitz Consulting',
  author_link => 'http://www.everitz.com/',
  plugin_link => 'http://www.everitz.com/sol/notifier/index.html',
  doc_link => 'http://www.everitz.com/doc/notifier/index.html',
  version => Notifier->VERSION,
  config => \&configure_plugin_settings,
  blog_config_template => sub { $notifier->load_tmpl('settings_blog.tmpl') },
  system_config_template => sub { $notifier->load_tmpl('settings_system.tmpl') },
  settings => new MT::PluginSettings([
    ['system_address'],
    ['system_confirm', { Default => 1 }],
    ['blog_address_type', { Default => 1 }],
    ['blog_address'],
    ['blog_confirm', { Default => 1 }],
    ['blog_disabled', { Default => 0 }]
  ])
};
$notifier = MT::Plugin::Notifier->new($about);
MT->add_plugin($notifier);

use MT::Comment;
MT::Comment->add_callback('pre_save', 11, $about, \&check_comment);
MT::Comment->add_callback('post_save', 1, $about, \&notify_comment);

use MT::Entry;
MT::Entry->add_callback('pre_save', 11, $about, \&check_entry);
MT->add_callback('CMSPostEntrySave', 1, $about, \&notify_entry);

use MT::Template::Context;
MT::Template::Context->add_tag(NotifierCatID => \&notifier_category_id);

sub init_app {
  my $plugin = shift;
  my ($app) = @_;
  return unless $app->isa('MT::App::CMS');
  my @sets = qw(blog category entry);
  foreach (@sets) {
    $app->add_itemset_action({
      type  => $_,
      key   => 'mtn_add_subscriptions',
      label => 'Add Subscription(s)',
      code  => sub { notifier_start($plugin, Notifier::SUB, @_) },
    });
    $app->add_itemset_action({
      type  => $_,
      key   => 'mtn_block_notifications',
      label => 'Block Notification(s)',
      code  => sub { notifier_start($plugin, Notifier::OPT, @_) },
    });
#    $app->add_itemset_action({
#      type  => $_,
#      key   => 'mtn_send_a_notification',
#      label => 'Send a Notification',
#      code  => sub { notifier_start($plugin, Notifier::TEMP, @_) },
#    }) if ($_ eq 'entry');
    $app->add_itemset_action({
      type  => $_,
      key   => 'mtn_view_subscription_count',
      label => 'View Subscription Count',
      code  => sub { subscription_view($plugin, @_) },
    });
  }
  $app->add_methods(
    add_subscriptions => sub { subscribe_addresses($plugin, @_) },
#    send_notification => sub { send_notification($plugin, @_) },
  );
}

sub instance { $notifier }

sub configure_plugin_settings {
  my $config = {};
  if ($notifier) {
    use MT::Request;
    my ($scope) = (@_);
    $config = MT::Request->instance->cache('notifier_config_'.$scope);
    if (!$config) {
      $config = $notifier->get_config_hash($scope);
      MT::Request->instance->cache('notifier_config_'.$scope, $config);
    }
  }
  $config;
}

# user interaction

sub subscription_view {
  my $plugin = shift;
  my $app = shift;
  my @ids = $app->param('id');
  my $type = $app->param('_type');
  my $total_opts = 0;
  my $total_subs = 0;
  my @subs;
  use Notifier::Data;
  foreach my $id (@ids) {
    if ($type eq 'blog') {
      use MT::Blog;
      my $blog = MT::Blog->load($id);
      my $opts = Notifier::Data->count({ blog_id => $id, record => Notifier::OPT });
      my $subs = Notifier::Data->count({ blog_id => $id, record => Notifier::SUB });
      push @subs, { name => $blog->name, opt_count => $opts, sub_count => $subs };
      $total_opts += $opts;
      $total_subs += $subs;
    } elsif ($type eq 'category') {
      use MT::Category;
      my $category = MT::Category->load($id);
      my $opts = Notifier::Data->count({ category_id => $id, record => Notifier::OPT });
      my $subs = Notifier::Data->count({ category_id => $id, record => Notifier::SUB });
      push @subs, { name => $category->label, opt_count => $opts, sub_count => $subs };
      $total_opts += $opts;
      $total_subs += $subs;
    } elsif ($type eq 'entry') {
      use MT::Entry;
      my $entry = MT::Entry->load($id);
      my $opts = Notifier::Data->count({ entry_id => $id, record => Notifier::OPT });
      my $subs = Notifier::Data->count({ entry_id => $id, record => Notifier::SUB });
      push @subs, { name => $entry->title, opt_count => $opts, sub_count => $subs };
      $total_opts += $opts;
      $total_subs += $subs;
    }
  }
  $app->build_page($plugin->load_tmpl('subscription_view.tmpl'), {
    subs          => \@subs,
    total_opts    => $total_opts,
    total_subs    => $total_subs,
    type_blog     => ($type eq 'blog') ? 1 : 0,
    type_category => ($type eq 'category') ? 1 : 0,
    type_entry    => ($type eq 'entry') ? 1 : 0,
  });
}

sub notifier_start {
  my $plugin = shift;
  my $record = shift;
  my $app = shift;
  my @ids = $app->param('id');
  my $type = $app->param('_type');
  my $send = ($record == Notifier::TEMP) ? 1 : 0;
  $app->build_page($plugin->load_tmpl('notifier_start.tmpl'), {
    ids  => [ map { { id => $_ } } @ids ],
    record => $record,
    send => $send,
    type => $type
  });
}

sub send_notification {
  my $plugin = shift;
  my $app = shift;
  my $id = $app->param('id');
  my $return = $app->param('return_args');
  my $record = $app->param('record');
  my $type = $app->param('_type');
  Notifier::Data->remove({
    entry_id => $id,
    record => Notifier::TEMP,
    status => Notifier::RUNNING
  });
  foreach my $email (split(/\r\n/, $app->param('addresses'))) {
    Notifier::create_subscription($email, $record, 0, 0, $id, Notifier::BULK);
  }
  my @work_subs =
    map { $_ }
    Notifier::Data->load({
      entry_id => $id,
      record => Notifier::TEMP,
      status => Notifier::RUNNING
    });
  my $work_users = scalar @work_subs;
  if ($work_users) {
    use MT::Entry;
    my $entry = MT::Entry->load($id);
    Notifier::notify_users($entry, \@work_subs) if ($entry);
  }
  ## This is a hack. make_return_args seems to generate a mode of
  ## itemset_action, whereas we want list (determine what to list).
  my $mode =
    ($type eq 'blog') ? 'system_list_blogs' :
    ($type eq 'category') ? 'list_cat' :
    'list_entries';
  $return =~ s/__mode=itemset_action/__mode=$mode/;
  $app->return_args($return);
  $app->call_return;
}

sub subscribe_addresses {
  my $plugin = shift;
  my $app = shift;
  my @ids = $app->param('id');
  my $return = $app->param('return_args');
  my $record = $app->param('record');
  my $type = $app->param('_type');
  my $blog_id;
  my $category_id;
  my $entry_id;
  foreach my $id (@ids) {
    if ($type eq 'blog') {
      use MT::Blog;
      my $blog = MT::Blog->load($id);
      $blog_id = $blog->id if ($blog);
    } elsif ($type eq 'category') {
      use MT::Category;
      my $category = MT::Category->load($id);
      $blog_id = $category->blog_id if ($category);
    } elsif ($type eq 'entry') {
      use MT::Entry;
      my $entry = MT::Entry->load($id);
      $blog_id = $entry->blog_id if ($entry);
    }
    next unless ($blog_id);
    use MT::Permission;
    my $perm = MT::Permission->load({
      author_id => $app->user->id,
      blog_id => $blog_id
    });
    next unless $perm->can_post;
    foreach my $email (split(/\r\n/, $app->param('addresses'))) {
      $blog_id = ($type eq 'blog') ? $id : 0;
      $category_id = ($type eq 'category') ? $id : 0;
      $entry_id = ($type eq 'entry') ? $id : 0;
      Notifier::create_subscription($email, $record, $blog_id, $category_id, $entry_id);
    }
  }
  ## This is a hack. make_return_args seems to generate a mode of
  ## itemset_action, whereas we want list (determine what to list).
  my $mode =
    ($type eq 'blog') ? 'system_list_blogs' :
    ($type eq 'category') ? 'list_cat' :
    'list_entries';
  $return =~ s/__mode=itemset_action/__mode=$mode/;
  $app->return_args($return);
  $app->call_return;
}

# template tags

sub notifier_category_id {
  my ($ctx, $args) = @_;
  my $cat_id = '';
  if (my $cat = $ctx->stash('category') || $ctx->stash('archive_category')) {
    $cat_id = $cat->id;
  } elsif (my $entry = $ctx->stash('entry')) {
    use MT::Placement;
    my $placement = MT::Placement->load({
      entry_id => $entry->id,
      is_primary => 1
    });
    $cat_id = $placement->category_id if $placement;
  }
  $cat_id;
}

# callbacks

sub check_comment {
  my $app = MT->instance;
  my ($err, $obj) = @_;
  return unless ($obj->visible);
  my $blog_config = configure_plugin_settings('blog:'.$obj->blog_id);
  return if ($blog_config && $blog_config->{'blog_disabled'});
  my $notify = 0;
  if ($obj->id) {
    my $comment = MT::Comment->load($obj->id);
    if ($comment && !$comment->visible) {
      $notify = 1;
    }
  } else {
    $notify = 1;
  }
  if ($notify) {
    my $r = MT::Request->instance;
    $r->cache('mtn_notify_comment', 1);
  }
}

sub check_entry {
  my $app = MT->instance;
  my ($err, $obj) = @_;
  return unless ($obj->status == MT::Entry::RELEASE());
  my $blog_config = configure_plugin_settings('blog:'.$obj->blog_id);
  return if ($blog_config && $blog_config->{'blog_disabled'});
  my $notify = 0;
  if ($obj->id) {
    my $entry = MT::Entry->load($obj->id);
    if ($entry && $entry->status != MT::Entry::RELEASE()) {
      $notify = 1;
    }
  } else {
    $notify = 1;
  }
  if ($notify) {
    my $r = MT::Request->instance;
    $r->cache('mtn_notify_entry', 1);
  }
}

sub notify_comment {
  my $app = MT->instance;
  my ($err, $comment) = @_;
  if ($app->{query}->param('subscribe')) {
    my $email = $comment->email;
    my $record = Notifier::SUB;
    my $blog_id = 0;
    my $category_id = 0;
    my $entry_id = $comment->entry_id;
    Notifier::create_subscription($email, $record, $blog_id, $category_id, $entry_id);
  }
  my $r = MT::Request->instance;
  return unless ($r->cache('mtn_notify_comment'));
  my $blog_id = $comment->blog_id;
  my $entry_id = $comment->entry_id;
  use Notifier::Data;
  my @work_subs =
    map { $_ }
    Notifier::Data->load({
      entry_id => $entry_id,
      record => Notifier::SUB,
      status => Notifier::RUNNING
    });
  my $work_users = scalar @work_subs;
  return unless ($work_users);
  Notifier::notify_users($comment, \@work_subs);
}

sub notify_entry {
  my ($err, $app, $entry) = @_;
  my $r = MT::Request->instance;
  return unless ($r->cache('mtn_notify_entry'));
  my $blog_id = $entry->blog_id;
  my $entry_id = $entry->id;
  use Notifier::Data;
  my @work_subs =
    map { $_ }
    Notifier::Data->load({
      blog_id => $blog_id,
      record => Notifier::SUB,
      status => Notifier::RUNNING
    });
  use MT::Placement;
  my @places = MT::Placement->load({
    entry_id => $entry_id
  });
  foreach my $place (@places) {
    my @category_subs = Notifier::Data->load({
      category_id => $place->category_id,
      record => Notifier::SUB,
      status => Notifier::RUNNING
    });
    foreach (@category_subs) {
      push @work_subs, $_;
    }
  }
  my $work_users = scalar @work_subs;
  return unless ($work_users);
  Notifier::notify_users($entry, \@work_subs);
}

1;
