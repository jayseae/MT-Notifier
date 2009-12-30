# ===========================================================================
# A Movable Type plugin with subscription options for your installation
# Copyright 2003, 2004, 2005, 2006, 2007 Everitz Consulting <everitz.com>.
#
# This program may not be redistributed without permission.
# ===========================================================================
package Notifier::Plugin;

use strict;

# callbacks

sub check_comment {
  my ($err, $obj) = @_;
  return unless ($obj->visible);
  my $plugin = MT->component('Notifier');
  return if ($plugin->get_config_value('blog_disabled', 'blog:'.$obj->blog_id));
  my ($comment_id, $notify);
  if ($comment_id = $obj->id) {
    require MT::Comment;
    my $comment = MT::Comment->load($comment_id);
    if ($comment && !$comment->visible) {
      $notify = $comment_id;
    } else {
      $notify = 0;
    }
  } else {
    $notify = 1;
  }
  require MT::Request;
  my $r = MT::Request->instance;
  $r->cache('mtn_notify_comment', $notify);
}

sub check_entry {
  my ($err, $obj) = @_;
  my $plugin = MT->component('Notifier');
  return if ($plugin->get_config_value('blog_disabled', 'blog:'.$obj->blog_id));
  require MT::Entry;
  if (my $notify = $obj->id && $obj->status == MT::Entry::RELEASE()) {
    require MT::Request;
    my $r = MT::Request->instance;
    $r->cache('mtn_notify_entry', $notify);
  }
}

sub notify_comment {
  my ($err, $obj) = @_;
  if ($obj->is_not_junk) {
    if (MT->instance->param('subscribe')) {
      require Notifier;
      my $email = $obj->email;
      my $record = Notifier::SUBSCRIBE;
      my $blog_id = 0;
      my $category_id = 0;
      my $entry_id = $obj->entry_id;
      Notifier::create_subscription($email, $record, $blog_id, $category_id, $entry_id)
    }
    require MT::Request;
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
}

sub notify_entry {
  my ($err, $obj) = @_;
  require MT::Request;
  my $r = MT::Request->instance;
  return unless ($r->cache('mtn_notify_entry'));
  my $notify_list = $r->cache('mtn_notify_list') || {};
  $notify_list->{$obj->id} = 1;
  $r->cache('mtn_notify_list', $notify_list);
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
  require MT;
  return MT->instance->param('subscribe');
}

# plugin registration

sub list_actions {
  require MT;
  my $app = MT->app;
  return {
    'blog' => {
      'mtn_add_subscription' => {
        label      => q(<MT_TRANS phrase="Add Subscription(s)">),
        order      => 1000,
        code       => '$Notifier::Notifier::App::_ui_sub',
        dialog     => 1,
        condition  => sub {
          return 0 if $app->mode eq 'view';
          return ( $app->user->is_superuser() ) ? 1 : 0;
        }
      },
      'mtn_add_subscription_block' => {
        label      => q(<MT_TRANS phrase="Add Subscription Block(s)">),
        order      => 1100,
        code       => '$Notifier::Notifier::App::_ui_opt',
        dialog     => 1,
        condition  => sub {
          return 0 if $app->mode eq 'view';
          return ( $app->user->is_superuser() ) ? 1 : 0;
        }
      },
      'mtn_view_subscription_count' => {
        label      => q(<MT_TRANS phrase="View Subscription Count(s)">),
        order      => 1200,
        code       => '$Notifier::Notifier::App::_ui_vue',
        dialog     => 1,
        condition  => sub {
          return 0 if $app->mode eq 'view';
          return ( $app->user->is_superuser() ) ? 1 : 0;
        }
      },
    },
    'category' => {
      'mtn_add_subscription' => {
        label      => q(<MT_TRANS phrase="Add Subscription(s)">),
        order      => 1000,
        code       => '$Notifier::Notifier::App::_ui_sub',
        dialog     => 1,
        condition  => sub {
          return 0 if $app->mode eq 'view';
          return ( $app->user->is_superuser() ||
                   $app->permissions->can_administer_blog ||
                   $app->permissions->can_edit_notifications ) ? 1 : 0;
        }
      },
      'mtn_add_subscription_block' => {
        label      => q(<MT_TRANS phrase="Add Subscription Block(s)">),
        order      => 1100,
        code       => '$Notifier::Notifier::App::_ui_opt',
        dialog     => 1,
        condition  => sub {
          return 0 if $app->mode eq 'view';
          return ( $app->user->is_superuser() ||
                   $app->permissions->can_administer_blog ||
                   $app->permissions->can_edit_notifications ) ? 1 : 0;
        }
      },
      'mtn_view_subscription_count' => {
        label      => q(<MT_TRANS phrase="View Subscription Count(s)">),
        order      => 1200,
        code       => '$Notifier::Notifier::App::_ui_vue',
        dialog     => 1,
        condition  => sub {
          return 0 if $app->mode eq 'view';
          return ( $app->user->is_superuser() ||
                   $app->permissions->can_administer_blog ||
                   $app->permissions->can_edit_notifications ) ? 1 : 0;
        }
      },
    },
    'entry' => {
      'mtn_add_subscription' => {
        label      => q(<MT_TRANS phrase="Add Subscription(s)">),
        order      => 1000,
        code       => '$Notifier::Notifier::App::_ui_sub',
        dialog     => 1,
        condition  => sub {
          return 0 if $app->mode eq 'view';
          return ( $app->user->is_superuser() ||
                   $app->permissions->can_administer_blog ||
                   $app->permissions->can_edit_notifications ) ? 1 : 0;
        }
      },
      'mtn_add_subscription_block' => {
        label      => q(<MT_TRANS phrase="Add Subscription Block(s)">),
        order      => 1100,
        code       => '$Notifier::Notifier::App::_ui_opt',
        dialog     => 1,
        condition  => sub {
          return 0 if $app->mode eq 'view';
          return ( $app->user->is_superuser() ||
                   $app->permissions->can_administer_blog ||
                   $app->permissions->can_edit_notifications ) ? 1 : 0;
        }
      },
      'mtn_view_subscription_count' => {
        label      => q(<MT_TRANS phrase="View Subscription Count(s)">),
        order      => 1200,
        code       => '$Notifier::Notifier::App::_ui_vue',
        dialog     => 1,
        condition  => sub {
          return 0 if $app->mode eq 'view';
          return ( $app->user->is_superuser() ||
                   $app->permissions->can_administer_blog ||
                   $app->permissions->can_edit_all_posts ||
                   $app->permissions->can_edit_notifications ) ? 1 : 0;
        }
      },
    },
    'subscription' => {
      'mtn_block_subscription' => {
        label      => q(<MT_TRANS phrase="Block Subscription(s)">),
        order      => 100,
        code       => '$Notifier::Notifier::App::_sub_block',
        condition  => sub {
          return 0 if $app->mode eq 'view';
          return ( $app->user->is_superuser() ||
                   $app->permissions->can_administer_blog ||
                   $app->permissions->can_edit_all_posts ||
                   $app->permissions->can_edit_notifications ) ? 1 : 0;
        }
      },
      'mtn_clear_subscription' => {
        label      => q(<MT_TRANS phrase="Clear Subscription Block(s)">),
        order      => 200,
        code       => '$Notifier::Notifier::App::_sub_clear',
        condition  => sub {
          return 0 if $app->mode eq 'view';
          return ( $app->user->is_superuser() ||
                   $app->permissions->can_administer_blog ||
                   $app->permissions->can_edit_all_posts ||
                   $app->permissions->can_edit_notifications ) ? 1 : 0;
        }
      },
      'mtn_verify_subscription' => {
        label      => q(<MT_TRANS phrase="Verify Subscription(s)">),
        order      => 300,
        code       => '$Notifier::Notifier::App::_sub_verify',
        condition  => sub {
          return 0 if $app->mode eq 'view';
          return ( $app->user->is_superuser() ||
                   $app->permissions->can_administer_blog ||
                   $app->permissions->can_edit_all_posts ||
                   $app->permissions->can_edit_notifications ) ? 1 : 0;
        }
      },
    },
  }
}

sub list_filters {
  require MT;
  my $app = MT->app;
  return {
		subscription => {
			active => {
        label   => 'Active Subscriptions',
        order   => 100,
        handler => sub {
          my ( $terms, $args ) = @_;
            $terms->{record} = 1;
            $terms->{status} = 1;
        },
      },
			blocked => {
        label   => 'Blocked Subscriptions',
        order   => 200,
        handler => sub {
          my ( $terms, $args ) = @_;
            $terms->{record} = 0;
            $terms->{status} = 1;
        },
      },
			pending => {
        label   => 'Pending Subscriptions',
        order   => 300,
        handler => sub {
          my ( $terms, $args ) = @_;
            $terms->{status} = 0;
        },
      },
    }
  }
}

sub menus {
  require MT;
  my $app = MT->app;
  return {
    'manage:notifier' => {
      label => 'Subscriptions',
      mode  => 'list_subs',
      order => 12000,
      view => 'blog',
      condition  => sub {
        return ( $app->user->is_superuser() ||
                 $app->permissions->can_administer_blog ||
                 $app->permissions->can_edit_all_posts ||
                 $app->permissions->can_edit_notifications ) ? 1 : 0;
      }
    },
  }
}

sub methods {
  require MT;
  my $app = MT->app;
  return {
    block_subs  => {
      code           => '$Notifier::Notifier::App::block_subs',
      requires_login => 1,
    },
    clear_subs  => {
      code           => '$Notifier::Notifier::App::clear_subs',
      requires_login => 1,
    },
#    clone_subs  => {
#      code           => '$Notifier::Notifier::App::clone_subs',
#      requires_login => 1,
#    },
    create_subs => {
      code           => '$Notifier::Notifier::App::create_subs',
      requires_login => 1,
    },
#    import_subs  => {
#      code           => '$Notifier::Notifier::App::import_subs',
#      requires_login => 1,
#    },
    list_subs   => {
      code           => '$Notifier::Notifier::App::list_subs',
      requires_login => 1,
    },
#    queued_subs => {
#      code           => '$Notifier::Notifier::App::queued_subs',
#      requires_login => 1,
#    },
    verify_subs => {
      code           => '$Notifier::Notifier::App::verify_subs',
      requires_login => $app->param('return_args') ? 1 : 0,
    },
    widget_sub_blog => {
      code           => '$Notifier::Notifier::App::_widget_blog',
      requires_login => 1,
    },
    widget_sub_category => {
      code           => '$Notifier::Notifier::App::_widget_category',
      requires_login => 1,
    },
    widget_sub_entry => {
      code           => '$Notifier::Notifier::App::_widget_entry',
      requires_login => 1,
    },
  }
}

1;