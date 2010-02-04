# ===========================================================================
# A Movable Type plugin with subscription options for your installation
# Copyright 2003-2010 Everitz Consulting <everitz.com>.
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

);

1;