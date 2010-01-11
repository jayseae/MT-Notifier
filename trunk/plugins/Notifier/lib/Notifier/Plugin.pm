# ===========================================================================
# A Movable Type plugin with subscription options for your installation
# Copyright 2003-2009 Everitz Consulting <everitz.com>.
#
# This program may not be redistributed without permission.
# ===========================================================================
package Notifier::Plugin;

use strict;

use MT;

# callbacks

sub check_comment {
  my ($err, $obj) = @_;
  my $id = 'blog:'.$obj->blog_id;
  my $notify = 1;
  $notify = 0 unless ($obj->visible);
  my $plugin = MT::Plugin::Notifier->instance;
  $notify = 0 if ($plugin->get_config_value('blog_disabled', $id));
  require MT::Request;
  my $r = MT::Request->instance;
  $r->cache('mtn_notify_comment_'.$id, $notify);
}

sub check_entry {
  my ($err, $obj) = @_;
  my $plugin = MT::Plugin::Notifier->instance;
  return if ($plugin->get_config_value('blog_disabled', 'blog:'.$obj->blog_id));
  require MT::Entry;
  if ($obj->status == MT::Entry::RELEASE()) {
      if (my $notify = $obj->id) {
          require MT::Request;
          my $r = MT::Request->instance;
          $r->cache('mtn_notify_entry', $notify);
      }
  }
}

sub notify_comment {
    my ($err, $obj) = @_;
    my $id = 'blog:'.$obj->blog_id;
    if ($obj->is_not_junk) {
        require Notifier::Data;
        if (MT->app->param('subscribe')) {
            require Notifier;
            Notifier::create_subscription($obj->email, Notifier::Data::SUBSCRIBE(), 0, 0, $obj->entry_id)
        }
        require MT::Request;
        my $r = MT::Request->instance;
        return unless ($r->cache('mtn_notify_comment_'.$id));
        my (%terms);
        $terms{'blog_id'} = $obj->blog_id;
        $terms{'entry_id'} = $obj->entry_id;
        $terms{'record'} = Notifier::Data::SUBSCRIBE();
        $terms{'status'} = Notifier::Data::RUNNING();
        my @work_subs = Notifier::Data->load(\%terms);
        my $plugin = MT::Plugin::Notifier->instance;
        if ($plugin->get_config_value('blog_all_comments', $id)) {
            delete $terms{'entry_id'};
            my @blog_subs = Notifier::Data->load(\%terms);
            push @work_subs, @blog_subs;
            foreach my $c ($obj->entry->categories) {
                require MT::Category;
                my $cat = MT::Category->load($c);
                next unless ((ref $cat) && $cat->isa('MT::Category'));
                $terms{'category_id'} = $cat->id;
                my @cat_subs = Notifier::Data->load(\%terms);
                push @work_subs, @cat_subs;
            }
        }
        return unless (scalar @work_subs);
        Notifier::notify_users($obj, \@work_subs);
    }
}

sub notify_entry {
    my ($err, $obj) = @_;
    require MT::Request;
    my $r = MT::Request->instance;
    my $notify = $r->cache('mtn_notify_entry');
    return unless ($notify);
    require Notifier;
    Notifier::entry_notifications($notify);
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
            blog_id => $entry->blog_id,
            entry_id => $entry->id,
            is_primary => 1
        });
        $cat_id = $placement->category_id if $placement;
    }
    $cat_id;
}

sub notifier_check {
    return MT->app->param('subscribe');
}

# plugin registration

sub list_actions {
    my $app = MT->app;
    return {
        'blog' => {
            'mtn_add_subscription' => {
                label      => q(<MT_TRANS phrase="Add Subscription(s)">),
                order      => 1000,
                code       => '$Notifier::Notifier::App::_ui_sub',
                dialog     => 1,
            },
            'mtn_add_subscription_block' => {
                label      => q(<MT_TRANS phrase="Add Subscription Block(s)">),
                order      => 1100,
                code       => '$Notifier::Notifier::App::_ui_opt',
                dialog     => 1,
            },
            'mtn_view_subscription_count' => {
                label      => q(<MT_TRANS phrase="View Subscription Count(s)">),
                order      => 1200,
                code       => '$Notifier::Notifier::App::_ui_vue',
                dialog     => 1,
            },
            'mtn_write_history_records' => {
                label      => q(<MT_TRANS phrase="Write History Records">),
                order      => 1400,
                code       => '$Notifier::Notifier::App::_sub_history',
            },
          },
        'category' => {
            'mtn_add_subscription' => {
                label      => q(<MT_TRANS phrase="Add Subscription(s)">),
                order      => 1000,
                code       => '$Notifier::Notifier::App::_ui_sub',
                dialog     => 1,
            },
            'mtn_add_subscription_block' => {
                label      => q(<MT_TRANS phrase="Add Subscription Block(s)">),
                order      => 1100,
                code       => '$Notifier::Notifier::App::_ui_opt',
                dialog     => 1,
            },
            'mtn_view_subscription_count' => {
                label      => q(<MT_TRANS phrase="View Subscription Count(s)">),
                order      => 1200,
                code       => '$Notifier::Notifier::App::_ui_vue',
                dialog     => 1,
            },
        },
        'entry' => {
            'mtn_add_subscription' => {
                label      => q(<MT_TRANS phrase="Add Subscription(s)">),
                order      => 1000,
                code       => '$Notifier::Notifier::App::_ui_sub',
                dialog     => 1,
            },
            'mtn_add_subscription_block' => {
                label      => q(<MT_TRANS phrase="Add Subscription Block(s)">),
                order      => 1100,
                code       => '$Notifier::Notifier::App::_ui_opt',
                dialog     => 1,
            },
            'mtn_view_subscription_count' => {
                label      => q(<MT_TRANS phrase="View Subscription Count(s)">),
                order      => 1200,
                code       => '$Notifier::Notifier::App::_ui_vue',
                dialog     => 1,
            },
        },
        'subscription' => {
            'mtn_block_subscription' => {
                label      => q(<MT_TRANS phrase="Block Subscription(s)">),
                order      => 100,
                code       => '$Notifier::Notifier::App::_sub_block',
            },
            'mtn_clear_subscription' => {
                label      => q(<MT_TRANS phrase="Clear Subscription Block(s)">),
                order      => 200,
                code       => '$Notifier::Notifier::App::_sub_clear',
            },
            'mtn_verify_subscription' => {
                label      => q(<MT_TRANS phrase="Verify Subscription(s)">),
                order      => 300,
                code       => '$Notifier::Notifier::App::_sub_verify',
            },
        },
    }
}

sub list_filters {
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
#       clone_subs  => {
#           code           => '$Notifier::Notifier::App::clone_subs',
#           requires_login => 1,
#       },
        create_subs => {
            code           => '$Notifier::Notifier::App::create_subs',
            requires_login => 1,
        },
#       import_subs  => {
#           code           => '$Notifier::Notifier::App::import_subs',
#           requires_login => 1,
#       },
        list_subs   => {
            code           => '$Notifier::Notifier::App::list_subs',
            requires_login => 1,
        },
#       queued_subs => {
#           code           => '$Notifier::Notifier::App::queued_subs',
#           requires_login => 1,
#       },
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