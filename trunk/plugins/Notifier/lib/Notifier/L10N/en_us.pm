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
package Notifier::L10N::en_us;

use strict;
use base 'Notifier::L10N';
use vars qw( %Lexicon );

## If you want to create a new translation, follow these six steps:
##
## - Copy this file to <lowercase language code>.pm
##
## - Replace the "package" line with:
## package Notifier::L10N::<lowercase language code>;
##
## - Replace the "use base" line with:
## use base 'Notifier::L10N::en_us';
##
## - Change the replacement text as needed (the right side of "=>").
##
## - Send me a copy so I can distribute to others.
##
## - Save and upload to your server.  You're done.

## Tips for a successful translation:
##
## Make sure each line ends with a comma (,)
##
## If a variable such as [_1] is present, do not remove it
##
## Try to use HTML entities where possible (&uuml; instead of ü)
##
## Do not change the English (left) side of the translation string
##
## Any quotes within strings must be "escaped" to be included: 'This is a quote: \''

## The following is the translation table.

%Lexicon = (

      ## plugin

      ## config.yaml (previously Notifier.pl)
      'Subscription options for your Movable Type installation.' => 'Subscription options for your Movable Type installation.',
      'Add Subscription(s)' => 'Add Subscription(s)',
      'Add Subscription Block(s)' => 'Add Subscription Block(s)',
      'View Subscription Count(s)' => 'View Subscription Count(s)',
      'Write History Records' => 'Write History Records',
      'Block Subscription(s)' => 'Block Subscription(s)',
      'Clear Subscription Block(s)' => 'Clear Subscription Block(s)',
      'Verify Subscription(s)' => 'Verify Subscription(s)',
      'Active Subscriptions' => 'Active Subscriptions',
      'Blocked Subscriptions' => 'Blocked Subscriptions',
      'Pending Subscriptions' => 'Pending Subscriptions',
      'Email' => 'Email',
      'IP Address' => 'IP Address',

      ## object_types

      ## lib/Notifier/Data.pm
      'Subscription' => 'Subscription',
      'Subscriptions' => 'Subscriptions',

      ## lib/Notifier/History.pm
      'Subscription History' => 'Subscription History',
      'Subscription History Records' => 'Subscription History Records',

      ## lib/Notifier/Queue.pm
      'Subscription Queue' => 'Subscription Queue',
      'Subscription Queue Records' => 'Subscription Queue Records',

      ## modules

      ## lib/Notifier.pm
      'Entry' => 'Entry',
      'Category' => 'Category',
      'Blog' => 'Blog',
      'subscribe to' => 'subscribe to',
      'opt-out of' => 'opt-out of',
      'Confirmation Subject' => 'Confirmation Subject',
      'Confirmation Body' => 'Confirmation Body',
      'Error sending confirmation message to [_1], error [_2]' => 'Error sending confirmation message to [_1], error [_2]',
      'Comment' => 'Comment',
      'Comment Notification Subject' => 'Comment Notification Subject',
      'Entry Notification Subject' => 'Entry Notification Subject',
      'Comment Notification Body' => 'Comment Notification Body',
      'Entry Notification Body' => 'Entry Notification Body',

      ## lib/Notifier/Plugin.pm
      'No entry was found to match that subscription record!' => 'No entry was found to match that subscription record!',
      'No category was found to match that subscription record!' => 'No category was found to match that subscription record!',
      'No blog was found to match that subscription record!' => 'No blog was found to match that subscription record!',
      'The specified email address is not valid!' => 'The specified email address is not valid!',
      'The requested record key is not valid!' => 'The requested record key is not valid!',
      'That record already exists!' => 'That record already exists!',
      'Your request has been processed successfully!' => 'Your request has been processed successfully!',
      'Your subscription has been cancelled!' => 'Your subscription has been cancelled!',
      'No subscription record was found to match that locator!' => 'No subscription record was found to match that locator!',
      'Your request did not include a record key!' => 'Your request did not include a record key!',
      'Your request must include an email address!' => 'Your request must include an email address!',
      'Request Processing' => 'Request Processing',
      'Unknown' => 'Unknown',
      'Invalid Request' => 'Invalid Request',
      'Permission denied' => 'Permission denied',
      'Active' => 'Active',
      'Blocked' => 'Blocked',
      'Pending' => 'Pending',
      '[_1] Feed' => '[_1] Feed',
      'Insufficient permissions for installing templates for this weblog.' => 'Insufficient permissions for installing templates for this weblog.',
      '[_1] Blog Widget' => '[_1] Blog Widget',
      '[_1] Category Widget' => '[_1] Category Widget',
      '[_1] Entry Widget' => '[_1] Entry Widget',
      '[_1] Blog Widget: Template Already Exists' => '[_1] Blog Widget: Template Already Exists',
      '[_1] Category Widget: Template Already Exists' => '[_1] Category Widget: Template Already Exists',
      '[_1] Entry Widget: Template Already Exists' => '[_1] Entry Widget: Template Already Exists',
      'Error creating new template: [_1]' => 'Error creating new template: [_1]',
      'Subscribe to Blog' => 'Subscribe to Blog',
      'Subscribe to Category' => 'Subscribe to Category',
      'Subscribe to Entry' => 'Subscribe to Entry',
      'Powered by [_1]' => 'Powered by [_1]',
      'Go' => 'Go',
      ## already defined
      ## 'Subscriptions' => 'Subscriptions',

      ## lib/Notifier/Util.pm
      'Could not load the [_1] [_2] template!' => 'Could not load the [_1] [_2] template!',
      'Specified blog unavailable - please check your data!' => 'Specified blog unavailable - please check your data!',
      'Invalid sender address - please reconfigure it!' => 'Invalid sender address - please reconfigure it!',
      'No sender address - please configure one!' => 'No sender address - please configure one!',
      'Invalid URL base value - please check your data ([_1])!' => 'Invalid URL base value - please check your data ([_1])!',

      ## templates: global templates are available in mt and are only translated on initial load - after that, you have to do them yourself!

      ## templates/global/notifier_comment_notification_body.mtml
      'Author: ' => 'Author: ',
      'Website: ' => 'Website: ',
      'View the entire entry:' => 'View the entire entry:',
      'Cancel this subscription:' => 'Cancel this subscription:',
      'Block all notifications from this site:' => 'Block all notifications from this site:',

      ## templates/global/notifier_comment_notification_subject.mtml
      'New Comment on' => 'New Comment on',

      ## templates/global/notifier_confirmation_body.mtml
      'requires you to use a double-opt system for making any changes to your subscription information.' => 'requires you to use a double-opt system for making any changes to your subscription information.',
      'Because you, or someone using your email address, recently submitted a request at' => 'Because you, or someone using your email address, recently submitted a request at',
      ', you are being sent this confirmation to verify that the request is genuine.' => ', you are being sent this confirmation to verify that the request is genuine.',
      'The request is to' => 'The request is to',
      'Please confirm your request by clicking this link' => 'Please confirm your request by clicking this link',
      'Use this link if you would like to visit before confirming this request' => 'Use this link if you would like to visit before confirming this request',
      'If you did not make this request, do nothing.  You will receive no further reminders of this request.  If you did make this request, but there are errors in the request, you can simply submit a new one to correct any problems.  Confirmation of that request will follow your re-submission.' => 'If you did not make this request, do nothing.  You will receive no further reminders of this request.  If you did make this request, but there are errors in the request, you can simply submit a new one to correct any problems.  Confirmation of that request will follow your re-submission.',
      ## already defined
      ## 'subscribe to' => 'subscribe to',
      ## 'opt-out of' => 'opt-out of',

      ## templates/global/notifier_confirmation_subject.mtml
      'Please confirm your request to' => 'Please confirm your request to',
      ## already defined
      ## 'subscribe to' => 'subscribe to',
      ## 'opt-out of' => 'opt-out of',

      ## templates/global/notifier_entry_notification_body.mtml
      ## already defined
      ## 'View the entire entry:' => 'View the entire entry:',
      ## 'Cancel this subscription:' => 'Cancel this subscription:',
      ## 'Block all notifications from this site:' => 'Block all notifications from this site:',

      ## templates/global/notifier_entry_notification_subject.mtml
      'New Entry from' => 'New Entry from',

      ## global/templates/notifier_request.mtml
      'Return to' => 'Return to',
      'You will receive an email to confirm your request momentarily.  If you do not, you may submit your request again.' => 'You will receive an email to confirm your request momentarily.  If you do not, you may submit your request again.',
      'Powered by' => 'Powered by',
      'version' => 'version',
      'Copyright' => 'Copyright',
      'All Rights Reserved' => 'All Rights Reserved',
      'Powered by' => 'Powered by',
      ## already defined
      ## 'Request Processing' => Request Processing',

      ## templates: these templates are loaded by the app, and as such are translated with each load

      ## tmpl/list_subscription.tmpl
      'Manage [_1]' => 'Manage [_1]',
      'You have added a [_1] for [_2].' => 'You have added a [_1] for [_2].',
      'You have successfully deleted the selected [_1].' => 'You have successfully deleted the selected [_1].',
      'Quickfilters' => 'Quickfilters',
      'Useful links' => 'Useful links',
      'Download [_1] (CSV)' => 'Download [_1] (CSV)',
      'Showing only: [_1]' => 'Showing only: [_1]',
      'Remove filter' => 'Remove filter',
      'All [_1]' => 'All [_1]',
      'change' => 'change',
      '[_1] where [_2] is [_3]' => '[_1] where [_2] is [_3]',
      'Show only [_1] where' => 'Show only [_1] where',
      'status' => 'status',
      'is' => 'is',
      'active' => 'active',
      'blocked' => 'blocked',
      'pending' => 'pending',
      'Filter' => 'Filter',
      'Cancel' => 'Cancel',
      'Delete selected [_1] (x)' => 'Delete selected [_1] (x)',
      'Delete' => 'Delete',
      'Actions' => 'Actions',
      'Add [_1]' => 'Add [_1]',
      'Status' => 'Status',
      'Modified' => 'Modified',
      'Type' => 'Type',
      'View' => 'View',
      'Click to show only blocked [_1]' => 'Click to show only blocked [_1]',
      'Click to show only active [_1]' => 'Click to show only active [_1]',
      'Click to show only pending [_1]' => 'Click to show only pending [_1]',
      'Click to edit [_1]' => 'Click to edit [_1]',
      'Save changes' => 'Save changes',
      'Save' => 'Save',
      ## already defined
      ## 'Subscription' => 'Subscription',
      ## 'Subscriptions' => 'Subscriptions',
      ## 'subscription' => 'subscription',
      ## 'subscriptions' => 'subscriptions',
      ## 'Email' => 'Email',
      ## 'Blocked' => 'Blocked',
      ## 'Active' => 'Active',
      ## 'Pending' => 'Pending',
      ## 'Entry' => 'Entry',
      ## 'Category' => 'Category',
      ## 'Blog' => 'Blog',

      ## tmpl/dialog/close.tmpl
      'Subscription Status' => 'Subscription Status',
      '[_1] email address(es) added to [_2] selection(s).' => '[_1] email address(es) added to [_2] selection(s).',
      'If the numbers don\'t match, you should check your data, wait a moment and try adding them again.' => 'If the numbers don\'t match, you should check your data, wait a moment and try adding them again.',
      'Close' => 'Close',

      ## tmpl/dialog/count.tmpl
      'Subscription Count' => 'Subscription Count',
      '[_1] has [_2] subscriptions and [_3] subscription blocks.' => '[_1] has [_2] subscriptions and [_3] subscription blocks.',
      'There are [_1] subscriptions and [_2] subscription blocks in this list.' => 'There are [_1] subscriptions and [_2] subscription blocks in this list.',
      ## already defined
      ## 'Close' => 'Close',

      ## tmpl/dialog/start.tmpl
      'Enter the email addresses, one per line, that you would like to subscribe to the current selection.  Click the Create Subscription(s) button to process the addresses when your list is complete.' => 'Enter the email addresses, one per line, that you would like to subscribe to the current selection.  Click the Create Subscription(s) button to process the addresses when your list is complete.',
      'Enter the email addresses, one per line, that you would like to enter into the system in order to block subscriptions.  These records are used to prevent subscriptions from being sent to a specific address, and are used in the event that a particular user no longer wants to receive anything from your site.  Click the Block Subscription(s) button to process the addresses when your list is complete.' => 'Enter the email addresses, one per line, that you would like to enter into the system in order to block subscriptions.  These records are used to prevent subscriptions from being sent to a specific address, and are used in the event that a particular user no longer wants to receive anything from your site.  Click the Block Subscription(s) button to process the addresses when your list is complete.',
      'Create Subscription(s)' => 'Create Subscription(s)',
      ## already defined
      ## 'Add Subscription(s)' => 'Add Subscription(s)',
      ## 'Block Subscription(s)' => 'Block Subscription(s)',
      ## 'Create Subscription(s)' => 'Create Subscription(s)',

      ## tmpl/include/subscription_table.tmpl
      'Click to email [_1]' => 'Click to email [_1]',
      ## already defined
      ## 'Delete selected [_1] (x)' => 'Delete selected [_1] (x)',
      ## 'Delete' => 'Delete',
      ## 'Status' => 'Status',
      ## 'Email' => 'Email',
      ## 'IP Address' => 'IP Address',
      ## 'Modified' => 'Modified',
      ## 'Type' => 'Type',
      ## 'View' => 'View',
      ## 'Click to show only blocked [_1]' => 'Click to view only blocked [_1]',
      ## 'Blocked' => 'Blocked',
      ## 'Click to show only active [_1]' => 'Click to view only active [_1]',
      ## 'Active' => 'Active',
      ## 'Click to show only pending [_1]' => 'Click to view only pending [_1]',
      ## 'Pending' => 'Pending',
      ## 'Entry' => 'Entry',
      ## 'Category' => 'Category',
      ## 'Blog' => 'Blog',
      ## 'Subscription' => 'Subscription',
      ## 'Subscriptions' => 'Subscriptions',
      ## 'subscription' => 'subscription',
      ## 'subscriptions' => 'subscriptions',
      ## 'View' => 'View',

      ## tmpl/settings/blog.tmpl
      'Enable MT-Notifier for This Blog (Default)' => 'Enable MT-Notifier for This Blog (Default)',
      'Disable MT-Notifier for This Blog' => 'Disable MT-Notifier for This Blog',
      'Base URL' => 'Base URL',
      'Use System Setting for Base URL (Default)' => 'Use System Setting for Base URL (Default)',
      'Use Config File for Base URL' => 'Use Config File for Base URL',
      'Use This Blog Site URL for Base URL' => 'Use This Blog Site URL for Base URL',
      'Specify Another Address for Base URL' => 'Specify Another Address for Base URL',
      'Set Base URL' => 'Set Base URL',
      'Bypass' => 'Bypass',
      'Send Entry Notifications Prior to Subscription Date' => 'Send Entry Notifications Prior to Subscription Date',
      'Skip Entry Notifications Prior to Subscription Date (Default)' => 'Skip Entry Notifications Prior to Subscription Date (Default)',
      'Confirmation' => 'Confirmation',
      'Do not Send Any Confirmation Messages' => 'Do not Send Any Confirmation Messages',
      'Send Confirmation for New Subscriptions (Default)' => 'Send Confirmation for New Subscriptions (Default)',
      'Override' => 'Override',
      'Only Send Comments for Entry Subscriptions (Default)' => 'Only Send Comments for Entry Subscriptions (Default)',
      'Allow Blog and Category Subscription Comment Override' => 'Allow Blog and Category Subscription Comment Override',
      'Queue' => 'Queue',
      'Do not Submit any Notifications to Delivery Queue (Default)' => 'Do not Submit any Notifications to Delivery Queue (Default)',
      'Submit Notifications to Queue for Later Delivery' => 'Submit Notifications to Queue for Later Delivery',
      'Sender' => 'Sender',
      'Use System Address for Sender Address (Default)' => 'Use System Address for Sender Address (Default)',
      'Use Author Address for Sending Notifications' => 'Use Author Address for Sending Notifications',
      'Specify Another Address for Sending Notifications' => 'Specify Another Address for Sending Notifications',
      'Set Address' => 'Set Address',
      'Widgets' => 'Widgets',
      'Click here to install the [_1] Blog Subscription Widget' => 'Click here to install the [_1] Blog Subscription Widget',
      'Click here to install the [_1] Category Subscription Widget' => 'Click here to install the [_1] Category Subscription Widget',
      'Click here to install the [_1] Entry Subscription Widget' => 'Click here to install the [_1] Entry Subscription Widget',
      ## already defined
      ## 'Status' => 'Status',

      ## tmpl/settings/system.tmpl
      'Use Each Blog Site URL for Base URL' => 'Use Each Blog Site URL for Base URL',
      'Address to use when sending notifications and no other addresses are available:' => 'Address to use when sending notifications and no other addresses are available:',
      ## already defined
      ## 'Base URL' => 'Base URL',
      ## 'Use Config File for Base URL' => 'Use Config File for Base URL',
      ## 'Specify Another Address for Base URL' => 'Specify Another Address for Base URL',
      ## 'Set Base URL' => 'Set Base URL',
      ## 'Bypass' => 'Bypass',
      ## 'Send Entry Notifications Prior to Subscription Date' => 'Send Entry Notifications Prior to Subscription Date',
      ## 'Skip Entry Notifications Prior to Subscription Date (Default)' => 'Skip Entry Notifications Prior to Subscription Date (Default)',
      ## 'Confirmation' => 'Confirmation',
      ## 'Do not Send Any Confirmation Messages' => 'Do not Send Any Confirmation Messages',
      ## 'Send Confirmation for New Subscriptions (Default)' => 'Send Confirmation for New Subscriptions (Default)',
      ## 'Queue' => 'Queue',
      ## 'Do not Submit any Notifications to Delivery Queue (Default)' => 'Do not Submit any Notifications to Delivery Queue (Default)',
      ## 'Submit Notifications to Queue for Later Delivery' => 'Submit Notifications to Queue for Later Delivery',
      ## 'Sender' => 'Sender',

);

1;