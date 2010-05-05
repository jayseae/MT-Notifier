# ===========================================================================
# A Movable Type plugin with subscription options for your installation
# Copyright 2003-2010 Everitz Consulting <everitz.com>.
#
# This program is distributed in the hope that it will be useful but does
# NOT INCLUDE ANY WARRANTY; Without even the implied warranty of FITNESS
# FOR A PARTICULAR PURPOSE.
#
# This program may not be redistributed without permission.
# ===========================================================================
package Notifier::Util;

use base qw(MT::App);
use strict;

use MT;

# shared functions

sub check_permission {
    my $app = MT->app;
    return 0 unless ($app);
    if ($app->permissions) {
        return 1 if ($app->permissions->can_edit_notifications);
        return 1 if ($app->permissions->can_administer_blog);
    }
    if ($app->user) {
        return 1 if ($app->user->is_superuser());
    }
    return 0;
}

sub load_blog {
    my ($obj) = @_;
    require MT::Blog;
    my $blog_id;
    if ($obj->entry_id) {
        require MT::Entry;
        my $entry = MT::Entry->load($obj->entry_id) or return;
        $blog_id = $entry->blog_id;
    } elsif ($obj->category_id) {
        require MT::Category;
        my $category = MT::Category->load($obj->category_id) or return;
        $blog_id = $category->blog_id;
    } else {
        $blog_id = $obj->blog_id;
    }
    my $blog = MT::Blog->load($blog_id) or return;
    $blog;
}

sub load_notifier_tmpl {
    my $app = shift;
    my ($args, $blog_id) = @_;
    my $mt = MT->app;
    my $plugin = MT->component('Notifier');
    # move hashref parameters to new hash
    my %terms;
    foreach my $key ( keys %{$args} ) {
        # set $blog_id, but don't add to terms
        if ($key eq 'blog_id') {
            $blog_id = $args->{$key};
            next;
        }
        # don't add extra keys to terms - will break load_global_tmpl!
        next if ($key eq 'category_id' || $key eq 'comment_id' || $key eq 'entry_id' || $key eq 'text');
        $terms{$key} = $args->{$key};
    }
    my $tmpl;
    # load the requested template from database
    $tmpl = $mt->load_global_tmpl(\%terms, $blog_id);
    if ($tmpl) {
        # if we have a template, set the various contexts
        my $ctx = $tmpl->context;
        if ($args->{blog_id}) {
            require MT::Blog;
            my $blog = MT::Blog->load({ id => $args->{blog_id} });
            $ctx->stash('blog', $blog) if ($blog);
        }
        if ($args->{category_id}) {
            require MT::Category;
            my $category = MT::Category->load({ id => $args->{category_id} });
            $ctx->stash('category', $category) if ($category);
        }
        if ($args->{comment_id}) {
            require MT::Comment;
            my $comment = MT::Comment->load({ id => $args->{comment_id} });
            $ctx->stash('comment', $comment) if ($comment);
        }
        if ($args->{entry_id}) {
            require MT::Entry;
            my $entry = MT::Entry->load({ id => $args->{entry_id} });
            $ctx->stash('entry', $entry) if ($entry);
        }
        $app->set_default_tmpl_params($tmpl, $blog_id);
        return $tmpl;
    } else {
        # no template, log a message and return an error
        my $message = $plugin->translate('Could not load the [_1] [_2] template!', $plugin->name, $plugin->translate($args->{text}));
        MT->log({ blog_id => $args->{blog_id}, message => $message });
        return $mt->error($message);
    }
}

sub load_sender_address {
    my ($obj, $author) = @_;
    require MT::Blog;
    require MT::Util;
    my $app = MT->app;
    my $plugin = MT->component('Notifier');
    my $entry;
    if (UNIVERSAL::isa($obj, 'MT::Comment')) {
        require MT::Entry;
        $entry = MT::Entry->load($obj->entry_id);
    } else {
        $entry = $obj;
    }
    my $blog = MT::Blog->load($entry->blog_id);
    unless ($blog) {
        $app->log($plugin->translate('Specified blog unavailable - please check your data!'));
        return;
    }
    my $blog_address_type = $plugin->get_config_value('blog_address_type', 'blog:'.$blog->id);
    my $sender_address;
    if ($blog_address_type == 1) {
        $sender_address = $plugin->get_config_value('system_address');
    } elsif ($blog_address_type == 2) {
        # use author email if there is one, otherwise use system default (thanks ches@lexblog)
        $sender_address = $author ? $author->email : $plugin->get_config_value('system_address');
    } elsif ($blog_address_type == 3) {
        $sender_address = $plugin->get_config_value('blog_address', 'blog:'.$blog->id);
    }
    if (my $fixed = MT::Util::is_valid_email($sender_address)) {
        return $fixed;
    } else {
        my $message;
        if ($sender_address) {
            $message .= $plugin->translate('Invalid sender address - please reconfigure it!');
        } else {
            $message .= $plugin->translate('No sender address - please configure one!');
        }
        $app->log($message);
        return;
    }
}

sub produce_cipher {
    my $key = shift;
    my $salt = join '', ('.', '/', 0..9, 'A'..'Z', 'a'..'z')[rand 64, rand 64];
    my $cipher = crypt ($key, $salt);
    $cipher =~ s/\.$/q/;
    $cipher;
}

sub script_name {
    my ($blog_id) = shift;
    require MT::Blog;
    require MT::ConfigMgr;
    my $app = MT->app;
    my $mgr = MT::ConfigMgr->instance;
    my $plugin = MT->component('Notifier');
    my $blog = MT::Blog->load($blog_id);
    unless ($blog) {
        $app->log($plugin->translate('Specified blog unavailable - please check your data!'));
        return $mgr->AdminScript;
    }
    my $url_base;
    my $url_type = $plugin->get_config_value('blog_url_type', 'blog:'.$blog->id);
    if ($url_type == 1) {
      # use system setting (default)
      $url_type = $plugin->get_config_value('system_url_type');
      if ($url_type == 2) {
          $url_base = $mgr->CGIPath;
      } elsif ($url_type == 3) {
          $url_base = $blog->site_url;
      } elsif ($url_type == 4) {
          $url_base = $plugin->get_config_value('system_url_base');
      }
    } elsif ($url_type == 2) {
        $url_base = $mgr->CGIPath;
    } elsif ($url_type == 3) {
        $url_base = $blog->site_url;
    } elsif ($url_type == 4) {
        $url_base = $plugin->get_config_value('blog_url_base', 'blog:'.$blog->id);
    }
    $url_base .= '/' unless ($url_base =~ m!/$!);
    unless ($url_base =~ /^http/) {
        $app->log($plugin->translate('Invalid URL base value - please check your data ([_1])!', qq{$url_base}));
    }
    return $url_base.$mgr->CommentScript;
}

sub set_default_tmpl_params {
    my $app = shift;
    my ($tmpl, $blog_id) = @_;
    my $param = {};
    my $plugin = MT->component('Notifier');
    $param->{notifier_author_link} = $plugin->author_link;
    $param->{notifier_author_name} = $plugin->author_name;
    $param->{notifier_plugin_docs} = $plugin->doc_link;
    $param->{notifier_plugin_icon} = $plugin->icon;
    $param->{notifier_plugin_link} = $plugin->plugin_link;
    $param->{notifier_plugin_name} = $plugin->name;
    $param->{notifier_schema} = $plugin->schema_version;
    $param->{notifier_version} = $plugin->version;
    if ($blog_id) {
        # script name is only available when there is a $blog_id
        $param->{notifier_script} = Notifier::Util::script_name($blog_id);
    }
    $tmpl->param($param);
}

1;