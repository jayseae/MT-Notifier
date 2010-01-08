# ===========================================================================
# A Movable Type plugin with subscription options for your installation
# Copyright 2003-2008 Everitz Consulting <everitz.com>.
#
# This program may not be redistributed without permission.
# ===========================================================================
package Notifier::App;

use base qw(MT::App);
use strict;

# methods

sub block_subs {
  my $app = shift;
  my $return = $app->param('return_args');
  my @ids = $app->param('id');
  for my $id (@ids) {
    require Notifier::Data;
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
  my $return = $app->param('return_args');
  my @ids = $app->param('id');
  for my $id (@ids) {
    require Notifier::Data;
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
    # TODO: convert this to use $app->call_return();
    # then templates can determine the page flow.
    #$app->return_args($return);
    #$app->call_return;
    return $app->redirect(
      $app->uri(
        'mode' => 'list_subs',
        args   => {
          blog_id => $blog_id,
          saved   => $email
        }
      )
    );
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
    my $plugin = MT::Plugin::Notifier->instance;
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
    my $plugin = MT::Plugin::Notifier->instance;
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
                $url .= '/' unless $url =~ m/\/$/;
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
                $url .= '/' unless $url =~ m/\/$/;
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
      confirm          => $confirm,
      link_name        => ($r) ? $name : '',
      link_url         => ($r) ? $url : '',
      message          => $plugin->translate($message),
      notifier_version => $plugin->version,
      page_title       => $plugin->name.' '.$plugin->translate('Request Processing')
    });
  }
}

sub write_history {
  my $app = shift;
  my $return = $app->param('return_args');
  my @ids = $app->param('id');
  for my $id (@ids) {
    require MT::Blog;
    my $blog = MT::Blog->load({ id => $id });
    next unless ($blog);
    require MT::Entry;
    my $entries = MT::Entry->load_iter({ blog_id => $blog->id });
    while (my $e = $entries->()) {
      require Notifier::Data;
      my $iter = Notifier::Data->load_iter({ blog_id => $blog->id, entry_id => 0 });
      while (my $data = $iter->()) {
        require Notifier::History;
        my $history = Notifier::History->load({
          data_id => $data->id,
          entry_id => $e->id,
        });
        next if ($history);
        $history = Notifier::History->new;
        $history->data_id($data->id);
        $history->comment_id(0);
        $history->entry_id($e->id);
        $history->save;
      }
    }
  }
  $app->return_args($return);
  $app->call_return;
}

# user redirection

sub _sub_block {
  my $app = shift;
  block_subs($app);
}

sub _sub_clear {
  my $app = shift;
  clear_subs($app);
}

sub _sub_history {
  my $app = shift;
  write_history($app);
}

sub _sub_verify {
  my $app = shift;
  verify_subs($app);
}

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

sub _ui_vue {
  my $app = shift;
  notifier_count($app);
}

# user interaction

sub list_subs {
  my $app    = shift;
  my $blog   = $app->param('blog_id') || $app->blog;
  my $plugin = MT::Plugin::Notifier->instance;
  my $args   = {};
  my $terms  = {};
  my $param  = {
    list_noncron  => 0,
    saved         => $app->param('saved')         || 0,
    saved_deleted => $app->param('saved_deleted') || 0,
    screen_class  => 'list-notification',
    search_label  => $plugin->translate('Subscriptions'),
  };
  $args->{sort_order} = 'created_on';
  $args->{direction}  = 'descend';
  # set values for screen filter
  my $filter     = $param->{filter}     = $app->param('filter') || '';
  my $filter_val = $param->{filter_val} = $app->param('filter_val') || '';
  # set values for filtering data
  if ($filter eq 'status') {
    if ($filter_val eq 'active') {
      $terms->{record} = 1;
      $terms->{status} = 1;
    }
    if ($filter_val eq 'blocked') {
      $terms->{record} = 0;
      $terms->{status} = 1;
    }
    if ($filter_val eq 'pending') {
      $terms->{status} = 0;
    }
  }
  # look for user cipher, load by email if present
  my $cipher = $param->{c} = $app->param('c') || '';
  if ($cipher) {
    require Notifier::Data;
    my $sub = Notifier::Data->load({ cipher => $cipher });
    $terms->{email} = $sub->email if (ref $sub);
  }
  # load data for processing
  my @data;
  require Notifier::Data;
  my $iter = Notifier::Data->load_iter($terms, $args);
  while (my $data = $iter->()) {
    push @data, $data->column_values;
  }
  $param->{subscriber_loop} = \@data;
  # hasher for data presentation
  my $hasher = sub {
    my ($obj, $row) = @_;
    $row->{category_record} = 1 if ( $row->{category_id} );
    $row->{entry_record} = 1 if ( $row->{entry_id} );
    $row->{url_block} = !$row->{record};
    $row->{visible} = $row->{status};

    require MT::Util;
    if (my $ts = $row->{created_on} ) {
      $row->{created_on_formatted} = MT::Util::format_ts("%Y.%m.%d", $ts);
      $row->{created_on_time_formatted} = MT::Util::format_ts("%Y.%m.%d %H:%M:%S", $ts);
      $row->{created_on_relative} = MT::Util::relative_date($ts, time, $blog);
    }
  };
  # data listing
  return $app->listing(
    {
      type     => 'subscription',
      template => 'list.tmpl',
      terms    => $terms,
      params   => $param,
      args     => $args,
      code     => $hasher,
    }
  );
}

sub notifier_count {
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
  my $plugin = MT::Plugin::Notifier->instance;
  $app->build_page($plugin->load_tmpl('dialog/count.tmpl'), {
    subs          => \@subs,
    total_opts    => $total_opts,
    total_subs    => $total_subs,
    type_blog     => ($type eq 'blog') ? 1 : 0,
    type_category => ($type eq 'category') ? 1 : 0,
    type_entry    => ($type eq 'entry') ? 1 : 0,
  });
}

sub notifier_start {
  my $app = shift;
  my $record = shift;
  my @ids = $app->param('id');
  my $plugin = MT::Plugin::Notifier->instance;
  $app->build_page($plugin->load_tmpl('dialog/start.tmpl'), {
    ids  => [ map { { id => $_ } } @ids ],
    record => $record,
    type => $app->param('_type')
  });
}

# widget redirection

sub _widget_blog {
  my $app = shift;
  install_widget($app, 'Blog');
}

sub _widget_category {
  my $app = shift;
  install_widget($app, 'Category');
}

sub _widget_entry {
  my $app = shift;
  install_widget($app, 'Entry');
}

# widget creation

sub install_widget {
  my $app = shift;
  my $type = shift;
  my $perms = $app->{perms};
  my $plugin = MT::Plugin::Notifier->instance;
  return $app->error($plugin->translate('Insufficient permissions for installing templates for this weblog.'))
    unless $perms->can_edit_templates() || $perms->can_administer_blog() || $app->user->is_superuser();
  my $blog_id = $app->param('blog_id');
  my $terms = {};
  $terms->{blog_id} = $blog_id;
  $terms->{name} = $plugin->translate("[_1] $type Widget", $plugin->name);
  require MT::Template;
  my $tmpl = MT::Template->load($terms);
  if ($tmpl) {
    return $app->error($plugin->translate("[_1] $type Widget: Template already exists.", $plugin->name));
  } else {
    my $val = {};
    $val->{name} = $terms->{name};
    $val->{text} = $app->translate_templatized(widget_template($type));
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
  my $type = shift;
  my $plugin = MT::Plugin::Notifier->instance;
  my $plugin_link = $plugin->plugin_link;
  my $plugin_name = $plugin->name;
  my $plugin = MT::Plugin::Notifier->instance;
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
                <form method="get" action="<mt:cgipath><mt:adminscript>">
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

1;