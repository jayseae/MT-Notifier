# ===========================================================================
# A Movable Type plugin with subscription options for your installation
# Copyright 2003-2010 Everitz Consulting <everitz.com>.
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

sub load_email {
    my ($tmpl, $param) = @_;
    my $out = MT->build_email("email/$tmpl", $param);
    return($out);
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
    $url_base .= '/' unless $url_base =~ m!/$!;
    unless ($url_base =~ /^http/) {
        $app->log($plugin->translate('Invalid URL base value - please check your data ([_1])!', qq{$url_base}));
    }
    return $url_base.$mgr->CommentScript;
}

1;