# ===========================================================================
# A Movable Type plugin with subscription options for your installation
# Copyright 2003, 2004, 2005, 2006, 2007 Everitz Consulting <everitz.com>.
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
	
	## Notifier.pl
	'Subscription options for your Movable Type installation.' => 'Subscription options for your Movable Type installation.',

	## Notifier.pl (Actions)
	'Add Subscription(s)' => 'Add Subscription(s)',
	'Add Subscription Block(s)' => 'Add Subscription Block(s)',
	'View Subscription Count' => 'View Subscription Count',
	'Block Subscription(s)' => 'Block Subscription(s)',
	'Clear Subscription(s)' => 'Clear Subscription(s)',
	'Verify Subscription(s)' => 'Verify Subscription(s)',

	## Notifier.pl (Admin interface)
	'subscription address' => 'subscription address',
	'subscription addresses' => 'subscription addresses',
	'Delete selected subscription addresses (x)' => 'Delete selected subscription addresses (x)',
	'Subscriptions' => 'Subscriptions',
	'Create New Blog Subscription' => 'Create New Blog Subscription',
	'is currently providing this list. You may change this behavior from the plugins settings menu.' => 'is currently providing this list. You may change this behavior from the plugins settings menu.',
	'Only show' => 'Only show',
	'active' => 'active',
	'blocked' => 'blocked',
	'or' => 'or',
	'pending' => 'pending',
	'subscriptions' => 'subscriptions',
 	'Show all subscriptions' => 'Show all subscriptions',
	'(Showing all subscriptions.)' => '(Showing all subscriptions.)',
	'Showing only active subscriptions.' => 'Showing only active subscriptions.',
	'Showing only blocked subscriptions.' => 'Showing only blocked subscriptions.',
	'Showing only pending subscriptions.' => 'Showing only pending subscriptions.',
	'Add Subscription' => 'Add Subscription',
	'No subscriptions could be found.' => 'No subscriptions could be found.',
	'Edit Subscription List' => 'Edit Subscription List',
	'Subscriptions' => 'Subscriptions',
	'Only show blocked subscriptions' => 'Only show blocked subscriptions',
	'Blocked' => 'Blocked',
	'Only show active subscriptions' => 'Only show active subscriptions',
	'Active' => 'Active',
	'Only show pending subscriptions' => 'Only show pending subscriptions',
	'Pending' => 'Pending',
	'Subscription' => 'Subscription',

	## lib/Notifier.pm
	'You have successfully converted [_1] record[_2]!' => 'You have successfully converted [_1] record[_2]!',
	'You are not authorized to run this process!' => 'You are not authorized to run this process!',
	'Import Processing' => 'Import Processing',
	'No entry was found to match that subscription record!' => 'No entry was found to match that subscription record!',
	'No category was found to match that subscription record!' => 'No category was found to match that subscription record!',
	'No blog was found to match that subscription record!' => 'No blog was found to match that subscription record!',
	'Your opt-out record has been created!' => 'Your opt-out record has been created!',
	'Your subscription has been cancelled!' => 'Your subscription has been cancelled!',
	'No subscription record was found to match that locator!' => 'No subscription record was found to match that locator!',
	'Your request has been processed successfully!' => 'Your request has been processed successfully!',
	'The specified email address is not valid!' => 'The specified email address is not valid!',
	'The requested record key is not valid!' => 'The requested record key is not valid!',
	'That record already exists!' => 'That record already exists!',
	'Your request did not include a record key!' => 'Your request did not include a record key!',
	'Your request must include an email address!' => 'Your request must include an email address!',
	'Request Processing' => 'Request Processing',
	'No sender address available - aborting confirmation!' => 'No sender address available - aborting confirmation!',
	'subscribe to' => 'subscribe to',
	'opt-out of' => 'opt-out of',
	'Unknown MailTransfer method \'[_1]\'' => 'Unknown MailTransfer method \'[_1]\'',
	'[_1]: Sent [_2] queued notification[_3].' => '[_1]: Sent [_2] queued notification[_3].',
	'Loading template \'[_1]\' failed: [_2]' => 'Loading template \'[_1]\' failed: [_2]',
	# 'No system address - please configure one!' => 'No system address - please configure one!',
	'Specified blog unavailable - please check your data!' => 'Specified blog unavailable - please check your data!',
	'Invalid sender address - please reconfigure it!' => 'Invalid sender address - please reconfigure it!',
	'No sender address - please configure one!' => 'No sender address - please configure one!',

	## tmpl/header.tmpl
	'View' => 'View',

	## tmpl/notification_request.tmpl
	'You will receive an email to confirm your request momentarily.  If you do not, you may submit your request again.' => 'You will receive an email to confirm your request momentarily.  If you do not, you may submit your request again.',

	## tmpl/notifier_start.tmpl
	'Add Subscription(s)' => 'Add Subscription(s)',
	'Enter the email addresses, one per line, that you would like to subscribe to the current selection.  Click the Add Subscription(s) button to process the addresses when your list is complete.' => 'Enter the email addresses, one per line, that you would like to subscribe to the current selection.  Click the Add Subscription(s) button to process the addresses when your list is complete.',
	'Block Notification(s)' => 'Block Notification(s)',
	'Enter the email addresses, one per line, that you would like to enter into the system in order to block notifications.  These records are used to prevent notifications from being sent to a specific address, and are used in the event that a particular user no longer wants to receive anything from your site.  Click the Block Notification(s) button to process the addresses when your list is complete.' => 'Enter the email addresses, one per line, that you would like to enter into the system in order to block notifications.  These records are used to prevent notifications from being sent to a specific address, and are used in the event that a particular user no longer wants to receive anything from your site.  Click the Block Notification(s) button to process the addresses when your list is complete.',
	'Create Notification(s)' => 'Create Notification(s)',

	## tmpl/settings_blog.tmpl
	'Disable MT-Notifier for This Blog' => 'Disable MT-Notifier for This Blog',
	'Use System Setting for Notification List (Default)' => 'Use System Setting for Notification List (Default)',
	'Display Movable Type Notification List' => 'Display Movable Type Notification List',
	'Display MT-Notifier Subscription List' => 'Display MT-Notifier Subscription List',
	'Do not Send Any Confirmation Messages' => 'Do not Send Any Confirmation Messages',
	'Send Confirmation for New Subscriptions' => 'Send Confirmation for New Subscriptions',
	'Do not Submit any Notifications to Delivery Queue' => 'Do not Submit any Notifications to Delivery Queue',
	'Submit Notifications to Queue for Later Delivery' => 'Submit Notifications to Queue for Later Delivery',
	'Use System Address for Sender Address (Default)' => 'Use System Address for Sender Address (Default)',
	'Use Author Address for Sending Notifications' => 'Use Author Address for Sending Notifications',
	'Use This Address for Sending Notifications:' => 'Use This Address for Sending Notifications:',

	## tmpl/settings_system
	'Display Movable Type Notification List' => 'Display Movable Type Notification List',
	'Display MT-Notifier Subscription List' => 'Display MT-Notifier Subscription List',
	'Do not Send any Confirmation Messages' => 'Do not Send any Confirmation Messages',
	'Send Confirmation for New Subscriptions' => 'Send Confirmation for New Subscriptions',
	'Do not Submit any Notifications to Delivery Queue' => 'Do not Submit any Notifications to Delivery Queue',
	'Submit Notifications to Queue for Later Delivery' => 'Submit Notifications to Queue for Later Delivery',
	'Address to use when sending notifications and no other addresses are available:' => 'Address to use when sending notifications and no other addresses are available:',

	## tmpl/subscription_view.tmpl
	'View Subscription Count' => 'View Subscription Count',
	'Total' => 'Total',
	'Here is the count of current subscribers for your selected items.' => 'Here is the count of current subscribers for your selected items.',
	'Blog Name' => 'Blog Name',
	'Category Label' => 'Category Label',
	'Entry Title' => 'Entry Title',
	'Opt-Out Records' => 'Opt-Out Records',
	'Subscriptions' => 'Subscriptions',

	## tmpl/email/confirmation.tmpl
	'requires you to use a double-opt system for making any changes to your subscription information' => 'requires you to use a double-opt system for making any changes to your subscription information',
	'Because you, or someone using your email address, recently submitted a request at' => 'Because you, or someone using your email address, recently submitted a request at',
	', you are being sent this confirmation to verify that the request is genuine.' => ', you are being sent this confirmation to verify that the request is genuine.',
	'The request is to' => 'The request is to',
	'Please confirm your request by clicking this link' => 'Please confirm your request by clicking this link',
	'Use this link if you would like to visit before confirming this request' => 'Use this link if you would like to visit before confirming this request',
	'If you did not make this request, do nothing.  You will receive no further reminders of this request.  If you did make this request, but there are errors in the request, you can simply submit a new one to correct any problems.  Confirmation of that request will follow your re-submission.' => 'If you did not make this request, do nothing.  You will receive no further reminders of this request.  If you did make this request, but there are errors in the request, you can simply submit a new one to correct any problems.  Confirmation of that request will follow your re-submission.',
	
	## tmpl/email/confirmation-subject.tmpl
	'Please confirm your request to' => 'Please confirm your request to',
	'You have subscribed to' => 'You have subscribed to',

	## tmpl/email/notification.tmpl
	'Summary: ' => 'Summary: ',
	'Author: ' => 'Author: ',
	'Website: ' => 'Website: ',
	'View the entire entry:' => 'View the entire entry:',
	'Cancel this subscription:' => 'Cancel this subscription:',
	'Block all notifications from this site:' => 'Block all notifications from this site:',

	## tmpl/email/confirmation-subject.tmpl
	'New Entry from' => 'New Entry from',
	'New Comment from' => 'New Comment from',
	'on' => 'on',

);

1;