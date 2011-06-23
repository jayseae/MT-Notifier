# ===========================================================================
# A Movable Type plugin with subscription options for your installation
# Copyright 2003-2011 Everitz Consulting <everitz.com>.
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

sub check_config_flag {
    my $flag = shift;
    require MT::Request;
    my $r = MT::Request->instance;
    my $blog = $r->cache('mtn_blog');
    my ($system_value, $blog_value);
    my $plugin = MT->component('Notifier');
    $system_value = $plugin->get_config_value('system_'.$flag);
    if ($blog) {
        $blog_value = $plugin->get_config_value('blog_'.$flag, 'blog:'.$blog->id);
    }
    require Notifier::Data;
    if ($system_value && $blog_value) {
        # both configuration values exist
        return Notifier::Data::FULL();
    } elsif ($blog_value) {
        # blog configuration value exists
        return Notifier::Data::BLOG();
    } elsif ($system_value) {
        # system configuration value exists
        return Notifier::Data::SITE();
    } else {
        # neither configuration value is set
        return Notifier::Data::NULL();
    }
}

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

sub load_notifier_tmpl {
    my $app = shift;
    my ($args, $blog_id, $author) = @_;
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
        next if ($key eq 'category_id' || $key eq 'comment_id' || $key eq 'entry_id' || $key eq 'author_id' || $key eq 'text');
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
        if ($args->{author_id}) {
            require MT::Author;
            $author = MT::Author->load({ id => $args->{author_id} });
            $ctx->stash('author', $author) if ($author);
        }
        $app->set_default_tmpl_params($tmpl, $blog_id, $author);
        return $tmpl;
    } else {
        # no template, log a message and return an error
        my $message = $plugin->translate('Could not load the [_1] [_2] template!', $plugin->name, $plugin->translate($args->{text}));
        MT->log({ blog_id => $args->{blog_id}, message => $message });
        return MT->error($message);
    }
}

sub load_sender_address {
    my ($author, $blog) = @_;
    my $plugin = MT->component('Notifier');
    # retrieve default system address for sender address
    my $system_address = $plugin->get_config_value('system_address');
    my $sender_address;
    if ($blog) {
        my $blog_address_type = $plugin->get_config_value('blog_address_type', 'blog:'.$blog->id);
        if ($blog_address_type == 1) {
            # use default system address for sender address
            $sender_address = $system_address;
        } elsif ($blog_address_type == 2) {
            # use author email if there is one, otherwise use system default (thanks ches@lexblog)
            $sender_address = $author ? $author->email : $plugin->get_config_value('system_address');
        } elsif ($blog_address_type == 3) {
            # use default blog address for sender address
            $sender_address = $plugin->get_config_value('blog_address', 'blog:'.$blog->id);
        }
    } else {
        # no blog?  has to be system address
        $sender_address = $system_address;
    }
    # now have a sender address, make sure it is valid and return
    require MT::Util;
    if (my $fixed = MT::Util::is_valid_email($sender_address)) {
        return $fixed;
    } else {
        my $message;
        if ($sender_address) {
            $message .= $plugin->translate('Invalid sender address - please reconfigure it!');
        } else {
            $message .= $plugin->translate('No sender address - please configure one!');
        }
        MT->log($message);
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
    my $blog_id = shift;
    my $author = shift;
    my $plugin = MT->component('Notifier');
    # retrieve default system base url
    my $system_base = $plugin->get_config_value('system_url_base');
    # retrieve default system url type
    my $system_url_type = $plugin->get_config_value('system_url_type');
    my $blog_url_type;
    my $url_base;
    require MT::ConfigMgr;
    my $mgr = MT::ConfigMgr->instance;
    my $plugin = MT->component('Notifier');
    if ($system_url_type == 2) {
        # use config file for base url
        $url_base = $mgr->CGIPath;
    } elsif ($system_url_type == 4) {
        # use default system base for base url
        $url_base = $system_base;
    }
    if ($blog_id) {
        $blog_url_type = $plugin->get_config_value('blog_url_type', 'blog:'.$blog_id);
        if ($blog_url_type == 1) {
            # use system setting for base url (default)
            if ($system_url_type == 3) {
                # use current blog site url for base url
                require MT::Blog;
                my $blog = MT::Blog->load($blog_id);
                unless ($blog) {
                    my $message = $plugin->translate('Specified blog unavailable - please check your data!');
                    MT->log($message);
                    return MT->error($message);
                }
                $url_base = $blog->site_url;
            }
        } elsif ($blog_url_type == 2) {
            # use config file for base url
            $url_base = $mgr->CGIPath;
        } elsif ($blog_url_type == 3) {
            # use current blog site url for base url
            require MT::Blog;
            my $blog = MT::Blog->load($blog_id);
            unless ($blog) {
                my $message = $plugin->translate('Specified blog unavailable - please check your data!');
                MT->log($message);
                return MT->error($message);
            }
            $url_base = $blog->site_url;
        } elsif ($blog_url_type == 4) {
            # use blog base for base url
            $url_base = $plugin->get_config_value('blog_url_base', 'blog:'.$blog_id);
        }
    }
    $url_base .= '/' unless ($url_base =~ m!/$!);
    unless ($url_base =~ /^http/) {
        my $message = $plugin->translate('Invalid URL base value - please check your data ([_1])!', qq{$url_base});
        MT->log($message);
        return MT->error($message);
    }
    return $url_base.$mgr->CommentScript;
}

sub set_default_tmpl_params {
    my $app = shift;
    my ($tmpl, $blog_id, $author) = @_;
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
    # conditional code for script name handled in subroutine
    $param->{notifier_script} = Notifier::Util::script_name($blog_id, $author);
    $tmpl->param($param);
}

1;