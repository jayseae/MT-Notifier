# ===========================================================================
# A Movable Type plugin with subscription options for your installation
# Copyright 2003, 2004, 2005, 2006, 2007 Everitz Consulting <everitz.com>.
#
# This program may not be redistributed without permission.
# ===========================================================================
package Notifier::L10N::it;

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
      'Subscription options for your Movable Type installation.' => 'Opzioni per gli abbonamenti di Movable Type.',

      ## Notifier.pl (blog settings)
      'Disable MT-Notifier for This Blog' => 'Disabilita MT-Notifier per questo blog',
      'Do not Send Any Confirmation Messages' => 'Non inviare alcun messaggio di conferma',
      'Send Confirmation for New Subscriptions' => 'Invia messaggio di conferma per i nuovi abbonamenti',
      'Do not Submit any Notifications to Delivery Queue' => 'Non inviare le notifiche alla coda di invio',
      'Submit Notifications to Queue for Later Delivery' => 'Non inviare le notifiche alla coda di invio',
      'Use System Address for Sender Address (Default)' => 'Usa l\'indirizzo di sistema come mittente (Predefinito)',
      'Use Author Address for Sending Notifications' => 'Usa l\'indirizzo del autore come mittente',
      'Use This Address for Sending Notifications:' => 'Usa questo indirizzo come mittente delle notifiche:',
      'Widgets' => 'Widget',
      'Click here to install the MT-Notifier Blog Subscription Widget' => 'Clicca qui per installare il widget per gli abbonamenti al blog di MT-Notifier',
      'Click here to install the MT-Notifier Category Subscription Widget' => 'Clicca qui per installare il widget per gli abbonamenti alla categoria di MT-Notifier',
      'Click here to install the MT-Notifier Entry Subscription Widget' => 'Clicca qui per installare il widget per gli abbonamenti per gli articoli di MT-Notifier',

      ## Notifier.pl (system settings)
      'Do not Send any Confirmation Messages' => 'Non inviare mesggi di conferma',
      'Send Confirmation for New Subscriptions' => 'Invia messaggio di conferma per i nuovi abboanmenti',
      'Do not Submit any Notifications to Delivery Queue' => 'Non inviare le notifiche alla coda di invio',
      'Submit Notifications to Queue for Later Delivery' => 'Non inviare le notifiche alla coda di invio',
      'Address to use when sending notifications and no other addresses are available:' => 'Indirizzo da usare per inviare le notifiche e non sono disponibili altri indirizzi:',

      ## lib/Notifier/Data.pm
      'Subscription' => 'Abbonamento',
      'Subscriptions' => 'Abbonamenti',

      ## lib/Notifier/History.pm
      'Subscription History' => 'Storia abbonamenti',
      'Subscription History Records' => 'Record della storia dell\'abbonamento',

      ## lib/Notifier/Queue.pm
      'Subscription Queue' => 'Coda abbonamento',
      'Subscription Queue Records' => 'Record della coda dell\'abbonamento',

      ## lib/Notifier.pm
      'Entry' => 'Articolo',
      'Category' => 'Categoria',
      'Blog' => 'Blog',
      'No sender address available - aborting confirmation!' => 'Indirizzo del mittente mancante, termino la conferma!',
      'subscribe to' => 'abbonati a',
      'opt-out of' => 'di opt-of',
      'Comment' => 'Commento',
      'Unknown MailTransfer method \'[_1]\'' => 'MailTransfer sconosciuto \'[_1]\'',
      '[_1]: Sent [_2] queued notification[_3].' => '[_1]: Ha inviato [_2] notifiche in coda[_3].',

      ## lib/Notifier/App.pm
      'No entry was found to match that subscription record!' => 'Non è stato trovato alcun articolo che corrisponda all\'abbonamento!',
      'No category was found to match that subscription record!' => 'Non è stata trovata alcuna categoria che corrisponda all\'abbonamento!',
      'No blog was found to match that subscription record!' => 'Non è stato trovato alcun blog che corrisponda all\'abbonamento!',
      'The specified email address is not valid!' => 'L\'indirizzo specificato non è valido!',
      'The requested record key is not valid!' => 'La chiave del record richiesta non è valida!',
      'That record already exists!' => 'Il record esiste già!',
      'Your request has been processed successfully!' => 'La richiesta è stata completata con successo!',
      'Your subscription has been cancelled!' => 'L\'abbonamento è stato annullato!',
      'No subscription record was found to match that locator!' => 'Non è stato trovato alcun record che corrisponda al dato!',
      'Your request did not include a record key!' => 'La tua richiesta non include una chiave di record!',
      'Your request must include an email address!' => 'La richiesta deve includere un indirizzo di posta elettronica!',
      'Request Processing' => 'Richiesta in corso',
      'Insufficient permissions for installing templates for this weblog.' => 'Permessi insufficienti per installere nuovi modelli su questo blog.',
      '[_1] Blog Widget: Template Already Exists' => 'Widget per blog [_1]: Il modello esiste già',
      '[_1] Category Widget: Template Already Exists' => 'Widget per categoria [_1]: Il modello esiste già',
      '[_1] Entry Widget: Template Already Exists' => 'Widget per articolo [_1]: Il modello esiste già',
      'Error creating new template: [_1]' => 'Errore durante la creazione di un nuovo modello: [_1]',

      ## lib/Notifier/App.pm (widget)
      'Subscribe to Blog', => 'Subscribe to Blog',
      'Subscribe to Category', => 'Subscribe to Category',
      'Subscribe to Entry', => 'Subscribe to Entry',
      'Go', => 'Go',
      'Powered by [_1]' => 'Creato con [_1]',

      ## lib/Notifier/Import.pm (currently not used)
      'You have successfully converted [_1] record[_2]!' => 'Hai convertito con successo [_1] record!',
      'You are not authorized to run this process!' => 'Non sei autorizzato ad eseguire questo processo!',
      'Import Processing' => 'Importazione in corso',

      ## lib/Notifier/Plugin.pm
      'Add Subscription(s)' => 'Aggiungi abbonamento',
      'Add Subscription Block(s)' => 'Aggiungi blocco abbonamento',
      'View Subscription Count' => 'Mostra contatore abbonamenti',
      'Block Subscription(s)' => 'Blocca abbonamento',
      'Clear Subscription(s)' => 'Azzera abbonamenti',
      'Verify Subscription(s)' => 'Verifica abbonamento',

      ## lib/Notifier/Util.pm
      'Loading template \'[_1]\' failed: [_2]' => 'Caricamento del modello \'[_1]\' fallito: [_2]',
      'Specified blog unavailable - please check your data!' => 'Blog specificato non disponibile, controlla i tuoi dati!',
      'Invalid sender address - please reconfigure it!' => 'Indirizzo del mittente non valido, controlla la configurazione!',
      'No sender address - please configure one!' => 'Indirizzo del destinatario assente, controlla che sia presente!',

      ## tmpl/list.tmpl
      'Manage [_1]' => 'Gestisci [_1]',
      'You have added a [_1] for [_2].' => 'Hai aggiunto un [_1] per [_2].',
      'You have successfully deleted the selected [_1].' => 'Hai cancellato con successo gli [_1] selezzionati.',
      'Quickfilters' => 'Filtri veloci',
      'Useful links' => 'Collegamenti utili',
      'Download [_1] (CSV)' => 'Scarica [_1] (CSV)',
      'Showing only: [_1]' => 'Mostro solo: [_1]',
      'Remove filter' => 'Rimuovi filtro',
      'All [_1]' => 'Tutti [_1]',
      'change' => 'cambia',
      '[_1] where [_2] is [_3]' => '[_1] dove [_2] è [_3]',
      'Show only [_1] where' => 'Mostro solo [_1] dove',
      'status' => 'stato',
      'is' => 'è',
      'active' => 'attivo',
      'blocked' => 'bloccato',
      'pending' => 'in attesa',
      'Filter' => 'Filtra',
      'Cancel' => 'Annulla',
      'Delete selected [_1] (x)' => 'Cancella [_1] selezionati (x)',
      'Delete' => 'Cancella',
      'Create [_1]' => 'Crea [_1]',
      'Email' => 'Posta elettronica',
      'Actions' => 'Azioni',
      'Add [_1]' => 'Aggiungi [_1]',
      'Status' => 'Stato',
      'Type' => 'Tipo',
      'Date Added' => 'Aggiunto il',
      'Click to show only blocked [_1]' => 'Clicca per mostrare solo gli [_1] bloccati',
      'Blocked' => 'Bloccato',
      'Click to show only active [_1]' => 'Clicca per mostrare solo gli [_1] attivi',
      'Active' => 'Attivo',
      'Click to show only pending [_1]' => 'Clica per mostrare solo gli [_1] in attesa',
      'Pending' => 'In attesa',
      'Click to edit contact' => 'Clicca per modificare il contatto',
      'Save changes' => 'Salva cambiamenti',
      'Save' => 'Salva',

      ## tmpl/request.tmpl
      'You will receive an email to confirm your request momentarily.  If you do not, you may submit your request again.' => 'Riceverai un messaggio di posta per confermare la tua richiesta. Se ci sono peoblemi riprova ad inviare la richiesta.',

      ## tmpl/dialog/close.tmpl
      'Subscription Status' => 'Stato abbonamento',
      '[_1] email address(es) added to [_2] selection(s).' => '[_1] indirizzi di posta elettronica aggiunti a [_2] selezioni.',
      'If the numbers don\'t match, you should check your data, wait a moment and try adding them again.' => 'Se i numeri non coincidono devi controllare i dati, aspetta un momento e riprova ad aggiungerli più tardi.',
      'Close' => 'Chiudi',

      ## tmpl/dialog/count.tmpl
      'Subscription Count' => 'Contatore abbonamenti',
      '[_1] has [_2] subscriptions and [_3] subscription blocks.' => '[_1] ha [_2] abbonamenti di cui [_3] blocati.',
      'There are [_1] subscriptions and [_2] subscription blocks in this list.' => 'Ci sono [_1] abbonamenti e [_2] bloccati in questa lista.',

      ## tmpl/dialog/start.tmpl
      'Enter the email addresses, one per line, that you would like to subscribe to the current selection.  Click the Create Subscription(s) button to process the addresses when your list is complete.' => 'Inserisci gli indirizzi di posta elettronica, uno per riga, che desideri abbonare a questa selezione. Clicca sul bottone Crea abbonamenti per elaborare la lista degli indirizzi.',
      'Enter the email addresses, one per line, that you would like to enter into the system in order to block subscriptions.  These records are used to prevent subscriptions from being sent to a specific address, and are used in the event that a particular user no longer wants to receive anything from your site.  Click the Block Subscription(s) button to process the addresses when your list is complete.' => 'Inserisci gli indirizzi di posta elettronica, uno per riga, che vuoi inserire tra quelli bloccati dal sistema. Questo impedira al sistema di inviare abbonamenti a indirizzi specifici, nel caso che alcuni utenti non vogliano più ricevere alcun messaggio dal tuo sito.',
      'Create Subscription(s)' => 'Crea abbonameti',

      'Subscription Count' => 'Contatore abbonamenti',
      '[_1] has [_2] subscriptions and [_3] subscription blocks.' => '[_1] ha [_2] abbonamenti di cui [_3] blocati.',
      'There are [_1] subscriptions and [_2] subscription blocks in this list.' => 'Ci sono [_1] abbonamenti e [_2] bloccati in questa lista.',

      ## tmpl/email/confirmation.tmpl
      'requires you to use a double-opt system for making any changes to your subscription information' => 'ti richiede di usare un sistema double-opt per effettuare qualsiasi modifica alle informazioni degli abbonamenti',
      'Because you, or someone using your email address, recently submitted a request at' => 'Questo messaggio di conferma ti è stato inviato perche tu, o qualcuno che usa il tuo indirizzo',
      ', you are being sent this confirmation to verify that the request is genuine.' => 'ha inviato una richiesta',
      'The request is to' => 'La richiesta è di',
      'Please confirm your request by clicking this link' => 'Conferma la richiesta cliccando questo collegamento',
      'Use this link if you would like to visit before confirming this request' => 'Usa questo collegamento se vuoi visitare il sito prima di confermare la richiesta',
      'If you did not make this request, do nothing.  You will receive no further reminders of this request.  If you did make this request, but there are errors in the request, you can simply submit a new one to correct any problems.  Confirmation of that request will follow your re-submission.' => 'Se non hai fatto questa richiesta non fare niente. Non riceverai altri messaggi per questa richiesta. Se hai inviato questa richiesta ma ci sono degli errori ignora questa ed inviane una nuova. Un nuovo messaggio di conferma ti verra inviato subito dopo.',

      ## tmpl/email/confirmation-subject.tmpl
      'Please confirm your request to' => 'Conferma la tua richiesta per',

      ## tmpl/email/notification.tmpl
      'Summary: ' => 'Sommario: ',
      'Author: ' => 'Autore: ',
      'Website: ' => 'Sito web: ',
      'View the entire entry:' => 'Mostra articolo completo:',
      'Cancel this subscription:' => 'Annulla abbonamento:',
      'Block all notifications from this site:' => 'Blocca tutte le notifiche da questo sito:',

      ## tmpl/email/notification-subject.tmpl
      'New Entry from' => 'Nuovo articolo da',
      'New Comment on' => 'Nuovo commento su',

);

1;