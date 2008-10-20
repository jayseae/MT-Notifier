# ===========================================================================
# Copyright 2003-2005, Everitz Consulting (mt@everitz.com)
#
# Licensed under the Open Software License version 2.1
# ===========================================================================
package Notifier;

use base qw(MT::App::CMS);
use strict;

use MT;
use Notifier::Data;

# record status
use constant PENDING => 0;
use constant RUNNING => 1;

# record type
use constant OPT     => 0;
use constant SUB     => 1;
use constant TEMP    => 2;

# other
use constant BULK    => 1;

# version
use vars qw($SENTSRV1 $SENTSRV2 $SENTSRV3 $VERSION);
$SENTSRV1 = 'http://www.everitz.com/sol/notifier/sentservice.html';
$SENTSRV2 = 'http://www.everitz.com/sol/notifier/sent_service.html';
$SENTSRV3 = 'http://www.everitz.com/sol/mt-notifier/sent_service.html';
$VERSION = '3.4.1';

sub init {
  my $app = shift;
  $app->SUPER::init (@_) or return;
  $app->add_methods (
    default => \&notifier_request,
    loader => \&notifier_loader,
    import => \&notifier_import,
    queued => \&send_queued,
    update => \&notifier_loader
  );
  $app->{default_mode} = 'default';
  my $mode = $app->{query}->param('__mode');
  $app->{requires_login} = ($mode) ? 1 : 0;
  if ($ARGV[0] eq 'queued') {
    $app->{query}->param('__mode', 'queued');
    $app->{query}->param('limit', $ARGV[1]);
    $app->{requires_login} = 0;
  }
  $app;
}

sub notifier_import {
  my $notifier = MT::Plugin::Notifier->instance;
  my $app = shift;
  my $auth = ($app->user->is_superuser) ? 1 : 0;
  my $from = $app->{query}->param('from');
  my $d = $app->{query}->param('d');
  my $count = 0;
  my $message;
  if ($auth) {
    if ($from eq 'mt') { 
      use MT::Notification;
      foreach my $data (MT::Notification->load()) {
        next unless ($data && $data->blog_id && $data->email);
        create_subscription($data->email, SUB, $data->blog_id, 0, 0, BULK);
        $count++;
      }
    } elsif ($from eq 'n1x') {
      use MT::PluginData;
      foreach my $data (MT::PluginData->load({ plugin => 'Notifier' })) {
        if ($data->key =~ /^([0-9]+):0$/) {
          my $blog_id = $1;
          my $scope = 'blog:'.$blog_id if ($blog_id);
          if (my $from = $data->data->{'senderaddress'}) {
            $notifier->set_config_value('system_address', $from, $scope);
          }
          next unless ($blog_id);
          if (my $subs = $data->data->{'subscriptions'}) {
            foreach my $sub (split(';', $subs)) {
              my ($email) = split(':', $sub);
              create_subscription($email, OPT, $blog_id, 0, 0, BULK);
              $count++;
            }
          }
        } elsif ($data->key =~ /^([1-9][0-9]*):([1-9][0-9]*)$/) {
          my $entry_id = $2;
          if (my $subs = $data->data->{'subscriptions'}) {
            foreach my $sub (split(';', $subs)) {
              my ($email) = split(':', $sub);
              create_subscription($email, SUB, 0, 0, $entry_id, BULK);
              $count++;
            }
          }
        }
      }
    } elsif ($from eq 'n2x') {
      use MT::PluginData;
      foreach my $data (MT::PluginData->load({ plugin => 'Notifier (n2x)' })) {
        next unless ($data->key =~ /:/);
        if ($data->key =~ /^([0-9]+):0$/) {
          my $blog_id = $1;
          my $scope = 'blog:'.$blog_id if ($blog_id);
          if (my $from = $data->data->{'from'}) {
            $notifier->set_config_value('system_address', $from, $scope);
          }
          next unless ($blog_id);
          if (my $subs = $data->data->{'subs'}) {
            foreach my $sub (split(';', $subs)) {
              my ($email, $type) = split(':', $sub);
              $type = ($type eq 'opt') ? OPT : SUB;
              create_subscription($email, $type, $blog_id, 0, 0, BULK);
              $count++;
            }
          }
        } elsif ($data->key =~ /^([1-9][0-9]*):C$/) {
          my $category_id = $1;
          if (my $subs = $data->data->{'subs'}) {
            foreach my $sub (split(';', $subs)) {
              my ($email, $type) = split(':', $sub);
              $type = ($type eq 'opt') ? OPT : SUB;
              create_subscription($email, $type, 0, $category_id, 0, BULK);
              $count++;
            }
          }
        } elsif ($data->key =~ /^0:([1-9][0-9]*)$/) {
          my $entry_id = $1;
          if (my $subs = $data->data->{'subs'}) {
            foreach my $sub (split(';', $subs)) {
              my ($email, $type) = split(':', $sub);
              next if ($type eq 'opt');
              create_subscription($email, SUB, 0, 0, $entry_id, BULK);
              $count++;
            }
          }
        }
      }
    }
    my $s = ($count eq 1) ? '' : 's';
    $message = $app->translate("You have successfully converted [_1] record$s!", $count);
  } else {
    $message = $app->translate('You are not authorized to run this process!');
  }
  $app->build_page($notifier->load_tmpl('notification_request.tmpl'), {
    message => $message,
    notifier_version => version_number(),
    page_title => 'MT-Notifier '.$app->translate('Import Processing')
  });
}

sub notifier_loader {
  my $notifier = MT::Plugin::Notifier->instance;
  my $app = MT->instance;
  my $auth = ($app->user->is_superuser) ? 1 : 0;
  my $load = ($app->{query}->param('__mode') eq 'loader') ? 1 : 0;
  my $message;
  if ($auth) {
    if ($app->{cfg}->ObjectDriver =~ /^DBI::(.*)$/) {
      my $type = $1;
      my $cfg = MT::ConfigMgr->instance;
      my $dbh = MT::Object->driver->{dbh};
      my $update = ($load == 0) ? '-update' : '';
      my $schema = File::Spec->catfile('schemas', $type.$update.'.dump');
      open FH, $schema or die "<p class=\"bad\">Can't open '$schema': $!</p>";
      my $ddl;
      { local $/; $ddl = <FH> }
      close FH;
      my @stmts = split /;/, $ddl;
      for my $stmt (@stmts) {
        $stmt =~ s!^\s*!!;
        $stmt =~ s!\s*$!!;
        next unless $stmt =~ /\S/;
        $dbh->do($stmt) or die $dbh->errstr;
      }
      $message = 'Your system is installed and ready to use!';
    }
  } else {
    $message = 'You are not authorized to run this process!';
  }
  $app->build_page($notifier->load_tmpl('notification_request.tmpl'), {
    message => $app->translate($message),
    notifier_version => version_number(),
    page_title => 'MT-Notifier '.$app->translate('System Loader')
  });
}

sub notifier_request {
  my $notifier = MT::Plugin::Notifier->instance;
  my $app = shift;
  my $cipher = $app->{query}->param('c');
  my $n = $app->{query}->param('n');                  # redirect name
  my $o = $app->{query}->param('o');                  # opt-out
  my $r = $app->{query}->param('r');                  # redirect link
  my $u = $app->{query}->param('u');                  # unsubscribe
  my ($email, $blog_id, $category_id, $entry_id);
  my ($confirm, $data, $message, $name, $url);
  if ($cipher) {
    use Notifier::Data;
    $data = Notifier::Data->load({ cipher => $cipher });
    if ($data) {
      if ($o) {
        $blog_id = $data->blog_id;
        $category_id = $data->category_id;
        $entry_id = $data->entry_id;
        $email = $data->email;
        my $record = OPT;
        if ($entry_id) {
          use MT::Entry;
          my $entry = MT::Entry->load($entry_id);
          if ($entry) {
            $blog_id = $entry->blog_id;
            $name = $entry->title;
            $url = $entry->permalink;
          } else {
            $message = 'No entry was found to match that subscription record!';
          }
        } elsif ($category_id) {
          use MT::Category;
          my $category = MT::Category->load($category_id);
          if ($category) {
            $blog_id = $category->blog_id;
            $name = $category->label;
            use MT::Blog;
            use MT::Util;
            my $blog = MT::Blog->load($category->blog_id);
            if ($blog) {
              $url = $blog->archive_url;
              $url .= '/' unless $url =~ m/\/$/;
              $url .= MT::Util::archive_file_for ('',  $blog, 'Category', $category);
            }
          } else {
            $message = 'No category was found to match that subscription record!';
          }
        } elsif ($blog_id) {
          use MT::Blog;
          my $blog = MT::Blog->load($blog_id);
          if ($blog) {
            $blog_id = $blog->id;
            $name = $blog->name;
            $url = $blog->site_url;
          } else {
            $message = 'No blog was found to match that subscription record!';
          }
        }
        $category_id = 0;
        $entry_id = 0;
        create_subscription($email, $record, $blog_id, $category_id, $entry_id);
        $message = 'Your opt-out record has been created!';
      } elsif ($u) {
        $data->remove;
        $message = 'Your subscription has been cancelled!';
      }
    } else {
      $message = 'No subscription record was found to match that locator!';
    }
    unless ($message) {
      $message = 'Your request has been processed successfully!';
      $data->status(RUNNING);
      $data->save;
    }
  } else {
    if ($email = $app->{query}->param('email')) {
      $blog_id = $app->{query}->param('blog_id');
      $category_id = $app->{query}->param('category_id');
      $entry_id = $app->{query}->param('entry_id');
      if ($blog_id || $category_id || $entry_id) {
        if ($entry_id) {
          use MT::Entry;
          my $entry = MT::Entry->load($entry_id);
          if ($entry) {
            $blog_id = $entry->blog_id;
            $name = $entry->title;
            $url = $entry->permalink;
          }
        } elsif ($category_id) {
          use MT::Category;
          my $category = MT::Category->load($category_id);
          if ($category) {
            $blog_id = $category->blog_id;
            $name = $category->label;
            use MT::Blog;
            my $blog = MT::Blog->load($category->blog_id);
            if ($blog) {
              $url = $blog->archive_url;
              $url .= '/' unless $url =~ m/\/$/;
              $url .= MT::Util::archive_file_for ('',  $blog, 'Category', $category);
            }
          }
        } elsif ($blog_id) {
          use MT::Blog;
          my $blog = MT::Blog->load($blog_id);
          if ($blog) {
            $name = $blog->name;
            $url = $blog->site_url;
          }
        }
        my $error = create_subscription($email, SUB, $blog_id, $category_id, $entry_id);
        if ($error == 1) {
          $message = 'The specified email address is not valid!';
        } elsif ($error == 2) {
          $message = 'The requested record key is not valid!';
        } elsif ($error == 3) {
          $message = 'That record already exists!';
        } else {
          $confirm = 1 if
            $notifier->get_config_value('system_confirm') &&
            $notifier->get_config_value('blog_confirm', $blog_id);
          $message = 'Your request has been processed successfully!';
        }
      } else {
        $message = 'Your request did not include a record key!';
      }
    } else {
      $message = 'Your request must include an email address!';
    }
  }
  if ($r && $r ne '1') {
    $name = ($n) ? $n : $r;
    $url = $r;
  }
  $app->build_page($notifier->load_tmpl('notification_request.tmpl'), {
    confirm => $confirm,
    link_name => ($r) ? $name : '',
    link_url => ($r) ? $url : '',
    message => $app->translate($message),
    notifier_version => version_number(),
    page_title => 'MT-Notifier '.$app->translate('Request Processing')
  });
}

# subscription functions

sub create_subscription {
  my $notifier = MT::Plugin::Notifier->instance;
  my $app = MT->instance;
  my ($email, $record, $blog_id, $category_id, $entry_id, $bulk) = @_;
  my $blog;
  use MT::Blog;
  use MT::Util;
  if (my $fixed = MT::Util::is_valid_email($email)) {
    $email = $fixed;
  } else {
    return 1;
  }
  return unless ($record eq OPT || $record eq SUB);
  if ($entry_id) {
    use MT::Entry;
    my $entry = MT::Entry->load($entry_id) or return 2;
    $blog = MT::Blog->load($entry->blog_id) or return 2;
    $blog_id = 0;
    $category_id = 0;
  } elsif ($category_id) {
    use MT::Category;
    my $category = MT::Category->load($category_id) or return 2;
    $blog = MT::Blog->load($category->blog_id) or return 2;
    $blog_id = 0;
    $entry_id = 0;
  } elsif ($blog_id) {
    $blog = MT::Blog->load($blog_id) or return 2;
    $category_id = 0;
    $entry_id = 0;
  }
  my $data = Notifier::Data->load({
    blog_id => $blog_id,
    category_id => $category_id,
    entry_id => $entry_id,
    email => $email,
    record => $record
  });
  if ($data) {
    return 3;
  } else {
    $data = Notifier::Data->new;
    $data->blog_id($blog_id);
    $data->category_id($category_id);
    $data->entry_id($entry_id);
    $data->email($email);
    $data->record($record);
    $data->cipher(produce_cipher(
      'a'.$email.'b'.$blog_id.'c'.$category_id.'d'.$entry_id
    ));
    my $config = $notifier->get_config_hash();
    my $blog_config = $notifier->get_config_hash('blog:'.$blog->id);
    if ($config->{'system_confirm'} && $blog_config->{'blog_confirm'}) {
      $data->status(PENDING) unless ($bulk);
      $data->status(RUNNING) if ($bulk);
    } else {
      $data->status(RUNNING);
    }
    $data->save;
    data_confirmation($data) if ($data->status == PENDING);
  }
  return 0;
}

sub data_confirmation {
  my $notifier = MT::Plugin::Notifier->instance;
  my $app = MT->instance;
  my ($data) = @_;
  my ($category, $entry, $type);
  if ($data->entry_id) {
    use MT::Entry;
    $entry = MT::Entry->load($data->entry_id) or return;
    $type = $app->translate('Entry');
  } elsif ($data->category_id) {
    $category = MT::Category->load($data->category_id) or return;
    $type = $app->translate('Category');
  } else {
    $type = $app->translate('Blog');
  }
  my ($author, $lang);
  if ($entry) {
    $author = $entry->author;
    if ($author && $author->preferred_language) {
      $lang = $author->preferred_language;
      $app->set_language($lang);
    }
  }
  my $sender_address = load_sender_address($data, $author);
  unless ($sender_address) {
    $app->log($app->translate('No sender address available - aborting confirmation!'));
    return;
  }
  my $blog = load_blog($data);
  use MT::ConfigMgr;
  my $cfg = MT::ConfigMgr->instance;
  $app->set_language($cfg->DefaultLanguage) unless ($lang);
  my $charset = $cfg->PublishCharset || 'iso-8859-1';
  my $record_text = ($data->record == SUB) ?
    $app->translate('subscribe to') :
    $app->translate('opt-out of');
  my %head = (
    'Content-Type' => qq(text/plain; charset="$charset"),
    'From' => $sender_address,
    'Subject' => '['.$blog->name.'] '
  );
  use MT::Util;
  my %param = (
    'blog_id' => $blog->id,
    'blog_id_'.$blog->id => 1,
    'blog_description' => MT::Util::remove_html($blog->description),
    'blog_name' => MT::Util::remove_html($blog->name),
    'blog_url' => $blog->site_url,
    'notifier_home' => $notifier->author_link,
    'notifier_name' => $notifier->name,
    'notifier_link' => $cfg->CGIPath.$notifier->envelope.'/mt-notifier.cgi',
    'notifier_running' => $data->status,
    'notifier_version' => version_number(),
    'record_cipher' => $data->cipher,
    'record_text' => $record_text
  );
  if ($entry) {
    $param{'record_link'} = $entry->permalink;
    $param{'record_name'} = MT::Util::remove_html($entry->title);
  } elsif ($category) {
    my $link = $blog->archive_url;
    $link .= '/' unless $link =~ m/\/$/;
    $link .= MT::Util::archive_file_for ('',  $blog, $type, $category);
    $param{'record_link'} = $link;
    $param{'record_name'} = MT::Util::remove_html($category->label);
  } elsif ($blog) {
    $param{'record_link'} = $blog->site_url;
    $param{'record_name'} = MT::Util::remove_html($blog->name);
  }
  $head{'Subject'} = load_email('confirmation-subject.tmpl', \%param);
  $head{'To'} = $data->email;
  my $body = load_email('confirmation.tmpl', \%param);
  send_email(\%head, $body);
}

sub entry_notifications {
  my $app = MT->instance;
  use MT::Request;
  my $r = MT::Request->instance;
  my $notify_list = $r->stash('mtn_notify_list') || {};
  return unless (scalar(keys(%$notify_list)));
  foreach my $entry_id (keys %$notify_list) {
    use MT::Entry;
    my $entry = MT::Entry->load($entry_id);
    next unless ($entry);
    my $pinged = $entry->pinged_urls;
    next if ($pinged && $pinged =~ m/$SENTSRV1/);
    next if ($pinged && $pinged =~ m/$SENTSRV2/);
    next if ($pinged && $pinged =~ m/$SENTSRV3/);
    my $blog_id = $entry->blog_id;
    my @work_subs =
      map { $_ }
      Notifier::Data->load({
        blog_id => $blog_id,
        record => Notifier::SUB,
        status => Notifier::RUNNING
      });
    use MT::Placement;
    my @places = MT::Placement->load({
      entry_id => $entry_id
    });
    foreach my $place (@places) {
      my @category_subs = Notifier::Data->load({
        category_id => $place->category_id,
        record => Notifier::SUB,
        status => Notifier::RUNNING
      });
      foreach (@category_subs) {
        push @work_subs, $_;
      }
    }
    my $work_users = scalar @work_subs;
    next unless ($work_users);
    notify_users($entry, \@work_subs);
    $pinged = $entry->pinged_url_list;
    push(@$pinged, $SENTSRV3);
    $entry->pinged_urls(join("\n", @$pinged));
    $entry->save;
  }
  $r->stash('mtn_notify_list', {});
}

sub notify_users {
  my $notifier = MT::Plugin::Notifier->instance;
  my $app = MT->instance;
  my ($obj, $work_subs) = @_;
  my ($entry, $comment, $type);
  if (UNIVERSAL::isa($obj, 'MT::Comment')) {
    use MT::Entry;
    $entry = MT::Entry->load($obj->entry_id) or return;
    $comment = $obj;
    $type = $app->translate('Comment');
  } else {
    $entry = $obj;
    $type = $app->translate('Entry');
  }
  use MT::Blog;
  my $blog = MT::Blog->load($obj->blog_id) or return;
  my @work_opts =
    map { $_ }
    Notifier::Data->load({
      blog_id => $blog->id,
      record => OPT,
      status => RUNNING
    });
  use MT::Placement;
  my @places = MT::Placement->load({
    entry_id => $entry->id
  });
  foreach my $place (@places) {
    my @category_opts = Notifier::Data->load({
      category_id => $place->category_id,
      record => OPT,
      status => RUNNING
    });
    foreach (@category_opts) {
      push @work_opts, $_;
    }
  }
  my %opts = map { $_->email => 1 }@work_opts;
  my @subs = grep { !exists $opts{$_->email} } @$work_subs;
  my $users = scalar @subs;
  return unless ($users);
  my $author = $entry->author;
  my $sender_address = load_sender_address($obj, $author);
  return unless ($sender_address);
  $app->set_language($author->preferred_language)
    if ($author && $author->preferred_language);
  use MT::ConfigMgr;
  my $cfg = MT::ConfigMgr->instance;
  my $charset = $cfg->PublishCharset || 'iso-8859-1';
  use MT::Util;
  my %param = (
    'blog_id' => $blog->id,
    'blog_id_'.$blog->id => 1,
    'blog_description' => MT::Util::remove_html($blog->description),
    'blog_name' => MT::Util::remove_html($blog->name),
    'blog_url' => $blog->site_url,
    'entry_author' => $entry->author->name,
    'entry_author_nickname' => $entry->author->nickname,
    'entry_author_email' => $entry->author->email,
    'entry_author_url' => $entry->author->url,
    'entry_body' => $entry->text,
    'entry_excerpt' => $entry->get_excerpt,
    'entry_id' => $entry->id,
    'entry_id_'.$entry->id => 1,
    'entry_keywords' => $entry->get_keywords,
    'entry_link' => $entry->permalink,
    'entry_more' => $entry->text_more,
    'entry_status' => $entry->permalink,
    'entry_title' => $entry->title,
    'notifier_home' => $notifier->author_link,
    'notifier_name' => $notifier->name,
    'notifier_link' => $cfg->CGIPath.$notifier->envelope.'/mt-notifier.cgi',
    'notifier_version' => version_number()
  );
  if ($comment) {
    $param{'comment_author'} = $comment->author;
    $param{'comment_body'} = $comment->text;
    $param{'comment_id'} = $comment->id;
    $param{'comment_url'} = $comment->url;
    $param{'notifier_comment'} = 1,
    $param{'notifier_entry'} = 0
  } else {
    $param{'notifier_comment'} = 0,
    $param{'notifier_entry'} = 1
  }
  my %head = (
    'Content-Type' => qq(text/plain; charset="$charset"),
    'From' => $sender_address,
    'Subject' => load_email('notification-subject.tmpl', \%param)
  );
  my $blog_queued = $notifier->get_config_value('blog_queued', 'blog:'.$blog->id);
  my $system_queued = $notifier->get_config_value('system_queued');
  foreach my $sub (@subs) {
    next if ($comment && $sub->email eq $comment->email);
    $head{'To'} = $sub->email;
    $param{'record_cipher'} = $sub->cipher;
    my $body = load_email('notification.tmpl', \%param);
    if ($system_queued && $blog_queued) {
      queue_email(\%head, $body);
    } else {
      send_email(\%head, $body);
    }
  }
}

sub queue_email {
  my ($hdrs, $body) = @_;
  use Notifier::Queue;
  my $queue = Notifier::Queue->new;
  $queue->head_content($hdrs->{'Content-Type'});
  $queue->head_from($hdrs->{'From'});
  $queue->head_to($hdrs->{'To'});
  $queue->head_subject($hdrs->{'Subject'});
  $queue->body($body);
  $queue->save;
}

sub send_email {
  my $notifier = MT::Plugin::Notifier->instance;
  my $app = MT->instance;
  my ($hdrs, $body) = @_;
  foreach my $h (keys %$hdrs) {
    if (ref($hdrs->{$h}) eq 'ARRAY') {
      map { y/\n\r/  / } @{$hdrs->{$h}};
    } else {
      $hdrs->{$h} =~ y/\n\r/  / unless (ref($hdrs->{$h}));
    }
  }
  $body .= "\n\n--\n";
  $body .= $notifier->name.' v'.$notifier->version."\n";
  $body .= $notifier->author_link."\n";
  use MT::Mail;    
  my $mgr = MT::ConfigMgr->instance;
  my $xfer = $mgr->MailTransfer;
  if ($xfer eq 'sendmail') {
    return MT::Mail->_send_mt_sendmail($hdrs, $body, $mgr);
  } elsif ($xfer eq 'smtp') {
    return MT::Mail->_send_mt_smtp($hdrs, $body, $mgr);
  } elsif ($xfer eq 'debug') {
    return MT::Mail->_send_mt_debug($hdrs, $body, $mgr);
  } else {
    return MT::Mail->error(MT->translate(
      "Unknown MailTransfer method '[_1]'", $xfer ));
  }
}

sub send_queued {
  my $notifier = MT::Plugin::Notifier->instance;
  my $app = shift;
  my (%terms, %args);
  $args{'limit'} = $app->{query}->param('limit');
  $args{'sort'} = 'id';
  $args{'direction'} = 'ascend';
  use Notifier::Queue;
  my $iter = Notifier::Queue->load_iter(\%terms, \%args);
  my $count = 0;
  while (my $q = $iter->()) {
    my %head = (
      'Content-Type' => $q->head_content_type,
      'From' => $q->head_from,
      'To' => $q->head_to,
      'Subject' => $q->head_subject
    );
    send_email(\%head, $q->body);
    $q->remove;
    $count++;
  }
  my $s = ($count != 1) ? 's' : '';
  $app->log($app->translate(
    "[_1]: Sent [_2] queued notification$s.", 'MT-Notifier', $count)
  );
}

# shared functions

sub load_blog {
  my ($obj) = @_;
  my $blog_id;
  use MT::Blog;
  if ($obj->entry_id) {
    use MT::Entry;
    my $entry = MT::Entry->load($obj->entry_id) or return;
    $blog_id = $entry->blog_id;
  } elsif ($obj->category_id) {
    use MT::Category;
    my $category = MT::Category->load($obj->category_id) or return;
    $blog_id = $category->blog_id;
  } else {
    $blog_id = $obj->blog_id;
  }
  my $blog = MT::Blog->load($blog_id) or return;
  $blog;
}

sub load_email {
  my $notifier = MT::Plugin::Notifier->instance;
  my $app = MT->instance;
  my ($file, $param) = @_;
  my @paths;
  my $dir = File::Spec->catdir($app->mt_dir, $notifier->envelope, 'tmpl', 'email');
  push @paths, $dir if -d $dir;
  $dir = File::Spec->catdir($app->mt_dir, $notifier->envelope, 'tmpl');
  push @paths, $dir if -d $dir;
  $dir = File::Spec->catdir($app->mt_dir, $notifier->envelope);
  push @paths, $dir if -d $dir;
  require HTML::Template;
  my $tmpl;
  eval {
    local $1; ## This seems to fix a utf8 bug (of course).
    $tmpl = HTML::Template->new_file(
      $file,
      path => \@paths,
      search_path_on_include => 1,
      die_on_bad_params => 0,
      global_vars => 1);
  };
  return MT->trans_error("Loading template '[_1]' failed: [_2]", $file, $@) if $@;
  for my $key (keys %$param) {
    $tmpl->param($key, $param->{$key});
  }
  MT->translate_templatized($tmpl->output);
}

sub load_sender_address {
  my $notifier = MT::Plugin::Notifier->instance;
  my $app = MT->instance;
  my ($obj, $author) = @_;
  my $sender_address = $author->email if ($author);
  my $config = $notifier->get_config_hash();
  if ($config) {
    $sender_address = $config->{'system_address'};
  } else {
    $app->log($app->translate('No system address - please configure one!'));
  }
  my $blog = load_blog($obj);
  unless ($blog) {
    $app->log($app->translate('Specified blog unavailable - please check your data!'));
    return $sender_address;
  }
  my $blog_config = $notifier->get_config_hash('blog:'.$blog->id);
  if ($blog_config) {
    if ($blog_config->{'blog_address_type'} == 2) {
      $sender_address = $author->email if ($author);
    } elsif ($blog_config->{'blog_address_type'} == 3) {
      $sender_address = $blog_config->{'blog_address'};
    }
  }
  use MT::Util;
  if (my $fixed = MT::Util::is_valid_email($sender_address)) {
    return $fixed;
  } else {
    my $message;
    if ($sender_address) {
      $message .= $app->translate('Invalid sender address - please reconfigure it!');
    } else {
      $message .= $app->translate('No sender address - please configure one!');
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

sub version_number {
  (my $ver = $VERSION) =~ s/^([\d]+[\.]?[\d]*).*$/$1/;
  $ver;
}

1;
