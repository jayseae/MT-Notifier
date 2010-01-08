# ===========================================================================
# A Movable Type plugin with subscription options for your installation
# Copyright 2003-2008 Everitz Consulting <everitz.com>.
#
# This program may not be redistributed without permission.
# ===========================================================================
package Notifier::Util;

use base qw(MT::App);
use strict;

use File::Spec;
use MT;
use MT::ConfigMgr;

# shared functions

sub load_blog {
  my ($obj) = @_;
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
  require MT::Blog;
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
  my $app = MT->instance->app;
  my $plugin = MT::Plugin::Notifier->instance;
  my $entry;
  if (UNIVERSAL::isa($obj, 'MT::Comment')) {
    require MT::Entry;
    $entry = MT::Entry->load($obj->entry_id);
  } else {
    $entry = $obj;
  }
  require MT::Blog;
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
    $sender_address = $author->email if ($author);
  } elsif ($blog_address_type == 3) {
    $sender_address = $plugin->get_config_value('blog_address', 'blog:'.$blog->id);
  }
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
  my $app = MT->instance->app;
  my $mgr = MT::ConfigMgr->instance;
  my $plugin = MT::Plugin::Notifier->instance;
  my $mt4 = ($app->version_number >= 4) ? 1 : 0;
  my $notifier_base = ($mgr->CGIPath =~ /^http/) ? $mgr->CGIPath : $app->base.$mgr->CGIPath;
  my $notifier_link = ($mt4) ? $mgr->AdminScript : $plugin->envelope.'/mt-notifier.cgi';
  $notifier_base.$notifier_link;
}

1;