# ===========================================================================
# A Movable Type plugin with subscription options for your installation
# Copyright 2003-2009 Everitz Consulting <everitz.com>.
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

use strict;

use base qw( MT::Plugin );

use MT;
use Notifier;
use Notifier::Plugin;

# plugin registration

my $plugin = MT::Plugin::Notifier->new({
  id             => 'Notifier',
  key            => 'notifier',
  name           => 'MT-Notifier',
  description    => qq(<__trans phrase="Subscription options for your Movable Type installation.">),
  author_name    => 'Everitz Consulting',
  author_link    => 'http://everitz.com/',
  plugin_link    => 'http://everitz.com/mt/notifier/index.php',
  doc_link       => 'http://everitz.com/mt/notifier/index.php#install',
  icon           => 'images/Notifier.gif',
  l10n_class     => 'Notifier::L10N',
  version        => Notifier->VERSION,
  schema_version => Notifier->schema_version,
#
# settings
#
  blog_config_template   => 'settings/blog.tmpl',
  system_config_template => 'settings/system.tmpl',
  settings               => new MT::PluginSettings([
    ['blog_address',      { Default => '', Scope => 'blog' }],
    ['blog_address_type', { Default => 1 , Scope => 'blog' }],
    ['blog_all_comments', { Default => 0 , Scope => 'blog' }],
    ['blog_confirm',      { Default => 1 , Scope => 'blog' }],
    ['blog_disabled',     { Default => 0 , Scope => 'blog' }],
    ['blog_status',       { Default => 1 , Scope => 'blog' }],
    ['blog_queued',       { Default => 0 , Scope => 'blog' }],
    ['blog_url_base',     { Default => '', Scope => 'blog' }],
    ['blog_url_type',     { Default => 1 , Scope => 'blog' }],
    ['system_address',    { Default => '', Scope => 'system' }],
    ['system_confirm',    { Default => 1 , Scope => 'system' }],
    ['system_queued',     { Default => 0 , Scope => 'system' }],
    ['system_url_base',   { Default => '', Scope => 'system' }],
    ['system_url_type',   { Default => 2 , Scope => 'system' }],
  ]),
});
MT->add_plugin($plugin);

sub init_registry {
  my $plugin = shift;
  $plugin->registry({
    applications => {
      'cms' => {
        list_actions => sub { Notifier::Plugin::list_actions },
        methods      => sub { Notifier::Plugin::methods },
      }
    },
    callbacks => {
      'MT::Comment::pre_save'                           => '$Notifier::Notifier::Plugin::check_comment',
      'MT::Comment::post_save'                          => '$Notifier::Notifier::Plugin::notify_comment',
      'MT::Entry::pre_save'                             => '$Notifier::Notifier::Plugin::check_entry',
      'MT::Entry::post_save'                            => '$Notifier::Notifier::Plugin::notify_entry',
      # application callbacks for MT::Entry::post_save...
      # - don't work for scheduled post...
      # 'MT::App::CMS::cms_post_save.entry'               => '$Notifier::Notifier::Plugin::notify_entry',
      # 'MT::AtomServer::api_post_save.entry'             => '$Notifier::Notifier::Plugin::notify_entry',
      # 'MT::XMLRPCServer::api_post_save.entry'           => '$Notifier::Notifier::Plugin::notify_entry',
    },
    object_types => {
      'subscription'         => 'Notifier::Data',
      'subscription.history' => 'Notifier::History',
      'subscription.queue'   => 'Notifier::Queue',
    },
    tags => {
      function => {
        'NotifierCatID' => '$Notifier::Notifier::Plugin::notifier_category_id',
        'NotifierCheck' => '$Notifier::Notifier::Plugin::notifier_check',
      }
    },
    upgrade_functions => {
      'set_blog_id' => {
        code => '$Notifier::Notifier::Upgrade::set_blog_id',
        version_limit => 3.5,
      },
      'set_blog_status' => {
        code => '$Notifier::Notifier::Upgrade::set_blog_status',
        version_limit => 4.1
      },
      'set_history' => {
        code => '$Notifier::Notifier::Upgrade::set_history',
        version_limit => 3.5,
      },
      'set_ip' => {
        code => '$Notifier::Notifier::Upgrade::set_ip',
        version_limit => 3.6,
      },
    },
  });
}

sub load_config {
  my $plugin = shift;
  my ($args, $scope) = @_;

  $plugin->SUPER::load_config(@_);

  my $app = MT->instance;
  if ($app->isa('MT::App')) {
    $args->{static_uri} = $app->static_path;
    if ($scope =~ /blog:(\d+)/) {
      my $blog_id = $1;
      $args->{blog_id} = $blog_id;
    }
  }
}

# access to plugin

sub instance { $plugin; }

1;
