# ===========================================================================
# A Movable Type plugin with subscription options for your installation
# Copyright 2003-2008 Everitz Consulting <everitz.com>.
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
  description    => q(<__trans phrase="Subscription options for your Movable Type installation.">),
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
  blog_config_template   => \&settings_template_blog,
  system_config_template => \&settings_template_system,
  settings               => new MT::PluginSettings([
    ['blog_address',      { Default => '', Scope => 'blog' }],
    ['blog_address_type', { Default => 1 , Scope => 'blog' }],
    ['blog_confirm',      { Default => 1 , Scope => 'blog' }],
    ['blog_disabled',     { Default => 0 , Scope => 'blog' }],
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
        methods      => sub { Notifier::Plugin::methods },
      }
    },
    callbacks => {
      'MT::Comment::pre_save'  => '$Notifier::Notifier::Plugin::check_comment',
      'MT::Comment::post_save' => '$Notifier::Notifier::Plugin::notify_comment',
      'MT::Entry::pre_save'    => '$Notifier::Notifier::Plugin::check_entry',
      'MT::Entry::post_save'   => '$Notifier::Notifier::Plugin::notify_entry',
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
      'set_history' => {
        code => '$Notifier::Notifier::Upgrade::set_history',
        version_limit => 3.5,
      },
      'set_ip' => {
        code => '$Notifier::Notifier::Upgrade::set_ip',
        version_limit => 3.6,
      }
    },
  });
}

# settings template - blog

sub settings_template_blog {
  my ($plugin, $param) = @_;
  my $app = MT->instance;
  my $blog_id = $app->param('blog_id');
  return <<TMPL;
<script language="JavaScript">
  <!--
    function hide_and_seek () {
      if (document.getElementById('blog_disabled').checked) {
        document.getElementById('blog_confirm_0').disabled = 1;
        document.getElementById('blog_confirm_1').disabled = 1;
        document.getElementById('blog_queued_0').disabled = 1;
        document.getElementById('blog_queued_1').disabled = 1;
        document.getElementById('blog_address_type_1').disabled = 1;
        document.getElementById('blog_address_type_2').disabled = 1;
        document.getElementById('blog_address_type_3').disabled = 1;
        document.getElementById('blog_address').disabled = 1;
      } else {
        document.getElementById('blog_confirm_0').disabled = 0;
        document.getElementById('blog_confirm_1').disabled = 0;
        document.getElementById('blog_queued_0').disabled = 0;
        document.getElementById('blog_queued_1').disabled = 0;
        document.getElementById('blog_address_type_1').disabled = 0;
        document.getElementById('blog_address_type_2').disabled = 0;
        document.getElementById('blog_address_type_3').disabled = 0;
        if (document.getElementById('blog_address_type_3').checked) {
          document.getElementById('blog_address').disabled = 0;
        } else {
          document.getElementById('blog_address').disabled = 1;
        }
      }
    }
  //-->
</script>
<fieldset>
    <mtapp:setting
        id="notifier_disable"
        label="<__trans phrase="Disable">"
        hint=""
        show_hint="0">
        <p>
            <input type="checkbox" name="blog_disabled" id="blog_disabled" onclick="hide_and_seek(this.form)" value="1" <mt:if name="blog_disabled">checked="checked"</mt:if> /> <__trans phrase="Disable MT-Notifier for This Blog">
        </p>
    </mtapp:setting>
    <mtapp:setting
        id="sender_address"
        label="<__trans phrase="Sender">"
        hint=""
        show_hint="0">
        <p>
            <input type="radio" name="blog_address_type" id="blog_address_type_1" onclick="hide_and_seek()" value="1" <mt:if name="blog_address_type_1">checked="checked"</mt:if> /> <__trans phrase="Use System Address for Sender Address (Default)"><br />
            <input type="radio" name="blog_address_type" id="blog_address_type_2" onclick="hide_and_seek()" value="2" <mt:if name="blog_address_type_2">checked="checked"</mt:if> /> <__trans phrase="Use Author Address for Sending Notifications"><br />
            <input type="radio" name="blog_address_type" id="blog_address_type_3" onclick="hide_and_seek()" value="3" <mt:if name="blog_address_type_3">checked="checked"</mt:if> /> <__trans phrase="Use This Address for Sending Notifications:"><br /><br />
            <input id="blog_address" name="blog_address" size="50" <mt:if name="blog_address">value="<mt:var name="blog_address">"</mt:if> />
        </p>
    </mtapp:setting>
    <mtapp:setting
        id="subscription_confirmation"
        label="<__trans phrase="Confirmation">"
        hint=""
        show_hint="0">
        <p>
            <input type="radio" name="blog_confirm" id="blog_confirm_0" value="0" <mt:if name="blog_confirm_0">checked="checked"</mt:if> /> <__trans phrase="Do not Send Any Confirmation Messages"><br />
            <input type="radio" name="blog_confirm" id="blog_confirm_1" value="1" <mt:if name="blog_confirm_1">checked="checked"</mt:if> /> <__trans phrase="Send Confirmation for New Subscriptions">
        </p>
    </mtapp:setting>
    <mtapp:setting
        id="delivery_queue"
        label="<__trans phrase="Queue">"
        hint=""
        show_hint="0">
        <p>
            <input type="radio" name="blog_queued" id="blog_queued_0" value="0" <mt:if name="blog_queued_0">checked="checked"</mt:if> /> <__trans phrase="Do not Submit any Notifications to Delivery Queue"><br />
            <input type="radio" name="blog_queued" id="blog_queued_1" value="1" <mt:if name="blog_queued_1">checked="checked"</mt:if> /> <__trans phrase="Submit Notifications to Queue for Later Delivery">
        </p>
    </mtapp:setting>
    <mtapp:setting
        id="widget_sub_blog"
        label="<__trans phrase="Widgets">"
        hint=""
        show_hint="0">
        <p>
            <a href="<mt:var name="script_url">?__mode=widget_sub_blog&blog_id=$blog_id">Click here to install the MT-Notifier Blog Subscription Widget</a><br />
            <a href="<mt:var name="script_url">?__mode=widget_sub_category&blog_id=$blog_id">Click here to install the MT-Notifier Category Subscription Widget</a><br />
            <a href="<mt:var name="script_url">?__mode=widget_sub_entry&blog_id=$blog_id">Click here to install the MT-Notifier Entry Subscription Widget</a>
        </p>
    </mtapp:setting>
</fieldset>
<script language="JavaScript">
  <!--
    hide_and_seek();
  //-->
</script>
TMPL
}

# settings template - system

sub settings_template_system {
  my ($plugin, $param) = @_;
  return <<TMPL;
<fieldset>
    <mtapp:setting
        id="subscription_confirmation"
        label="<__trans phrase="Confirmation">"
        hint=""
        show_hint="0">
        <p>
            <input type="radio" name="system_confirm" id="system_confirm_0" value="0" <mt:if name="system_confirm_0">checked="checked"</mt:if> /> <__trans phrase="Do not Send any Confirmation Messages"><br />
            <input type="radio" name="system_confirm" id="system_confirm_1" value="1" <mt:if name="system_confirm_1">checked="checked"</mt:if> /> <__trans phrase="Send Confirmation for New Subscriptions">
        </p>
    </mtapp:setting>
    <mtapp:setting
        id="delivery_queue"
        label="<__trans phrase="Queue">"
        hint=""
        show_hint="0">
        <p>
            <input type="radio" name="system_queued" id="system_queued_0" value="0" <mt:if name="system_queued_0">checked="checked"</mt:if> /> <__trans phrase="Do not Submit any Notifications to Delivery Queue"><br />
            <input type="radio" name="system_queued" id="system_queued_1" value="1" <mt:if name="system_queued_1">checked="checked"</mt:if> /> <__trans phrase="Submit Notifications to Queue for Later Delivery">
        </p>
    </mtapp:setting>
    <mtapp:setting
        id="sender_address"
        label="<__trans phrase="Sender">"
        hint=""
        show_hint="0">
        <p>
            <__trans phrase="Address to use when sending notifications and no other addresses are available:"><br /><br />
            <input id="system_address" name="system_address" maxlength="75" size="75" <mt:if name="system_address">value="<mt:var name="system_address">"</mt:if> />
        </p>
    </mtapp:setting>
</fieldset>
TMPL
}

1;
