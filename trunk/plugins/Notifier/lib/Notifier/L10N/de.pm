# ===========================================================================
# A Movable Type plugin with subscription options for your installation
# Copyright 2003, 2004, 2005, 2006, 2007 Everitz Consulting <everitz.com>.
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
package Notifier::L10N::de;

use strict;
use base 'Notifier::L10N::en_us';
use vars qw( %Lexicon );

## If you want to create a new translation, follow these five steps:
##
## - Copy this file to <lowercase language code>.pm
##
## - Replace the "package" line with:
## package Notifier::L10N::<lowercase language code>;
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
	'Subscription options for your Movable Type installation.' => 'Mitteilungsoptionen f&uuml;r Ihre Movable Type Installation.',

	## Notifier.pl (Actions)
	'Add Subscription(s)' => 'Mitteilung(en) hinzuf&uuml;gen',
	'Add Subscription Block(s)' => 'Blockierte Mitteilung(en) hinzuf&uuml;gen',
	'View Subscription Count' => 'Anzahl der Mitteilungen anzeigen',
	'Block Subscription(s)' => 'Mitteilung(en) blockieren',
	'Clear Subscription(s)' => 'Mitteilung(en) zur&uuml;cksetzen',
	'Verify Subscription(s)' => 'Mitteilung(en) best&auml;tigen',

	## Notifier.pl (Admin interface)
	'subscription address' => 'Mitteilungs-Adresse',
	'subscription addresses' => 'Mitteilungs-Adressen',
	'Delete selected subscription addresses (x)' => 'L&ouml;sche ausgew&auml;hlte Mitteilungs-Adressen (x)',
	'Subscriptions' => 'Abonnements',
	'Create New Blog Subscription' => 'Erstelle neues Blog Abonnement',
	'[_1] is currently providing this list. You may change this behavior from the plugins settings menu.' => '[_1] bietet derzeit diese Liste an. Sie k&ouml;nnen dieses Verhalten im Menu der Plugineinstellungen &auml;ndern.',
	'Only show' => 'Zeige nur',
	'active' => 'aktiv',
	'blocked' => 'blockiert',
	'or' => 'oder',
	'pending' => 'ausstehend',
	'subscriptions' => 'Abonnements',
	 'Show all subscriptions' => 'Zeige alle Mitteilungen',
	'(Showing all subscriptions.)' => '(alle Mitteilungen werden angezeigt.)',
	'Showing only active subscriptions.' => 'Zeige nur aktive Mitteilungen.',
	'Showing only blocked subscriptions.' => 'Zeige nur blockierte Mitteilungen.',
	'Showing only pending subscriptions.' => 'Zeige nur ausstehende Mitteilungen.',
	'Add Subscription' => 'Mitteilung(en) hinzuf&uuml;gen',
	'No subscriptions could be found.' => 'Es konten keine Mitteilungen gefunden werden.',
	'Edit Subscription List' => 'Mitteilungsliste bearbeiten',
	'Subscriptions' => 'Mitteilungen',
	'Only show blocked subscriptions' => 'Zeige nur blockierte Mitteilungen.',
	'Blocked' => 'Blockiert',
	'Only show active subscriptions' => 'Zeige nur aktive Mitteilungen.',
	'Active' => 'Aktiv',
	'Only show pending subscriptions' => 'Zeige nur ausstehende Mitteilungen.',
	'Pending' => 'Ausstehend',
	'Subscription' => 'Mitteilung',

	## lib/Notifier.pm
	'You have successfully converted [_1] record[_2]!' => 'Sie haben [_1] record[_2] erfolgreich konvertiert!',
	'You are not authorized to run this process!' => 'Sie sind nicht berechtigt, diesen Prozess auszuf&uuml;hren!',
	'Import Processing' => 'Import Processing',
	'No entry was found to match that subscription record!' => 'Es wurde kein Eintrag gefunden, der dieser Anmeldung entspricht!',
	'No category was found to match that subscription record!' => 'Es wurde keine Kategorie gefunden, die dieser Anmeldung entspricht!',
	'No blog was found to match that subscription record!' => 'Es wurde kein Blog gefunden, der dieser Anmeldung entspricht!',
	'Your opt-out record has been created!' => 'Ihr opt-out Eintrag wurde erstellt!',
	'Your subscription has been cancelled!' => 'Ihre Anmelung wurde abgebrochen!',
	'No subscription record was found to match that locator!' => 'Es wurde keine Anmeldung gefunden, die diesem Verweis entspricht!',
	'Your request has been processed successfully!' => 'Ihre Anfrage wurde erfolgreich verarbeitet!',
	'The specified email address is not valid!' => 'Die angegebene E-Mail Adresse ist nicht g&uuml;ltig!',
	'The requested record key is not valid!' => 'Der angefragte Schl&uuml;ssel ist nicht g&uuml;ltig!',
	'That record already exists!' => 'Dieser Eintrag existiert bereits!',
	'Your request did not include a record key!' => 'Ihre Anfrage beinhaltet keinen Schl&uuml;ssel!',
	'Your request must include an email address!' => 'Ihre Anfrage muss eine E-Mail Adresse enthalten!',
	'Request Processing' => 'Request Processing',
	'No sender address available - aborting confirmation!' => 'Kein Absender verf&uuml;gbar - Best&auml;tigung wird abgebrochen!',
	'subscribe to' => 'anmelden bei',
	'opt-out of' => 'opt-out von',
	'Unknown MailTransfer method \'[_1]\'' => 'Unbekannte MailTransfer Methode \'[_1]\'',
	'[_1]: Sent [_2] queued notification[_3].' => '[_1]: [_2] Benachrichtigungen gesendet.',
	'Loading template \'[_1]\' failed: [_2]' => 'Laden der Vorlage \'[_1]\' gescheitert: [_2]',
	# 'No system address - please configure one!' => 'Keine Systemadresse - bitte richten Sie eine ein!',
	'Specified blog unavailable - please check your data!' => 'Angegebener Blog nicht verf&uuml;gbar - bitte &uuml;berpr&uuml;fen Sie Ihre Angaben!',
	'Invalid sender address - please reconfigure it!' => 'Ung&uuml;ltige Absenderadresse - bitte &uuml;berpr&uuml;fen Sie Ihre Angaben!',
	'No sender address - please configure one!' => 'Keine Absenderadresse - bitte richten Sie eine ein!',

	## tmpl/header.tmpl
	'View' => 'Ansicht',

	## tmpl/notification_request.tmpl
	'You will receive an email to confirm your request momentarily.  If you do not, you may submit your request again.' => 'Sie erhalten in K&uuml;rze eine E-Mail um Ihre Anmeldung zu best&auml;tigen. Wenn Sie keine E-Mail erhalten, melden Sie sich erneut an.',

	## tmpl/notifier_start.tmpl
	'Add Subscription(s)' => 'Mitteilung(en) hinzuf&uuml;gen',
	'Enter the email addresses, one per line, that you would like to subscribe to the current selection.  Click the Add Subscription(s) button to process the addresses when your list is complete.' => 'Geben Sie zeilenweise die E-Mail Adressen an, die Sie der Auswahl hinzuf&uuml;gen m&ouml;chten. Klicken Sie \"Mitteilung(en) hinzuf&uuml;gen\" um die komplette Liste anzumelden.',
	'Block Notification(s)' => 'Mitteilung(en) blockieren',
	'Enter the email addresses, one per line, that you would like to enter into the system in order to block notifications.  These records are used to prevent notifications from being sent to a specific address, and are used in the event that a particular user no longer wants to receive anything from your site.  Click the Block Notification(s) button to process the addresses when your list is complete.' => 'Geben Sie zeilenweise die E-Mail Adressen an, die Sie vom System blockieren lassen m&ouml;chten.Diese Eintr&auml;ge werden verwendet um zu verhindern, dass Benachrichtigungen an bestimmte Adressen gesendet werden. Dies geschieht, wenn ein Benutzer angibt, nicht l&auml;nger von Ihrer Seite benachrichtigt zu werden.Klicken Sie \"Mitteilung(en) blockieren\" um die komplette Liste zu blockieren.',
	'Create Notification(s)' => 'Mitteilung(en) erstellen',

	## tmpl/settings_blog.tmpl
	'Disable MT-Notifier for This Blog' => 'MT-Notifier f&uuml;r diesen Blog deaktivieren',
	'Use System Setting for Notification List (Default)' => 'Systemeinstellungen f&uuml;r Mitteilungslisten verwenden (Default)',
	'Display Movable Type Notification List' => 'Movable Type Mitteilungsliste anzeigen',
	'Display MT-Notifier Subscription List' => 'MT-Notifier Mitteilungsliste anzeigen',
	'Do not Send Any Confirmation Messages' => 'Sende keine Best&auml;tigungsnachrichten',
	'Send Confirmation for New Subscriptions' => 'Sende Best&auml;tigung f&uuml;r neue Anmeldungen',
	'Do not Submit any Notifications to Delivery Queue' => 'Sende keine Benachrichtigungen zur Warteschlange',
	'Submit Notifications to Queue for Later Delivery' => 'Speichere Benachrichtigungen in die Warteschlange f&uuml;r sp&auml;tere Zustellung',
	'Use System Address for Sender Address (Default)' => 'Verwende Systemadresse als Absenderadresse (Default)',
	'Use Author Address for Sending Notifications' => 'Verwende Autoradresse f&uuml;r Benachrichtigungen',
	'Use This Address for Sending Notifications:' => 'Verwende diese Adresse f&uuml;r Benachrichtigungen:',

	## tmpl/settings_system
	'Display Movable Type Notification List' => 'Movable Type Mitteilungsliste anzeigen',
	'Display MT-Notifier Subscription List' => 'MT-Notifier Mitteilungsliste anzeigen',
	'Do not Send any Confirmation Messages' => 'Sende keine Best&auml;tigungsnachrichten',
	'Send Confirmation for New Subscriptions' => 'Sende Best&auml;tigung f&uuml;r neue Anmeldungen',
	'Do not Submit any Notifications to Delivery Queue' => 'Sende &uuml;berhaupt keine Benachrichtigungen zur Warteschlange',
	'Submit Notifications to Queue for Later Delivery' => 'Speichere Benachrichtigungen in die Warteschlange f&uuml;r sp&auml;tere Zustellung',
	'Address to use when sending notifications and no other addresses are available:' => 'Adresse, welche verwendet wird, wenn Benachrichtigungen gesendet werden und keine andere Adresse verf&uuml;gbar ist:',

	## tmpl/subscription_view.tmpl
	'View Subscription Count' => 'Anzahl der Mitteilungen anzeigen',
	'Total' => 'Insgesamt',
	'Here is the count of current subscribers for your selected items.' => 'Hier ist die Anzahl der derzeitigen Abonnenten f&uuml;r die Auswahl',
	'Blog Name' => 'Blog Name',
	'Category Label' => 'Kategoriebezeichnung',
	'Entry Title' => 'Eintrags Titel',
	'Opt-Out Records' => 'Opt-Out Eintr&auml;ge',
	'Subscriptions' => 'Mitteilungen',

	## tmpl/email/confirmation.tmpl
	'requires you to use a double-opt system for making any changes to your subscription information' => 'verwendet f&uuml;r jede &Auml;nderung an Ihren Anmeldeinformationen ein double-opt System.',
	'Because you, or someone using your email address, recently submitted a request at' => 'Weil Sie oder jemand, der Ihre E-Mail Adresse verwendet hat, k&uuml;rzlich eine Anmeldung bei',
	', you are being sent this confirmation to verify that the request is genuine.' => '&uuml;bermittelt hat, erhalten Sie diese Best&auml;tigung um sicherzustellen, dass die Anmeldung gewollt ist.',
	'The request is to' => 'Die Anmeldung bezieht sich auf',
	'Please confirm your request by clicking this link' => 'Bitte best&auml;tigten Sie Ihre Anfrage, indem Sie diesen Link besuchen',
	'Use this link if you would like to visit before confirming this request' => 'Verwenden Sie diesen Link, wenn Sie die WebSite besuchen m&ouml;chten, bevor Sie die Anmeldung best&auml;tigen.',
	'If you did not make this request, do nothing.  You will receive no further reminders of this request.  If you did make this request, but there are errors in the request, you can simply submit a new one to correct any problems.  Confirmation of that request will follow your re-submission.' => 'Wenn Sie diese Anmeldung nicht get&auml;tigt haben, tun Sie nichts. Sie werden keine weiteren Benachrichtigungen &uuml;ber diese Anmeldung erhalten.Wenn Sie diese Anmeldung get&auml;tigt haben, aber es ist ein Fehler aufgetreten, k&ouml;nnen Sie die Anmeldung einfach wiederholen.Die Best&auml;tigung dieser Anmeldung wird Ihrer erneuten Anmeldung folgen.',
	
	## tmpl/email/confirmation-subject.tmpl
	'Please confirm your request to' => 'Bitte best&auml;tigen Sie Ihre Anmeldung bei',
	'You have subscribed to' => 'Sie haben sich angemeldet bei',

	## tmpl/email/notification.tmpl
	'Summary: ' => 'Zusammenfassung: ',
	'Author: ' => 'Autor: ',
	'Website: ' => 'WebSite: ',
	'View the entire entry:' => 'Den ganzen Eintrag anzeigen:',
	'Cancel this subscription:' => 'Dieses Abonnement k&uuml;ndigen:',
	'Block all notifications from this site:' => 'Alle Benachrichtigungen von dieser Seite blockieren:',

	## tmpl/email/confirmation-subject.tmpl
	'New Entry from' => 'Neuer Eintrag von',
	'New Comment from' => 'Neuer Kommentar von',
	'on' => 'bei',

);

1;
