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
package MT::Plugin::Notifier;

use base qw(MT::Plugin);
use strict;

use MT;
use Notifier;
use Notifier::Upgrader;

use vars qw($TAKEDOWN);
$TAKEDOWN = 0;

our $Notifier;
MT->add_plugin($Notifier = __PACKAGE__->new({
  name => 'MT-Notifier',
  description => "<MT_TRANS phrase=\"Subscription options for your Movable Type installation.\">",
  author_name => 'Everitz Consulting',
  author_link => 'http://www.everitz.com/',
  plugin_link => 'http://www.everitz.com/sol/mt-notifier/index.html',
  doc_link => 'http://www.everitz.com/sol/mt-notifier/index.html#install',
  icon => 'images/Notifier.gif',
  l10n_class => 'Notifier::L10N',
  version => Notifier->VERSION,
#
# config
#
  blog_config_template => 'settings_blog.tmpl',
  system_config_template => 'settings_system.tmpl',
  settings => new MT::PluginSettings([
    ['blog_address'],
    ['blog_address_type', { Default => 1 }],
    ['blog_confirm', { Default => 1 }],
    ['blog_disabled', { Default => 0 }],
    ['blog_queued', { Default => 0 }],
    ['blog_userlist', { Default => 1 }],
    ['system_address'],
    ['system_confirm', { Default => 1 }],
    ['system_queued', { Default => 0 }],
    ['system_userlist', { Default => 1 }],
  ]),
#
# tables
#
  object_classes => [
    'Notifier::Data',
    'Notifier::History',
    'Notifier::Queue'
  ],
  upgrade_functions => {
    'set_blog_id' => {
      code => \&Notifier::Upgrader::_set_blog_id,
      version_limit => 3.5
    },
    'set_history' => {
      code => \&Notifier::Upgrader::_set_history,
      version_limit => 3.5
    }
  },
  schema_version => Notifier->notifier_schema_version,
#
# tags
#
  template_tags => {
    'NotifierCatID' => \&notifier_category_id,
    'NotifierCheck' => \&notifier_check,
  }
}));

# callback registration

require MT::Comment;
MT::Comment->add_callback('pre_save', 10, $Notifier, \&check_comment);
MT::Comment->add_callback('post_save', 1, $Notifier, \&notify_comment);

require MT::Entry;
MT::Entry->add_callback('pre_save', 10, $Notifier, \&check_entry);
MT::Entry->add_callback('post_save', 1, $Notifier, \&notify_entry);

if (eval { require Notifier::Manager; 1 }) {
  MT->add_callback('MT::App::CMS::AppTemplateOutput', 1, $Notifier, \&Notifier::Manager::_output_itemset_action_widget);
  MT->add_callback('MT::App::CMS::AppTemplateParam.list_notification', 1, $Notifier, \&Notifier::Manager::_param_list_notification);
  MT->add_callback('MT::App::CMS::AppTemplateSource.blog-left-nav', 1, $Notifier, \&Notifier::Manager::_source_blog_left_nav);
  MT->add_callback('MT::App::CMS::AppTemplateSource.header', 1, $Notifier, \&Notifier::Manager::_source_header);
  MT->add_callback('MT::App::CMS::AppTemplateSource.list_notification', 1, $Notifier, \&Notifier::Manager::_source_list_notification);
  MT->add_callback('MT::App::CMS::AppTemplateSource.notification_actions', 1, $Notifier, \&Notifier::Manager::_source_notification_actions);
  MT->add_callback('MT::App::CMS::AppTemplateSource.notification_table', 1, $Notifier, \&Notifier::Manager::_source_notification_table);
}

# plugin initialization

sub init_app {
  my $plugin = shift;
  my ($app) = @_;
  return unless $app->isa('MT::App::CMS');
  my @sets = qw(blog category entry);
  foreach (@sets) {
    $app->add_itemset_action({
      type  => $_,
      key   => 'mtn_add_subscription',
      label => "<MT_TRANS phrase=\"Add Subscription(s)\">",
      code  => sub { notifier_start($plugin, Notifier::SUBSCRIBE, @_) }
    });
    $app->add_itemset_action({
      type  => $_,
      key   => 'mtn_add_subscription_block',
      label => "<MT_TRANS phrase=\"Add Subscription Block(s)\">",
      code  => sub { notifier_start($plugin, Notifier::OPT_OUT, @_) }
    });
    $app->add_itemset_action({
      type  => $_,
      key   => 'mtn_view_subscription_count',
      label => "<MT_TRANS phrase=\"View Subscription Count\">",
      code  => sub { subscription_view($plugin, @_) }
    });
  }
  @sets = qw(notification);
  foreach (@sets) {
    $app->add_itemset_action({
      type  => $_,
      key   => 'mtn_block_subscription',
      label => "<MT_TRANS phrase=\"Block Subscription(s)\">",
      code  => sub { block_subs($plugin, @_) }
    });
    $app->add_itemset_action({
      type  => $_,
      key   => 'mtn_clear_subscription',
      label => "<MT_TRANS phrase=\"Clear Subscription(s)\">",
      code  => sub { clear_subs($plugin, @_) }
    });
    $app->add_itemset_action({
      type  => $_,
      key   => 'mtn_verify_subscription',
      label => "<MT_TRANS phrase=\"Verify Subscription(s)\">",
      code  => sub { verify_subs($plugin, @_) }
    });
  }
  $app->add_methods(
    block_subs => sub { block_subs($plugin, @_) },
    clear_subs => sub { clear_subs($plugin, @_) },
    create_subs => sub { create_subs($plugin, @_) },
    delete_subs => sub { delete_subs($plugin, @_) },
    verify_subs => sub { verify_subs($plugin, @_) },
  );
}

# needed for xmlrpc

sub END { Notifier::entry_notifications() }

sub instance { $Notifier }

# user interaction

sub notifier_start {
  my $plugin = shift;
  my $record = shift;
  my $app = shift;
  my @ids = $app->param('id');
  my $type = $app->param('_type');
  $app->build_page($plugin->load_tmpl('notifier_start.tmpl'), {
    ids  => [ map { { id => $_ } } @ids ],
    record => $record,
    type => $type
  });
}

sub subscription_view {
  my $plugin = shift;
  my $app = shift;
  my @ids = $app->param('id');
  my $type = $app->param('_type');
  my $total_opts = 0;
  my $total_subs = 0;
  my @subs;
  require Notifier::Data;
  foreach my $id (@ids) {
    if ($type eq 'blog') {
      require MT::Blog;
      my $blog = MT::Blog->load($id);
      my $opts = Notifier::Data->count({ blog_id => $id, record => Notifier::OPT_OUT });
      my $subs = Notifier::Data->count({ blog_id => $id, record => Notifier::SUBSCRIBE });
      push @subs, { name => $blog->name, opt_count => $opts, sub_count => $subs };
      $total_opts += $opts;
      $total_subs += $subs;
    } elsif ($type eq 'category') {
      require MT::Category;
      my $category = MT::Category->load($id);
      my $opts = Notifier::Data->count({ category_id => $id, record => Notifier::OPT_OUT });
      my $subs = Notifier::Data->count({ category_id => $id, record => Notifier::SUBSCRIBE });
      push @subs, { name => $category->label, opt_count => $opts, sub_count => $subs };
      $total_opts += $opts;
      $total_subs += $subs;
    } elsif ($type eq 'entry') {
      require MT::Entry;
      my $entry = MT::Entry->load($id);
      my $opts = Notifier::Data->count({ entry_id => $id, record => Notifier::OPT_OUT });
      my $subs = Notifier::Data->count({ entry_id => $id, record => Notifier::SUBSCRIBE });
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

# automated modes

sub block_subs {
  my $plugin = shift;
  my $app = shift;
  my $return = $app->param('return_args');
  my @ids = $app->param('id');

  require Notifier::Data;
  require Notifier::Queue;

  for my $id (@ids) {
    my $iter = Notifier::Data->load_iter($id);
    while (my $obj = $iter->()) {
      my @queue = Notifier::Queue->load({ head_to => $obj->email });
      foreach my $queue (@queue) {
        $queue->remove;
      }
      $obj->record(0);
      $obj->save;
    }
  }

  unless ($return) {
    $return =
      '__mode='.$app->param('mtmode').'&amp;'.
      '_type='.$app->param('mttype').'&amp;'.
      'blog_id='.$app->param('blog_id');
  }

  $app->return_args($return);
  $app->call_return;
}

sub clear_subs {
  my $plugin = shift;
  my $app = shift;
  my $return = $app->param('return_args');
  my @ids = $app->param('id');

  require Notifier::Data;

  for my $id (@ids) {
    my $iter = Notifier::Data->load_iter($id);
    while (my $obj = $iter->()) {
      $obj->record(1);
      $obj->save;
    }
  }

  unless ($return) {
    $return =
      '__mode='.$app->param('mtmode').'&amp;'.
      '_type='.$app->param('mttype').'&amp;'.
      'blog_id='.$app->param('blog_id');
  }

  $app->return_args($return);
  $app->call_return;
}

sub create_subs {
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
      require MT::Blog;
      my $blog = MT::Blog->load($id);
      $blog_id = $blog->id if ($blog);
    } elsif ($type eq 'category') {
      require MT::Category;
      my $category = MT::Category->load($id);
      $blog_id = $category->blog_id if ($category);
    } elsif ($type eq 'entry') {
      require MT::Entry;
      my $entry = MT::Entry->load($id);
      $blog_id = $entry->blog_id if ($entry);
    }
    next unless ($blog_id);
    require MT::Permission;
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

sub delete_subs {
  my $plugin = shift;
  my $app = shift;
  my $return = $app->param('return_args');
  my @ids = $app->param('id');

  require Notifier::Data;
  require Notifier::Queue;

  for my $id (@ids) {
    my $iter = Notifier::Data->load_iter($id);
    while (my $obj = $iter->()) {
      my @queue = Notifier::Queue->load({ head_to => $obj->email });
      foreach my $queue (@queue) {
        $queue->remove;
      }
      $obj->remove;
    }
  }

  unless ($return) {
    $return =
      '__mode='.$app->param('mtmode').'&amp;'.
      '_type='.$app->param('mttype').'&amp;'.
      'blog_id='.$app->param('blog_id');
  }

  $app->return_args($return);
  $app->call_return;
}

sub verify_subs {
  my $plugin = shift;
  my $app = shift;
  my $return = $app->param('return_args');
  my @ids = $app->param('id');

  require Notifier::Data;

  for my $id (@ids) {
    my $iter = Notifier::Data->load_iter($id);
    while (my $obj = $iter->()) {
      $obj->status(1);
      $obj->save;
    }
  }

  unless ($return) {
    $return =
      '__mode='.$app->param('mtmode').'&amp;'.
      '_type='.$app->param('mttype').'&amp;'.
      'blog_id='.$app->param('blog_id');
  }

  $app->return_args($return);
  $app->call_return;
}

# callbacks

sub check_comment {
  my ($err, $obj) = @_;
  return unless ($obj->visible);
  return if ($Notifier->get_config_value('blog_disabled', 'blog:'.$obj->blog_id));
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
  my ($err, $obj) = @_;
  return unless ($obj->status == MT::Entry::RELEASE());
  return if ($Notifier->get_config_value('blog_disabled', 'blog:'.$obj->blog_id));
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
  my ($err, $obj) = @_;
  if (MT->instance->param('subscribe')) {
    my $email = $obj->email;
    my $record = Notifier::SUBSCRIBE;
    my $blog_id = 0;
    my $category_id = 0;
    my $entry_id = $obj->entry_id;
    if ($obj->is_not_junk) {
      Notifier::create_subscription($email, $record, $blog_id, $category_id, $entry_id)
    }
  }
  my $r = MT::Request->instance;
  return unless ($r->cache('mtn_notify_comment'));
  my $blog_id = $obj->blog_id;
  my $entry_id = $obj->entry_id;
  require Notifier::Data;
  my @work_subs =
    map { $_ }
    Notifier::Data->load({
      entry_id => $entry_id,
      record => Notifier::SUBSCRIBE,
      status => Notifier::RUNNING
    });
  my $work_users = scalar @work_subs;
  return unless ($work_users);
  Notifier::notify_users($obj, \@work_subs);
}

sub notify_entry {
  my ($err, $obj) = @_;
  require MT::Request;
  my $r = MT::Request->instance;
  return unless ($r->cache('mtn_notify_entry'));
  my $notify_list = $r->stash('mtn_notify_list') || {};
  $notify_list->{$obj->id} = 1;
  $r->stash('mtn_notify_list', $notify_list);
  unless ($TAKEDOWN) {
    MT->add_callback('TakeDown', 5, $Notifier, \&Notifier::entry_notifications);
    $TAKEDOWN = 1;
  }
}

# template tags

sub notifier_category_id {
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

sub notifier_check {
  return MT->instance->param('subscribe');
}

1;
