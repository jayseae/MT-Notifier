# ===========================================================================
# A Movable Type plugin with subscription options for your installation
# Copyright 2003-2008 Everitz Consulting <everitz.com>.
#
# This program may not be redistributed without permission.
# ===========================================================================
package Notifier;

use base qw(MT::App);
use strict;

use MT;
use Notifier::Data;

# record status
use constant PENDING => 0;
use constant RUNNING => 1;

# record type
use constant OPT_OUT   => 0;
use constant SUBSCRIBE => 1;
use constant TEMPORARY => 2;

# other
use constant BULK => 1;

# version
use vars qw($VERSION);
$VERSION = '4.0.4';

sub init {
  my $app = shift;
  $app->SUPER::init (@_) or return;
  $app->add_methods (
    queued => \&send_queued
  );
  $app->{requires_login} = 1;
  if ($ARGV[0] eq 'queued') {
    $app->param('__mode', 'queued');
    $app->param('limit', $ARGV[1]);
    $app->{requires_login} = 0;
  }
  $app;
}

# subscription functions

sub create_subscription {
  my $app = MT->instance->app;
  my $plugin = $app->component('Notifier');
  my ($email, $record, $blog_id, $category_id, $entry_id, $bulk) = @_;
  my $blog;
  require MT::Blog;
  require MT::Util;
  if (my $fixed = MT::Util::is_valid_email($email)) {
    $email = $fixed;
  } else {
    return 1;
  }
  return unless ($record eq Notifier::OPT_OUT || $record eq Notifier::SUBSCRIBE);
  if ($entry_id) {
    require MT::Entry;
    my $entry = MT::Entry->load($entry_id) or return 2;
    $blog = MT::Blog->load($entry->blog_id) or return 2;
    $blog_id = $blog->id;
    $category_id = 0;
  } elsif ($category_id) {
    require MT::Category;
    my $category = MT::Category->load($category_id) or return 2;
    $blog = MT::Blog->load($category->blog_id) or return 2;
    $blog_id = $blog->id;
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
  	require Notifier::Util;
    $data->cipher(Notifier::Util::produce_cipher(
      'a'.$email.'b'.$blog_id.'c'.$category_id.'d'.$entry_id
    ));
    my $system_confirm = $plugin->get_config_value('system_confirm');
    my $blog_confirm = $plugin->get_config_value('blog_confirm', 'blog:'.$blog->id);
    if ($system_confirm && $blog_confirm) {
      $data->status(PENDING) unless ($bulk);
      $data->status(RUNNING) if ($bulk);
    } else {
      $data->status(RUNNING);
    }
    $data->ip($app->remote_ip);
    $data->type(0); # 4.0
    $data->save;
    data_confirmation($data) if ($data->status == Notifier::PENDING);
  }
  return 0;
}

sub data_confirmation {
  my $app = MT->instance->app;
  my $plugin = $app->component('Notifier');
  my ($data) = @_;
  my ($category, $entry, $type);
  if ($data->entry_id) {
    require MT::Entry;
    $entry = MT::Entry->load($data->entry_id) or return;
    $type = $plugin->translate('Entry');
  } elsif ($data->category_id) {
  	require MT::Category;
    $category = MT::Category->load($data->category_id) or return;
    $type = $plugin->translate('Category');
  } else {
    $type = $plugin->translate('Blog');
  }
  my ($author, $lang);
  if ($entry) {
    $author = $entry->author;
    if ($author && $author->preferred_language) {
      $lang = $author->preferred_language;
      $app->set_language($lang);
    }
  }
  require Notifier::Util;
  my $sender_address = Notifier::Util::load_sender_address($data, $author);
  unless ($sender_address) {
    $app->log($plugin->translate('No sender address available - aborting confirmation!'));
    return;
  }
  my $blog = Notifier::Util::load_blog($data);
  require MT::ConfigMgr;
  my $cfg = MT::ConfigMgr->instance;
  $app->set_language($cfg->DefaultLanguage) unless ($lang);
  my $charset = $cfg->PublishCharset || 'iso-8859-1';
  my $notifier_base =($cfg->CGIPath =~ /^http/) ? $cfg->CGIPath : $app->base.$cfg->CGIPath;
  my $notifier_link = $notifier_base.$cfg->AdminScript;
  my $record_text = ($data->record == Notifier::SUBSCRIBE) ?
    $plugin->translate('subscribe to') :
    $plugin->translate('opt-out of');
  my %head = (
    'Content-Type' => qq(text/plain; charset="$charset"),
    'From' => $sender_address,
    'To' => $data->email
  );
  require MT::Util;
  my %param = (
    'blog_id' => $blog->id,
    'blog_id_'.$blog->id => 1,
    'blog_description' => MT::Util::remove_html($blog->description),
    'blog_name' => MT::Util::remove_html($blog->name),
    'blog_url' => $blog->site_url,
    'notifier_home' => $plugin->author_link,
    'notifier_name' => $plugin->name,
    'notifier_link' => $notifier_link,
    'notifier_version' => Notifier->version_number,
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
  $head{'Subject'} = Notifier::Util::load_email('confirmation-subject.tmpl', \%param);
  my $body = Notifier::Util::load_email('confirmation.tmpl', \%param);
  send_email(\%head, $body);
}

sub entry_notifications {
  my $entry_id = shift;
  require MT::Entry;
  my $entry = MT::Entry->load($entry_id);
  next unless ($entry);
  my $blog_id = $entry->blog_id;
  my @work_subs =
    map { $_ }
    Notifier::Data->load({
      blog_id => $blog_id,
      category_id => 0,
      entry_id => 0,
      record => Notifier::SUBSCRIBE,
      status => Notifier::RUNNING
    });
  require MT::Placement;
  my @places = MT::Placement->load({
    entry_id => $entry_id
  });
  foreach my $place (@places) {
    my @category_subs = Notifier::Data->load({
      blog_id => $blog_id,
      category_id => $place->category_id,
      entry_id => 0,
      record => Notifier::SUBSCRIBE,
      status => Notifier::RUNNING
    });
    foreach (@category_subs) {
      push @work_subs, $_;
    }
  }
  my $work_users = scalar @work_subs;
  next unless ($work_users);
  notify_users($entry, \@work_subs);
}

sub notify_users {
  my $app = MT->instance->app;
  my $plugin = $app->component('Notifier');
  my ($obj, $work_subs) = @_;
  my ($entry, $comment, $type);
  if (UNIVERSAL::isa($obj, 'MT::Comment')) {
    require MT::Entry;
    $entry = MT::Entry->load($obj->entry_id) or return;
    $comment = $obj;
    $type = $plugin->translate('Comment');
  }
  if (UNIVERSAL::isa($obj, 'MT::Entry')) {
    $entry = $obj;
    $type = $plugin->translate('Entry');
  }
  require MT::Blog;
  my $blog = MT::Blog->load($obj->blog_id) or return;
  my @work_opts =
    map { $_ }
    Notifier::Data->load({
      blog_id => $blog->id,
      category_id => 0,
      entry_id => 0,
      record => Notifier::OPT_OUT,
      status => Notifier::RUNNING
    });
  require MT::Placement;
  my @places = MT::Placement->load({
    entry_id => $entry->id
  });
  foreach my $place (@places) {
    my @category_opts = Notifier::Data->load({
      blog_id => $blog->id,
      category_id => $place->category_id,
      entry_id => 0,
      record => Notifier::OPT_OUT,
      status => Notifier::RUNNING
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
  require Notifier::Util;
  my $sender_address = Notifier::Util::load_sender_address($obj, $author);
  return unless ($sender_address);
  $app->set_language($author->preferred_language)
    if ($author && $author->preferred_language);
  require MT::ConfigMgr;
  my $cfg = MT::ConfigMgr->instance;
  my $charset = $cfg->PublishCharset || 'iso-8859-1';
  my $notifier_base =($cfg->CGIPath =~ /^http/) ? $cfg->CGIPath : $app->base.$cfg->CGIPath;
  my $notifier_link = $notifier_base.$cfg->AdminScript;
  require MT::Util;
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
    'entry_keywords' => $entry->keywords,
    'entry_link' => $entry->permalink,
    'entry_more' => $entry->text_more,
    'entry_status' => $entry->status,
    'entry_title' => $entry->title,
    'notifier_home' => $plugin->author_link,
    'notifier_name' => $plugin->name,
    'notifier_link' => $notifier_link,
    'notifier_version' => Notifier->version_number
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
    'Subject' => Notifier::Util::load_email('notification-subject.tmpl', \%param)
  );
  my $blog_queued = $plugin->get_config_value('blog_queued', 'blog:'.$blog->id);
  my $system_queued = $plugin->get_config_value('system_queued');
  foreach my $sub (@subs) {
    next if ($comment && $sub->email eq $comment->email);
    my %terms;
    require Notifier::History;
    $terms{'data_id'} = $sub->id;
    $terms{'comment_id'} = (UNIVERSAL::isa($obj, 'MT::Comment')) ? $obj->id : 0;
    $terms{'entry_id'} = (UNIVERSAL::isa($obj, 'MT::Entry')) ? $obj->id : 0;
    my $history = Notifier::History->load(\%terms);
    next if ($history);
    $head{'To'} = $sub->email;
    $param{'record_cipher'} = $sub->cipher;
    my $body = Notifier::Util::load_email('notification.tmpl', \%param);
    if ($system_queued && $blog_queued) {
      queue_email(\%head, $body);
    } else {
      send_email(\%head, $body);
    }
    $history = Notifier::History->new;
    $history->data_id($sub->id);
    $history->comment_id((UNIVERSAL::isa($obj, 'MT::Comment')) ? $obj->id : 0);
    $history->entry_id((UNIVERSAL::isa($obj, 'MT::Entry')) ? $obj->id : 0);
    $history->save;
  }
}

sub queue_email {
  my ($hdrs, $body) = @_;
  require Notifier::Queue;
  my $queue = Notifier::Queue->new;
  $queue->head_content($hdrs->{'Content-Type'});
  $queue->head_from($hdrs->{'From'});
  $queue->head_to($hdrs->{'To'});
  $queue->head_subject($hdrs->{'Subject'});
  $queue->body($body);
  $queue->save;
}

sub send_email {
  my $app = MT->instance->app;
  my $plugin = $app->component('Notifier');
  my ($hdrs, $body) = @_;
  foreach my $h (keys %$hdrs) {
    if (ref($hdrs->{$h}) eq 'ARRAY') {
      map { y/\n\r/  / } @{$hdrs->{$h}};
    } else {
      $hdrs->{$h} =~ y/\n\r/  / unless (ref($hdrs->{$h}));
    }
  }
  $body .= "\n\n--\n";
  $body .= $plugin->name.' v'.$plugin->version."\n";
  $body .= $plugin->author_link."\n";
  require MT::Mail;
  require MT::ConfigMgr;
  my $mgr = MT::ConfigMgr->instance;
  my $xfer = $mgr->MailTransfer;
  if ($xfer eq 'sendmail') {
    return MT::Mail->_send_mt_sendmail($hdrs, $body, $mgr);
  } elsif ($xfer eq 'smtp') {
    return MT::Mail->_send_mt_smtp($hdrs, $body, $mgr);
  } elsif ($xfer eq 'debug') {
    return MT::Mail->_send_mt_debug($hdrs, $body, $mgr);
  } else {
    return MT::Mail->error($plugin->translate(
      "Unknown MailTransfer method '[_1]'", $xfer ));
  }
}

sub send_queued {
  my $app = MT->instance->app;
  my $plugin = $app->component('Notifier');
  my (%terms, %args);
  $args{'limit'} = $app->param('limit');
  $args{'direction'} = 'ascend';
  $args{'sort'} = 'id';
  require Notifier::Queue;
  my $iter = Notifier::Queue->load_iter(\%terms, \%args);
  my $count = 0;
  while (my $q = $iter->()) {
    my %head = (
      'Content-Type' => $q->head_content,
      'From' => $q->head_from,
      'To' => $q->head_to,
      'Subject' => $q->head_subject
    );
    send_email(\%head, $q->body);
    $q->remove;
    $count++;
  }
  my $s = ($count != 1) ? 's' : '';
  $app->log($plugin->translate(
    "[_1]: Sent [_2] queued notification[_3].", 'MT-Notifier', $count, $s)
  );
}

# version routines

sub schema_version {
  (my $ver = $VERSION) =~ s/^([\d]+[\.]).*$/$1/;
  (my $rel = $VERSION) =~ s/^[\d]+[\.](.*)$/$1/;
  $rel =~ s/\.//g;
  $ver = $ver.$rel;
  $ver;
}

sub version_number {
  (my $ver = $VERSION) =~ s/^([\d]+[\.]?[\d]*).*$/$1/;
  $ver;
}

1;