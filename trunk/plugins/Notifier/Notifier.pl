# ===========================================================================
# A Movable Type plugin with subscription options for your installation
# Copyright 2003-2008 Everitz Consulting <everitz.com>.
#
# This program may not be redistributed without permission.
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
    ['system_address',    { Default => '', Scope => 'system' }],
    ['system_confirm',    { Default => 1 , Scope => 'system' }],
    ['system_queued',     { Default => 0 , Scope => 'system' }],
  ]),
});
MT->add_plugin($plugin);

sub init_registry {
  my $plugin = shift;
  $plugin->registry({
    applications => {
      'cms' => {
        list_actions => sub { Notifier::Plugin::list_actions },
        list_filters => sub { Notifier::Plugin::list_filters },
        menus        => sub { Notifier::Plugin::menus },
        methods      => sub { Notifier::Plugin::methods },
      }
    },
    callbacks => {
      'MT::Comment::pre_save'                           => '$Notifier::Notifier::Plugin::check_comment',
      'MT::Comment::post_save'                          => '$Notifier::Notifier::Plugin::notify_comment',
      'MT::Entry::pre_save'                             => '$Notifier::Notifier::Plugin::check_entry',
      'MT::App::CMS::cms_post_save.entry'               => '$Notifier::Notifier::Plugin::notify_entry',
      'MT::AtomServer::api_post_save.entry'             => '$Notifier::Notifier::Plugin::notify_entry',
      'MT::XMLRPCServer::api_post_save.entry'           => '$Notifier::Notifier::Plugin::notify_entry',
      # transformer to set quicksearch value to 0 on subscription quicksearches...
      # - can remove once there is an edit_subscription.tmpl in place (one day)
      'MT::App::CMS::template_output.search_replace'    => \&_output_search_replace,
      'MT::App::CMS::template_output.list_subscription' => \&_output_search_replace,
    },
    object_types => {
      'subscription'         => 'Notifier::Data',
      'subscription.history' => 'Notifier::History',
      'subscription.queue'   => 'Notifier::Queue',
    },
    search_apis => {
        'subscription' => {
          'order'              => 1000,
          'permission'         => 'edit_notifications',
          'handler'            => '$Notifier::Notifier::App::build_sub_table',
          'label'              => 'Subscriptions',
          'perm_check'         => sub { 1; },
          'search_cols'        => {
            'email'            => sub { $plugin->translate('Email') },
            'ip'               => sub { $plugin->translate('IP Address') },
          },
          'replace_cols'       => [qw(email)],
          'can_replace'        => 1,
          'can_search_by_date' => 1,
          'date_column'        => 'created_on',
          'view'               => 'blog',
          'setup_terms_args'   => sub {
             my ($terms, $args, $blog_id) = @_;
             $args->{sort}      = 'created_on';
             $args->{direction} = 'descend';
          },
          'results_table_template' => '<mt:include name="include/subscription_table.tmpl" component="notifier">',
      },
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

# transformer to set quicksearch value to 0 on subscription searches...

sub _output_search_replace {
  my ($cb, $app, $template) = @_;
  my $plugin = $cb->plugin;
  my ($chk, $new, $old);

  $chk = qq{<input type="hidden" name="_type" value="subscription" />};
  $chk = quotemeta($chk);
  return unless ($$template =~ m/$chk/);

  $old = qq{<input type="hidden" name="quicksearch" value="1" />};
  $old = quotemeta($old);
  $new = qq{<input type="hidden" name="quicksearch" value="0" />};
  $$template =~ s/$old/$new/;
}

1;
