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
package Notifier::Plugin;

use base qw(MT::App);
use strict;

# methods

sub block_subs {
    my $app = shift;
    require Notifier::Data;
    my $return = $app->param('return_args');
    my @ids = $app->param('id');
    for my $id (@ids) {
        my $obj = Notifier::Data->get_by_key({
            id => $id
        });
        if ($obj) {
            require Notifier::Queue;
            my @queue = Notifier::Queue->load({
                head_to => $obj->email
            });
            foreach my $queue (@queue) {
                $queue->remove;
            }
            $obj->record(0);
            $obj->save;
        }
    }
    $app->return_args($return);
    $app->call_return;
}

sub clear_subs {
    my $app = shift;
    require Notifier::Data;
    my $return = $app->param('return_args');
    my @ids = $app->param('id');
    for my $id (@ids) {
        my $obj = Notifier::Data->get_by_key({
            id => $id
        });
        if ($obj) {
            $obj->record(1);
            $obj->save;
        }
    }
    $app->return_args($return);
    $app->call_return;
}

sub create_subs {
    my $app = shift;
    my $record = $app->param('record');
    my $blog_id;
    if ($blog_id = $app->param('blog_id')) {
        my $id = $app->param('id');
        my $email = $app->param('email');
        my $return = $app->param('return_args');
        my $obj;
        if ($id) {
            require Notifier::Data;
            $obj = Notifier::Data->get_by_key({
                id => $id
            });
        }
        if ($obj) {
            $obj->email($email);
            require Notifier::Util;
            $obj->cipher(Notifier::Util::produce_cipher(
                'a'.$email.'b'.$blog_id.'c'.'0'.'d'.'0'
            ));
            $obj->save;
        } else {
            Notifier::create_subscription($email, $record, $blog_id, 0, 0);
        }
        $app->return_args($return);
        $app->call_return;
    } else {
        my $type = $app->param('_type');
        my @ids = $app->param('id');
        my ($category_id, $entry_id);
        my ($valid_email, $valid_id);
        foreach my $id (@ids) {
            if ($type eq 'blog') {
                require MT::Blog;
                my $blog = MT::Blog->load($id);
                $blog_id = $blog->id if ($blog);
                next unless ($blog);
                $valid_id++;
            } elsif ($type eq 'category') {
                require MT::Category;
                my $category = MT::Category->load($id);
                $blog_id = $category->blog_id if ($category);
                next unless ($category);
                $valid_id++;
            } elsif ($type eq 'entry') {
                require MT::Entry;
                my $entry = MT::Entry->load($id);
                $blog_id = $entry->blog_id if ($entry);
                next unless ($entry);
                $valid_id++;
            }
            foreach my $email (split(/\r\n/, $app->param('addresses'))) {
                $blog_id = ($type eq 'blog') ? $id : 0;
                $category_id = ($type eq 'category') ? $id : 0;
                $entry_id = ($type eq 'entry') ? $id : 0;
                my $ec = Notifier::create_subscription($email, $record, $blog_id, $category_id, $entry_id);
                $valid_email++ unless ($ec);
            }
        }
        my $plugin = MT->component('Notifier');
        $app->build_page($plugin->load_tmpl('dialog/close.tmpl'), {
            valid_email => $valid_email,
            valid_id    => $valid_id,
        });
    }
}

sub verify_subs {
  my $app = shift;
  require Notifier;
  require Notifier::Data;
  if (my $return = $app->param('return_args')) {
      my @ids = $app->param('id');
      for my $id (@ids) {
          my $obj = Notifier::Data->get_by_key({
              id => $id
          });
          if ($obj) {
              $obj->status(1);
              $obj->save;
          }
      }
      $app->return_args($return);
      $app->call_return;
  } else {
    my $plugin = MT->component('Notifier');
    my ($email, $blog_id, $category_id, $entry_id);
    my ($confirm, $data, $message, $name, $url);
    if (my $c = $app->param('c')) {
        # user cipher found - load data for processing!
        $data = Notifier::Data->load({ cipher => $c });
        if ($data) {
            if (my $o = $app->param('o')) {
                # opt-out/block requested!
                $blog_id = $data->blog_id;
                $category_id = $data->category_id;
                $entry_id = $data->entry_id;
                $email = $data->email;
                if ($data->entry_id) {
                    require MT::Entry;
                    my $entry = MT::Entry->get_by_key({
                        id => $entry_id
                    });
                    if ($entry) {
                        $blog_id = $entry->blog_id;
                        $name = $entry->title;
                        $url = $entry->permalink;
                    } else {
                        $message = 'No entry was found to match that subscription record!';
                    }
                } elsif ($category_id) {
                    require MT::Category;
                    my $category = MT::Category->get_by_key({
                        id => $category_id
                    });
                    if ($category) {
                        $blog_id = $category->blog_id;
                        $name = $category->label;
                        require MT::Blog;
                        require MT::Util;
                        my $blog = MT::Blog->get_by_key({
                            id => $category->blog_id
                        });
                        if ($blog) {
                            $url = $blog->archive_url;
                            $url .= '/' unless ($url =~ m/\/$/);
                            $url .= MT::Util::archive_file_for ('',  $blog, 'Category', $category);
                        }
                    } else {
                        $message = 'No category was found to match that subscription record!';
                    }
                } elsif ($blog_id) {
                    require MT::Blog;
                    my $blog = MT::Blog->get_by_key({
                        id => $blog_id
                    });
                    if ($blog) {
                        $blog_id = $blog->id;
                        $name = $blog->name;
                        $url = $blog->site_url;
                    } else {
                        $message = 'No blog was found to match that subscription record!';
                    }
                }
                $category_id = 0;
                $entry_id = 0;
                my $error = Notifier::create_subscription($email, Notifier::Data::OPT_OUT(), $blog_id, $category_id, $entry_id);
                if ($error == 1) {
                    $message = 'The specified email address is not valid!';
                } elsif ($error == 2) {
                    $message = 'The requested record key is not valid!';
                } elsif ($error == 3) {
                    $message = 'That record already exists!';
                } else {
                    $message = 'Your request has been processed successfully!';
                }
            } elsif (my $u = $app->param('u')) {
                # unsubscribe requested!
                $data->remove;
                $message = 'Your subscription has been cancelled!';
            }
        } else {
            $message = 'No subscription record was found to match that locator!';
        }
        unless ($message) {
            $message = 'Your request has been processed successfully!';
            $data->status(Notifier::Data::RUNNING());
            $data->save;
        }
    } else {
        if ($email = $app->param('email')) {
            $blog_id = $app->param('blog_id');
            $category_id = $app->param('category_id');
            $entry_id = $app->param('entry_id');
            if ($blog_id || $category_id || $entry_id) {
                if ($entry_id) {
                    require MT::Entry;
                    my $entry = MT::Entry->get_by_key({
                        id => $entry_id
                    });
                    if ($entry) {
                        $blog_id = $entry->blog_id;
                        $name = $entry->title;
                        $url = $entry->permalink;
                    }
                } elsif ($category_id) {
                    require MT::Category;
                    my $category = MT::Category->get_by_key({
                        id => $category_id
                    });
                    if ($category) {
                        $blog_id = $category->blog_id;
                        $name = $category->label;
                        require MT::Blog;
                        my $blog = MT::Blog->get_by_key({
                            id => $category->blog_id
                        });
                        if ($blog) {
                            $url = $blog->archive_url;
                            $url .= '/' unless ($url =~ m/\/$/);
                            $url .= MT::Util::archive_file_for ('',  $blog, 'Category', $category);
                        }
                    }
                } elsif ($blog_id) {
                    require MT::Blog;
                    my $blog = MT::Blog->get_by_key({
                        id => $blog_id
                    });
                    if ($blog) {
                        $name = $blog->name;
                        $url = $blog->site_url;
                    }
                }
                my $error = Notifier::create_subscription($email, Notifier::Data::SUBSCRIBE(), $blog_id, $category_id, $entry_id);
                if ($error == 1) {
                    $message = 'The specified email address is not valid!';
                } elsif ($error == 2) {
                    $message = 'The requested record key is not valid!';
                } elsif ($error == 3) {
                    $message = 'That record already exists!';
                } else {
                    $confirm = 1 if
                        $plugin->get_config_value('system_confirm') &&
                        $plugin->get_config_value('blog_confirm', 'blog:'.$blog_id);
                    $message = 'Your request has been processed successfully!';
                }
            } else {
                $message = 'Your request did not include a record key!';
            }
        } else {
            $message = 'Your request must include an email address!';
        }
    }
    my $n = $app->param('n'); # redirect name
    my $r = $app->param('r'); # redirect link
    if ($r && $r ne '1') {
        $name = ($n) ? $n : $r;
        $url = $r;
    }
    $app->build_page($plugin->load_tmpl('request.tmpl'), {
        confirm              => $confirm,
        link_name            => ($r) ? $name : '',
        link_url             => ($r) ? $url : '',
        message              => $plugin->translate($message),
        notifier_author_link => $plugin->author_link,
        notifier_author_name => $plugin->author_name,
        notifier_plugin_link => $plugin->plugin_link,
        notifier_name        => $plugin->name,
        notifier_version     => $plugin->version,
        page_title           => $plugin->name.' '.$plugin->translate('Request Processing')
    });
  }
}

sub write_history {
    my $app = shift;
    require MT::Blog;
    require MT::Entry;
    require Notifier::Data;
    require Notifier::History;
    my $return = $app->param('return_args');
    my @ids = $app->param('id');
    for my $id (@ids) {
        my $blog = MT::Blog->load({ id => $id });
        next unless ($blog);
        my @entries;
        my $entries = MT::Entry->load_iter({ blog_id => $blog->id });
        while (my $e = $entries->()) {
            push @entries, $e;
        }
        my %terms;
        $terms{'comment_id'} = 0;
        my $iter = Notifier::Data->load_iter({ blog_id => $blog->id, entry_id => 0 });
        while (my $data = $iter->()) {
            for my $entry (@entries) {
                my $history = Notifier::History->load({
                    data_id => $data->id,
                    entry_id => $entry->id,
                });
                next if ($history);
                $terms{'data_id'} = $data->id;
                $terms{'entry_id'} = $entry->id;
                Notifier::History->create(\%terms);
            }
        }
    }
    $app->return_args($return);
    $app->call_return;
}

# user interaction

sub notifier_count {
    my $app = shift;
    require Notifier::Data;
    my @ids = $app->param('id');
    my $type = $app->param('_type');
    my $total_opts = 0;
    my $total_subs = 0;
    my @subs;
    foreach my $id (@ids) {
        if ($type eq 'blog') {
            require MT::Blog;
            my $blog = MT::Blog->load($id);
            my $opts = Notifier::Data->count({ blog_id => $id, record => Notifier::Data::OPT_OUT() });
            my $subs = Notifier::Data->count({ blog_id => $id, record => Notifier::Data::SUBSCRIBE() });
            push @subs, { name => $blog->name, opt_count => $opts, sub_count => $subs };
            $total_opts += $opts;
            $total_subs += $subs;
        } elsif ($type eq 'category') {
            require MT::Category;
            my $category = MT::Category->load($id);
            my $opts = Notifier::Data->count({ category_id => $id, record => Notifier::Data::OPT_OUT() });
            my $subs = Notifier::Data->count({ category_id => $id, record => Notifier::Data::SUBSCRIBE() });
            push @subs, { name => $category->label, opt_count => $opts, sub_count => $subs };
            $total_opts += $opts;
            $total_subs += $subs;
        } elsif ($type eq 'entry') {
            require MT::Entry;
            my $entry = MT::Entry->load($id);
            my $opts = Notifier::Data->count({ entry_id => $id, record => Notifier::Data::OPT_OUT() });
            my $subs = Notifier::Data->count({ entry_id => $id, record => Notifier::Data::SUBSCRIBE() });
            push @subs, { name => $entry->title, opt_count => $opts, sub_count => $subs };
            $total_opts += $opts;
            $total_subs += $subs;
        }
    }
    my $plugin = MT->component('Notifier');
    $app->build_page($plugin->load_tmpl('dialog/count.tmpl'), {
        subs          => \@subs,
        total_opts    => $total_opts,
        total_subs    => $total_subs,
        type_blog     => ($type eq 'blog') ? 1 : 0,
        type_category => ($type eq 'category') ? 1 : 0,
        type_entry    => ($type eq 'entry') ? 1 : 0,
    });
}

# user redirection

sub _ui_opt {
    my $app = shift;
    require Notifier::Data;
    notifier_start($app, Notifier::Data::OPT_OUT());
}

sub _ui_sub {
    my $app = shift;
    require Notifier::Data;
    notifier_start($app, Notifier::Data::SUBSCRIBE());
}

sub notifier_start {
    my $app = shift;
    my $record = shift;
    my @ids = $app->param('id');
    my $plugin = MT->component('Notifier');
    $app->build_page($plugin->load_tmpl('dialog/start.tmpl'), {
        ids  => [ map { { id => $_ } } @ids ],
        record => $record,
        type => $app->param('_type')
    });
}

# widget redirection

sub sub_widget_blog {
    my $app = shift;
    install_widget($app, 'Blog');
}

sub sub_widget_category {
    my $app = shift;
    install_widget($app, 'Category');
}

sub sub_widget_entry {
    my $app = shift;
    install_widget($app, 'Entry');
}

# widget creation

sub install_widget {
    my ($app, $type) = @_;
    require MT::Template;
    my $perms = $app->permissions;
    my $plugin = MT->component('Notifier');
    return $app->error($plugin->translate('Insufficient permissions for installing templates for this weblog.'))
        unless ($app->user->is_superuser() || ($perms && ($perms->can_edit_templates() || $perms->can_administer_blog())));
    my $blog_id = MT->app->param('blog_id');
    my $terms = {};
    $terms->{blog_id} = $blog_id;
    $terms->{name} = $plugin->translate("[_1] $type Widget", $plugin->name);
    my $tmpl = MT::Template->load($terms);
    if ($tmpl) {
        return $app->error($plugin->translate("[_1] $type Widget: Template already exists.", $plugin->name));
    } else {
        my $val = {};
        $val->{name} = $terms->{name};
        $val->{text} = $app->translate_templatized(widget_template($plugin, $type));
        my $at = 'widget';
        my $tmpl = new MT::Template;
        $tmpl->set_values($val);
        $tmpl->type($at);
        $tmpl->blog_id($blog_id);
        $tmpl->save or return $app->error($plugin->translate('Error creating new template: [_1]', $tmpl->errstr));
        $app->redirect($app->uri( 'mode' => 'view', args => { 'blog_id' => $blog_id, '_type' => 'template', 'id' => $tmpl->id } ));
    }
}

sub widget_template {
    my ($plugin, $type) = @_;
    my $plugin_link = $plugin->plugin_link;
    my $plugin_name = $plugin->name;
    my $message = $plugin->translate("Subscribe to $type");
    my $powered = $plugin->translate('Powered by [_1]', qq{<a href="$plugin_link">$plugin_name</a>});
    my ($field, $value);
    if ($type eq 'Blog') {
        $field = 'blog_id';
        $value = '<$MTBlogID$>';
    } elsif ($type eq 'Category') {
        $field = 'category_id';
        $value = '<$MTNotifierCatID$>';
    } else {
        $field = 'entry_id';
        $value = '<$MTEntryID$>';
    }
    return <<TMPL;
        <div class="widget-subscribe widget">
            <h3 class="widget-header">$message</h3>
            <div class="widget-content">
                <form method="get" action="<mt:cgipath><mt:commentscript>">
                    <input type="hidden" name="__mode" value="verify_subs" />
                    <input type="hidden" name="$field" value="$value" />
                    <input id="email" name="email" size="16" />
                    <input type="submit" class="button" value="<__trans phrase="Go">" />
                </form>
                <p>$powered</p>
            </div>
        </div>
TMPL
}

# callbacks

sub check_comment {
    my ($err, $obj) = @_;
    require MT::Request;
    my $id = 'blog:'.$obj->blog_id;
    my $notify = 1;
    $notify = 0 unless ($obj->visible);
    my $plugin = MT->component('Notifier');
    $notify = 0 if ($plugin->get_config_value('blog_disabled', $id));
    my $r = MT::Request->instance;
    $r->cache('mtn_notify_comment_'.$id, $notify);
}

sub check_entry {
    my ($err, $obj) = @_;
    require MT::Entry;
    my $plugin = MT->component('Notifier');
    return if ($plugin->get_config_value('blog_disabled', 'blog:'.$obj->blog_id));
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
        require MT::Request;
        require Notifier::Data;
        if (MT->app->param('subscribe')) {
            require Notifier;
            Notifier::create_subscription($obj->email, Notifier::Data::SUBSCRIBE(), 0, 0, $obj->entry_id)
        }
        my $r = MT::Request->instance;
        return unless ($r->cache('mtn_notify_comment_'.$id));
        my (%terms);
        $terms{'blog_id'} = $obj->blog_id;
        $terms{'record'} = Notifier::Data::SUBSCRIBE();
        $terms{'status'} = Notifier::Data::RUNNING();
        my @work_subs;
        my $plugin = MT->component('Notifier');
        if ($plugin->get_config_value('blog_all_comments', $id)) {
            my @blog_subs = Notifier::Data->load(\%terms);
            push @work_subs, @blog_subs;
            my $cats = $obj->entry->categories;
            foreach my $c (@$cats) {
                require MT::Category;
                my $cat = MT::Category->load($c);
                next unless ((ref $cat) && $cat->isa('MT::Category'));
                $terms{'category_id'} = $cat->id;
                my @cat_subs = Notifier::Data->load(\%terms);
                push @work_subs, @cat_subs;
            }
        } else {
            $terms{'entry_id'} = $obj->entry_id;
            @work_subs = Notifier::Data->load(\%terms);
        }
        return unless (scalar @work_subs);
        Notifier::notify_users($obj, \@work_subs);
    }
}

sub notify_entry {
    my ($err, $obj) = @_;
    require MT::Request;
    require Notifier;
    my $r = MT::Request->instance;
    my $notify = $r->cache('mtn_notify_entry');
    return unless ($notify);
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

1;