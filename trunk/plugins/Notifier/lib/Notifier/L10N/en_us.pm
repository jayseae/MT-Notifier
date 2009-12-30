# ===========================================================================
# A Movable Type plugin with subscription options for your installation
# Copyright 2003-2008 Everitz Consulting <everitz.com>.
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

      ## Notifier.pl
      'Subscription options for your Movable Type installation.' => 'Subscription options for your Movable Type installation.',

      ## Notifier.pl (blog settings)
      'Disable MT-Notifier for This Blog' => 'Disable MT-Notifier for This Blog',
      'Do not Send Any Confirmation Messages' => 'Do not Send Any Confirmation Messages',
      'Send Confirmation for New Subscriptions' => 'Send Confirmation for New Subscriptions',
      'Do not Submit any Notifications to Delivery Queue' => 'Do not Submit any Notifications to Delivery Queue',
      'Submit Notifications to Queue for Later Delivery' => 'Submit Notifications to Queue for Later Delivery',
      'Use System Address for Sender Address (Default)' => 'Use System Address for Sender Address (Default)',
      'Use Author Address for Sending Notifications' => 'Use Author Address for Sending Notifications',
      'Use This Address for Sending Notifications:' => 'Use This Address for Sending Notifications:',
      'Widgets' => 'Widgets',
      'Click here to install the MT-Notifier Blog Subscription Widget' => 'Click here to install the MT-Notifier Blog Subscription Widget',
      'Click here to install the MT-Notifier Category Subscription Widget' => 'Click here to install the MT-Notifier Category Subscription Widget',
      'Click here to install the MT-Notifier Entry Subscription Widget' => 'Click here to install the MT-Notifier Entry Subscription Widget',

      ## Notifier.pl (system settings)
      'Do not Send any Confirmation Messages' => 'Do not Send any Confirmation Messages',
      'Send Confirmation for New Subscriptions' => 'Send Confirmation for New Subscriptions',
      'Do not Submit any Notifications to Delivery Queue' => 'Do not Submit any Notifications to Delivery Queue',
      'Submit Notifications to Queue for Later Delivery' => 'Submit Notifications to Queue for Later Delivery',
      'Address to use when sending notifications and no other addresses are available:' => 'Address to use when sending notifications and no other addresses are available:',

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
      'No sender address available - aborting confirmation!' => 'No sender address available - aborting confirmation!',
      'subscribe to' => 'subscribe to',
      'opt-out of' => 'opt-out of',
      'Comment' => 'Comment',
      'Unknown MailTransfer method \'[_1]\'' => 'Unknown MailTransfer method \'[_1]\'',
      '[_1]: Sent [_2] queued notification[_3].' => '[_1]: Sent [_2] queued notification[_3].',

      ## lib/Notifier/App.pm
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
      'Insufficient permissions for installing templates for this weblog.' => 'Insufficient permissions for installing templates for this weblog.',
      '[_1] Blog Widget: Template Already Exists' => '[_1] Blog Widget: Template Already Exists',
      '[_1] Category Widget: Template Already Exists' => '[_1] Category Widget: Template Already Exists',
      '[_1] Entry Widget: Template Already Exists' => '[_1] Entry Widget: Template Already Exists',
      'Error creating new template: [_1]' => 'Error creating new template: [_1]',
      ## already defined
      ## 'Subscriptions' => 'Subscriptions',

      ## lib/Notifier/App.pm (widget)
      'Subscribe to Blog', => 'Subscribe to Blog',
      'Subscribe to Category', => 'Subscribe to Category',
      'Subscribe to Entry', => 'Subscribe to Entry',
      'Go', => 'Go',
      'Powered by [_1]' => 'Powered by [_1]',

      ## lib/Notifier/Import.pm (currently not used)
      'You have successfully converted [_1] record[_2]!' => 'You have successfully converted [_1] record[_2]!',
      'You are not authorized to run this process!' => 'You are not authorized to run this process!',
      'Import Processing' => 'Import Processing',

      ## lib/Notifier/Plugin.pm
      'Add Subscription(s)' => 'Add Subscription(s)',
      'Add Subscription Block(s)' => 'Add Subscription Block(s)',
      'View Subscription Count' => 'View Subscription Count',
      'Block Subscription(s)' => 'Block Subscription(s)',
      'Clear Subscription(s)' => 'Clear Subscription(s)',
      'Verify Subscription(s)' => 'Verify Subscription(s)',
      'Write History Records' => 'Write History Records',

      ## lib/Notifier/Util.pm
      'Loading template \'[_1]\' failed: [_2]' => 'Loading template \'[_1]\' failed: [_2]',
      'Specified blog unavailable - please check your data!' => 'Specified blog unavailable - please check your data!',
      'Invalid sender address - please reconfigure it!' => 'Invalid sender address - please reconfigure it!',
      'No sender address - please configure one!' => 'No sender address - please configure one!',

      ## templates

      ## tmpl/list.tmpl
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
      'Create [_1]' => 'Create [_1]',
      'Email' => 'Email',
      'Actions' => 'Actions',
      'Add [_1]' => 'Add [_1]',
      'Status' => 'Status',
      'Type' => 'Type',
      'Date Added' => 'Date Added',
      'Click to show only blocked [_1]' => 'Click to show only blocked [_1]',
      'Blocked' => 'Blocked',
      'Click to show only active [_1]' => 'Click to show only active [_1]',
      'Active' => 'Active',
      'Click to show only pending [_1]' => 'Click to show only pending [_1]',
      'Pending' => 'Pending',
      'Click to edit contact' => 'Click to edit contact',
      'Save changes' => 'Save changes',
      'Save' => 'Save',
      ## already defined
      ## 'Entry' => 'Entry',
      ## 'Category' => 'Category',
      ## 'Blog' => 'Blog',
      ## 'subscription' => 'subscription',
      ## 'subscriptions' => 'subscriptions',
      ## 'Subscription' => 'Subscription',
      ## 'Subscriptions' => 'Subscriptions',

      ## tmpl/request.tmpl
      'You will receive an email to confirm your request momentarily.  If you do not, you may submit your request again.' => 'You will receive an email to confirm your request momentarily.  If you do not, you may submit your request again.',

      ## tmpl/dialog/close.tmpl
      'Subscription Status' => 'Subscription Status',
      '[_1] email address(es) added to [_2] selection(s).' => '[_1] email address(es) added to [_2] selection(s).',
      'If the numbers don\'t match, you should check your data, wait a moment and try adding them again.' => 'If the numbers don\'t match, you should check your data, wait a moment and try adding them again.',
      'Close' => 'Close',

      ## tmpl/dialog/count.tmpl
      'Subscription Count' => 'Subscription Count',
      '[_1] has [_2] subscriptions and [_3] subscription blocks.' => '[_1] has [_2] subscriptions and [_3] subscription blocks.',
      'There are [_1] subscriptions and [_2] subscription blocks in this list.' => 'There are [_1] subscriptions and [_2] subscription blocks in this list.',
      # already defined
      # 'Close' => 'Close',

      ## tmpl/dialog/start.tmpl
      'Enter the email addresses, one per line, that you would like to subscribe to the current selection.  Click the Create Subscription(s) button to process the addresses when your list is complete.' => 'Enter the email addresses, one per line, that you would like to subscribe to the current selection.  Click the Create Subscription(s) button to process the addresses when your list is complete.',
      'Enter the email addresses, one per line, that you would like to enter into the system in order to block subscriptions.  These records are used to prevent subscriptions from being sent to a specific address, and are used in the event that a particular user no longer wants to receive anything from your site.  Click the Block Subscription(s) button to process the addresses when your list is complete.' => 'Enter the email addresses, one per line, that you would like to enter into the system in order to block subscriptions.  These records are used to prevent subscriptions from being sent to a specific address, and are used in the event that a particular user no longer wants to receive anything from your site.  Click the Block Subscription(s) button to process the addresses when your list is complete.',
      'Create Subscription(s)' => 'Create Subscription(s)',
      # already defined
      # 'Add Subscription(s)' => 'Add Subscription(s)',
      # 'Block Subscription(s)' => 'Block Subscription(s)',

      'Subscription Count' => 'Subscription Count',
      '[_1] has [_2] subscriptions and [_3] subscription blocks.' => '[_1] has [_2] subscriptions and [_3] subscription blocks.',
      'There are [_1] subscriptions and [_2] subscription blocks in this list.' => 'There are [_1] subscriptions and [_2] subscription blocks in this list.',

      ## tmpl/email/confirmation.tmpl
      'requires you to use a double-opt system for making any changes to your subscription information' => 'requires you to use a double-opt system for making any changes to your subscription information',
      'Because you, or someone using your email address, recently submitted a request at' => 'Because you, or someone using your email address, recently submitted a request at',
      ', you are being sent this confirmation to verify that the request is genuine.' => ', you are being sent this confirmation to verify that the request is genuine.',
      'The request is to' => 'The request is to',
      'Please confirm your request by clicking this link' => 'Please confirm your request by clicking this link',
      'Use this link if you would like to visit before confirming this request' => 'Use this link if you would like to visit before confirming this request',
      'If you did not make this request, do nothing.  You will receive no further reminders of this request.  If you did make this request, but there are errors in the request, you can simply submit a new one to correct any problems.  Confirmation of that request will follow your re-submission.' => 'If you did not make this request, do nothing.  You will receive no further reminders of this request.  If you did make this request, but there are errors in the request, you can simply submit a new one to correct any problems.  Confirmation of that request will follow your re-submission.',
      # already defined
      # 'subscribe to' => 'subscribe to',
      # 'opt-out of' => 'opt-out of',

      ## tmpl/email/confirmation-subject.tmpl
      'Please confirm your request to' => 'Please confirm your request to',
      # already defined
      # 'subscribe to' => 'subscribe to',
      # 'opt-out of' => 'opt-out of',

      ## tmpl/email/notification.tmpl
      'Summary: ' => 'Summary: ',
      'Author: ' => 'Author: ',
      'Website: ' => 'Website: ',
      'View the entire entry:' => 'View the entire entry:',
      'Cancel this subscription:' => 'Cancel this subscription:',
      'Block all notifications from this site:' => 'Block all notifications from this site:',

      ## tmpl/email/notification-subject.tmpl
      'New Entry from' => 'New Entry from',
      'New Comment on' => 'New Comment on',

);

1;