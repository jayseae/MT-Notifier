# ===========================================================================
# MT-Notifier: Configure subscriptions to your blog.
# A Plugin for Movable Type
#
# Release 2.2.2
# September 3, 2004
#
# http://jayseae.cxliv.org/notifier/
# http://www.amazon.com/o/registry/2Y29QET3Y472A/
#
# Copyright 2003-2004, Chad Everett (software@cxliv.org)
# ~Licensed under the Open Software License version 2.1~
#
# If you find the software useful or even like it, then a simple 'thank you'
# is always appreciated.  A reference back to me is even nicer.  If you find
# a way to make money from the software, do what you feel is right.
# ===========================================================================

package jayseae::notifier;

use strict;

use MT::App::CMS;
use MT::Util qw(archive_file_for format_ts);

use vars qw(@ISA $FILESET $VERSION);
@ISA = qw(MT::App::CMS);
$FILESET = 'n2x';
$VERSION = '2.2.2';

sub uri {
  $_[0]->path . ($_[0]->{author} ? MT::ConfigMgr->instance->AdminScript : $_[0]->script);
}

sub init {
  my $app = shift;
  $app->SUPER::init (@_) or return;
  $app->add_methods (
    default => \&manage_address,
    cfg => \&enabler,
    del => \&deleter,
    mgr => \&manager,
    mnu => \&menu,
    xfr => \&transfer
  );
  $app->{default_mode} = 'default';
  my $mode = $app->{query}->param('__mode');
  $app->{requires_login} =
    $mode eq 'cfg' ||
    $mode eq 'del' ||
    $mode eq 'mgr' ||
    $mode eq 'mnu' ||
    $mode eq 'xfr' ||
    $mode eq 'redir' ?
    1 : 0;
  $app->{user_class} = 'MT::Author';
  $app->{is_admin} = 1;
  $app;
}

sub deleter {
  my $app = shift;
  my $method = $app->{query}->param('method') || '';
  my $string = $app->{query}->param('string') || '';
  my $select = $app->{query}->param('select') || '';
  my $thekey = $app->{query}->param('thekey') || '';
  my %modes = (all => 1, cor => 1, dfa => 1, inv => 1, opt => 1, sub => 1);
  my %param = (func_deleter => 1);
  my $error;
  $thekey = '0:0' if ($select eq 'akey');
  $thekey = $app->{query}->param('bkey') if ($select eq 'bkey');
  $thekey = $app->{query}->param('ckey') if ($select eq 'ckey');
  $thekey = $app->{query}->param('ekey') if ($select eq 'ekey');
  if ($method) {
    if ($app->test_data_key($thekey)) { 
      if ($modes{$method}) {
        my @work_set;
        my $data_set;
        if ($method eq 'inv') {
          $data_set = $app->load_data_set($FILESET, 'data', $thekey, $method);
          foreach my $data_key (@$data_set) {
            push @work_set, $data_key unless $app->test_data_key($data_key, 1);
          }
        } else {
          $data_set = $app->load_data_set($FILESET, 'data', $thekey, $method, $string);
          foreach my $data_key (@$data_set) {
            push @work_set, $data_key if $app->test_data_key($data_key);
          }
        }
        $data_set = \@work_set;
        if (scalar @$data_set) {
          foreach my $data_key (@$data_set) {
            if ($method eq 'all') {
              $error = 99 if $app->purge_data($data_key);
            } elsif ($method eq 'cor') {
              my $data_rec = $app->read_record($FILESET, 'data', $data_key);
              next unless ($data_rec && $data_rec->{subs});
              foreach my $opt_key (split(';', $data_rec->{subs})) {
                next if ($string && $opt_key !~ /^$string:opt/);
                next unless ($opt_key =~ /(.*):opt$/);
                my $user_key = $1;
                my $user_rec = $app->read_record($FILESET, 'data', $user_key);
                if ($user_rec && $user_rec->{subs}) {
                  foreach my $sub_key (split(';', $user_rec->{subs})) {
                    if ($app->check_parent($sub_key, $data_key)) {
                      $error = 99 if $app->subs('rmv', 'sub', $sub_key, $user_key);
                    }
                  }
                }
              }
            } elsif ($method eq 'dfa') {
              my $data_rec = $app->read_record($FILESET, 'data', $data_key);
              next unless ($data_rec && $data_rec->{from});
              next if ($string && $data_rec->{from} ne $string);
              $data_rec->{from} = undef;
              $error = 99 if $app->save_record('data', $data_key, $data_rec);
            } elsif ($method eq 'opt' || $method eq 'sub') {
              my $data_rec = $app->read_record($FILESET, 'data', $data_key);
              next unless ($data_rec && $data_rec->{subs});
              foreach my $sub_key (split(';', $data_rec->{subs})) {
                next if ($string && $sub_key !~ /^$string:$method/);
                next unless ($sub_key =~ /(.*):$method$/);
                my $user_key = $1;
                $error = 99 if $app->subs('rmv', $method, $data_key, $user_key);
              }
            } elsif ($method eq 'inv') {
              $error = 99 if $app->purge_data($data_key);
            }
          }
          $error = 98 unless $error;   # purge ok
        } else {
          $error = 98;   # purge ok
        }
      } else {
        $error = 7;   # invalid mode
      }
    } else {
      $error = 3 unless $thekey;   # no key
      $error = 4 if $thekey;       # invalid key
    }
  }
  if ($app->{query}->param('advanced')) {
    $param{do_javascript} = 1;
    $param{xtra_deleter} = 1;
  }
  $param{notifier_message} = status_message($app, $error) if $error;
  $app->build_page('notifier.tmpl', \%param);
}

sub enabler {
  my $app = shift;
  my $auth = $app->{author};
  my $case = $app->{query}->param('case') || '';
  my $from = $app->{query}->param('from') || '';
  my $module = $app->{query}->param('module') || '';
  my %param = (do_javascript => 1, func_enabler => 1);
  my $error = 0;
  my $file = "$ENV{SCRIPT_FILENAME}~";
  $file =~ s/\/([^\/]|\n)*\~//;
  $file .= '/lib/MT/App/Comments.pm';
  if ($case) { 
    my $msg = 'Comment notification ';
    my ($blog_id, $mode) = split(':', $case);
    if ($blog_id && $mode) {
      if ($mode eq 'disabled' || $mode eq 'enabled') {
        require MT::Blog;
        if (my $blog = MT::Blog->load($blog_id)) {
          require MT::Permission;
          my $perm = MT::Permission->load({
            author_id => $auth->id,
            blog_id => $blog->id }
          );
          if ($perm) {
            $blog->email_new_comments(0) if ($mode eq 'disabled');
            $blog->email_new_comments(1) if ($mode eq 'enabled');
            $blog->save or $error = 1;
            $msg .= 'could not be ' if $error;
            $msg .= 'was ' unless $error;
            $msg .= $mode.' for '.$blog->name.'.';
          } else {
            $error = 5;   # no perm
          }
        } else {
          $error = 4;   # invalid key
        }
      } else {
        $error = 7;   # invalid mode
      }
    } else {
      $error = 3 unless $blog_id;            # no blog_id
      $error = 6 unless ($mode && $error);   # no mode
    }
    $param{notifier_message} = $app->translate($msg) unless $error;
  } elsif ($from) {
    my $data_rec = $app->read_record($FILESET, 'data', '0:0');
    $data_rec->{from} = $from;
    $error = 1 unless $app->save_record('data', '0:0', $data_rec);
  } elsif ($module) {
    $param{module_status} = module_magic($file, $module);
    my $status = 'added to';
    $status = 'removed from' if ($module eq 'remove');
    my $msg = "MT-Notifier was $status your Movable Type installation.";
    $param{notifier_message} = $app->translate($msg);
  }
  $param{module_status} = module_magic($file, 'verify');
  $param{notifier_message} = status_message($app, $error) if $error;
  $param{sender_address} = $app->get_sender_address('0:0');
  $app->build_page('notifier.tmpl', \%param);
}

sub manager {
  my $app = shift;
  my $method = $app->{query}->param('method') || '';
  my %param = (do_javascript => 1, func_manager => 1);
  my $error;
  if ($method) {
    return $app->manage_address if ($method eq 'bya');
    if (my $email = $app->{query}->param('email')) {
      my $dkey = $app->{query}->param('dkey') || '';
      if ($app->test_data_key($dkey)) {
        $app->subs('add', 'sub', $dkey, $email);
      } else {
        $error = 4;
      }
    }
    unless ($error) {
      return $app->manage_record if ($method eq 'byb');
      return $app->manage_record if ($method eq 'byc');
      return $app->manage_record if ($method eq 'bye');
      $error = 7;
    }
  }
  $param{notifier_message} = status_message($app, $error);
  $app->build_page('notifier.tmpl', \%param);
}

sub menu {
  my $app = shift;
  my %param = (func_default => 1);
  $app->build_page('notifier.tmpl', \%param);
}

sub notify {
  my $app = shift;
  my ($err, $comment) = @_;
  my $blog_id = $comment->blog_id;
  require MT::Blog;
  my $blog = MT::Blog->load($blog_id) or return;
  my $entry_id = $comment->entry_id;
  require MT::Entry;
  my $entry = MT::Entry->load($entry_id) or return;
  my $subs = $app->load_subs($blog_id, $entry_id);
  return unless scalar @$subs;
  my $author = $entry->author;
  $app->set_language($author->preferred_language)
    if ($author && $author->preferred_language);
  require MT::ConfigMgr;
  my $cfg = MT::ConfigMgr->instance;
  my $charset = $cfg->PublishCharset || 'iso-8859-1';
  my %head = (From => $app->get_sender_address('0:'.$entry_id));
  $head{'Content-Type'} = qq(text/plain; charset="$charset");
  $head{Subject} = '['.$blog->name.'] '.
    $app->translate('New Comment from \'[_1]\' ', $comment->author).
    $app->translate('on \'[_1]\' ', $entry->title);
  my %param = (
    blog_name => $blog->name,
    comment_name => $comment->name,
    comment_url => $comment->url,
    comment_text => $comment->text,
    entry_id => $entry->id,
    entry_link => $entry->permalink,
    entry_title => $entry->title,
    notifier_home => 'http://jayseae.cxliv.org/notifier/',
    notifier_link => $cfg->CGIPath.'mt-notifier.cgi',
    notifier_version => $VERSION
  );
  foreach my $sub (@$subs) {
    $head{To} = $sub;
    my $user_rec = $app->read_record($FILESET, 'user', $sub);
    $param{notifier_key} = $sub.':'.$user_rec->{code} if $user_rec;
    my $body = MT->build_email('notification.tmpl', \%param);
    require MT::Mail;
    MT::Mail->send(\%head, $body);
  }
}

sub transfer {
  my $app = shift;
  my $auth = $app->{author};
  my $convert = $app->{query}->param('convert') || '';
  my $mode = $app->{query}->param('mode') || '';
  my %param = (do_javascript => 1, func_transfer => 1);
  $param{sg_path} = '/home/username/public_html/commentsubscribe/subscriptions.inc';
  my $error = 0;
  my $msg = '';
  if ($convert) { 
    if ($mode eq 'n1x') {
      require MT::PluginData;
      foreach my $data (MT::PluginData->load({ plugin => 'Notifier' })) {
        my $data_key = $data->key;
        my $n1x_rec = $app->read_record('n1x', 'data', $data_key);
        if ($data_key eq '0:0') {
          # (0:0) Site
          if ($n1x_rec->{from}) {
            my $data_rec = $app->read_record($FILESET, 'sys', $data_key);
            ($data_rec->{from}) = split(':', $n1x_rec->{from});
            $app->save_record('sys', $data_key, $data_rec);
          }
        } elsif ($data_key =~ /^([0-9]+):0$/) {
          if ($app->test_data_key($data_key)) {
            # (X:0) Blog
            if ($n1x_rec->{from}) {
              my $data_rec = $app->read_record($FILESET, 'data', $data_key);
              ($data_rec->{from}) = split(':', $n1x_rec->{from});
              $app->save_record('data', $data_key, $data_rec);
            }
            if ($n1x_rec->{subs}) {
              foreach my $sub (split(';', $n1x_rec->{subs})) {
                my ($mail_key) = split(':', $sub);
                $app->subs('add', 'opt', $data_key, $mail_key);
              }
            }
          }
        } elsif ($data_key =~ /^([0-9]+):([0-9]+)$/) {
          # (X:Y) Entry
          $data_key = '0:'.$2;
          if ($app->test_data_key($data_key)) {
            if ($n1x_rec->{subs}) {
              foreach my $sub (split(';', $n1x_rec->{subs})) {
                my ($mail_key) = split(':', $sub);
                $app->subs('add', 'sub', $data_key, $mail_key);
              }
            }
          }
        }
      }
      $msg = 'Your conversion request completed successfully.';
    } elsif ($mode eq 'ezstc') {
      require MT::PluginData;
      foreach my $data (MT::PluginData->load({ plugin => 'subtocomm' })) {
        if ($data->key eq '0&0') {
          # (0&0) Site
          my $d = $data->data;
          my @custom = @$d;
          for (my $i = 5; $i < scalar @custom; $i++) {
            my $blogdata = $custom[$i];
            my $data_key = $blogdata->{blog_id}.':0';
            my $data_rec = $app->read_record($FILESET, 'data', $data_key);
            ($data_rec->{from}) = $blogdata->{mail}->{from};
            $app->save_record('data', $data_key, $data_rec);
          }
        } elsif ($data->key =~ /^([0-9]+)&0$/) {
          # (X&0) Blog
          my $data_key = $1.':0';
          my $data_rec = $data->data;           
          if ($data_rec) {
            my @subs = @$data_rec;
            foreach my $rec (@subs) {
              $app->subs('add', 'opt', $data_key, $rec->{email});
            }
          }
        } elsif ($data->key =~ /^([0-9]+)&([0-9]+)$/) {
          # (X&Y) Entry
          my $data_key = '0:'.$2;
          my $data_rec = $data->data;           
          if ($data_rec) {
            my @subs = @$data_rec;
            foreach my $rec (@subs) {
              if ($rec->{subscribe}) {
                if ($rec->{subscribe} eq 'subscribe') {
                  $app->subs('add', 'sub', $data_key, $rec->{email});
                } elsif ($rec->{subscribe} eq 'unsubscribe') {
                  $app->subs('add', 'opt', $data_key, $rec->{email});
                }
              }
            }
          }
        }
      }
      $msg = 'Your conversion request completed successfully.';
    } elsif ($mode eq 'sg') {
      $param{sg_path} = $app->{query}->param('path') || '';
      if (-f $param{sg_path}) {
        open (FILE, $param{sg_path}) || die "($param{sg_path}) Open Failed: $!\n";
        my @file = <FILE>;
        close (FILE);
        foreach my $line (@file) {
          my ($email, $entry_id, $entry_title, $entry_path) = split (/\|/, $line);
          $app->subs('add', 'sub', '0:'.$entry_id, $email);
        }
        $msg = 'Your conversion request completed successfully.';
      } else {
        $error = 96;   # file not found
      }
    } else {
      $error = 7;   # invalid mode
    }
  }
  $param{notifier_message} = $app->translate($msg) unless $error;
  $param{notifier_message} = status_message($app, $error) if $error;
  $app->build_page('notifier.tmpl', \%param);
}

# ===========================================================================
# Methods.
# ===========================================================================

sub build_key {
  my $app = shift;
  my $key = shift;
  my $var =
    substr ($key, 1, 1) .
    substr ($key, 5, 1) .
    substr ($key, 2, 1) .
    substr ($key, 4, 1) .
    substr ($key, 3, 1);
  crypt ($key, $var);
}

sub check_parent {
  # 0 - Not Parent
  # 1 - Is Parent
  my $app = shift;
  my ($child_key, $parent_key) = @_;
  return 0 unless ($child_key && $parent_key);
  return 0 if ($child_key eq $parent_key);
  return 0 if ($parent_key =~ /^0:([0-9]+)$/);
  if ($child_key =~ /^0:([0-9]+)$/) {
    # (0:Z) Entry
    my $ent_id = $1;
    require MT::Entry;
    my $ent = MT::Entry->load($ent_id);
    return 1 if ($ent && $parent_key eq $ent->blog_id.':0');
    if ($parent_key =~ /^([0-9]+):C$/) {
      # (Y:C) Category
      my $cat_id = $1;
      require MT::Placement;
      my $placement = MT::Placement->load({
        entry_id => $ent_id,
        category_id => $cat_id
      });
      return 1 if $placement;
    }
  } elsif ($child_key =~ /^([0-9]+):C$/) {
    # (Y:C) Category
    my $cat_id = $1;
    # no parent or child if keys are both cats
    return 0 if ($parent_key =~ /^([0-9]+):C$/);
    require MT::Category;
    my $cat = MT::Category->load($cat_id);
    return 1 if ($cat && $parent_key eq $cat->blog_id.':0');
  }
  0;
}

sub count_subs {
  # 0 - No Subscriptions Found
  # X - Count of Subscriptions
  my $app = shift;
  my ($data_type, $data_key) = @_;
  return 0 unless ($data_type eq 'data' || $data_type eq 'user');
  my $data_rec = $app->read_record($FILESET, $data_type, $data_key);
  if ($data_rec->{subs}) {
    my @subs = split(';', $data_rec->{subs});
    return scalar @subs;
  }
  0;
}

sub get_sender_address {
  my $app = shift;
  my $data_key = shift;
  my $sender = 'sender@domain.com';
  my $data_rec = $app->read_record($FILESET, 'data', '0:0');
  $sender = $data_rec->{from} if $data_rec && $data_rec->{from}; 
  return $sender if ($data_key eq '0:0');
  if ($data_key =~ /^0:([0-9]+)$/) {
    # (0:Z) Entry
    my $entry_id = $1;
    my $data_rec = $app->read_record($FILESET, 'data', $data_key);
    return $data_rec->{from} if $data_rec && $data_rec->{from};
    require MT::Placement;
    my $placement = MT::Placement->load
     ({ entry_id => $entry_id, is_primary => 1 }, { limit => 1 });
    $data_key = $placement->category_id.':C' if $placement;
  }
  if ($data_key =~ /^([0-9]+):C$/) {
    # (Y:C) Category
    my $category_id = $1;
    my $data_rec = $app->read_record($FILESET, 'data', $data_key);
    return $data_rec->{from} if $data_rec && $data_rec->{from};
    require MT::Category;
    my $category = MT::Category->load($category_id);
    $data_key = $category->blog_id.':0' if $category;
  }
  if ($data_key =~ /^([0-9]+):0$/) {
    # (X:0) Blog
    my $blog_id = $1;
    my $data_rec = $app->read_record($FILESET, 'data', $data_key);
    return $data_rec->{from} if $data_rec && $data_rec->{from};
  }
  $sender;
}

sub load_data_set {
  my $app = shift;
  my ($format, $rec_type, $chek_key, $chek_rec, $chek_txt) = @_;
  my @data_set;
  my @work_set = ();
  if ($format eq 'n2x') {
    require MT::PluginData;
    foreach my $data (MT::PluginData->load({ plugin => 'Notifier (n2x)' })) {
      if ($rec_type eq 'data') {
        push @data_set, $data->key unless ($data->key =~ /0:0|@/);
      } elsif ($rec_type eq 'user') {
        push @data_set, $data->key if ($data->key =~ /@/);
      }
    }
  }  # use else here to load from alternate data set (yaml, etc)
  if (@data_set && scalar @data_set) {
    return \@data_set if ($rec_type eq 'user' || $chek_rec eq 'inv');
    my ($chek_key_one, $chek_key_two) = split(/:/, $chek_key);
    foreach my $data_key (@data_set) {
      my ($data_key_one, $data_key_two) = split(/:/, $data_key);
      my $good_key = 0;
      if ($chek_key eq '0:0') {
        $good_key = 1;
      } elsif ($chek_key eq $data_key) {
        $good_key = 1;
      } elsif ($chek_key_two eq '0') {
        if ($data_key_two eq 'C') {
          require MT::Category;
          my $cat = MT::Category->load($data_key_one);
          $good_key = 1 if ($cat && $cat->blog_id eq $chek_key_one);
        } elsif ($data_key_two ne '0') {
          require MT::Entry;
          my $ent = MT::Entry->load($data_key_two);
          $good_key = 1 if ($ent && $ent->blog_id eq $chek_key_one);
        }
      } elsif ($chek_key_two eq 'C') {
        next unless ($data_key_two =~ /[0-9]+/);
        require MT::Placement;
        my $placement = MT::Placement->load
          ({ entry_id => $data_key_two,
             category_id => $chek_key_one });
        $good_key = 1 if ($placement);
      }
      if ($good_key) {
        if ($chek_txt) {
          my $data_rec = $app->read_record($FILESET, 'data', $data_key);
          my $mail_key = 0;
          if ($chek_rec eq 'all') {
            if ($data_rec->{from}) {
              $mail_key = 1 if ($data_rec->{from} =~ /$chek_txt/);
            }
            if ($data_rec->{subs}) {
              $mail_key = 1 if ($data_rec->{subs} =~ /$chek_txt/);
            }
          } elsif ($chek_rec eq 'dfa') {
            if ($data_rec->{from}) {
              $mail_key = 1 if ($data_rec->{from} =~ /$chek_txt/);
            }
          } else {
            foreach my $sub_key (split(/;/, $data_rec->{subs})) {
              if ($sub_key =~ /$chek_txt/) {
                if ($sub_key =~ /:9$/) {
                  $mail_key = 1 if ($chek_rec eq 'cor');
                  $mail_key = 1 if ($chek_rec eq 'opt');
                } else {
                  $mail_key = 1 if ($chek_rec eq 'sub');
                }
                last if ($mail_key);
              }
            }
          }
          push @work_set, $data_key if $mail_key;
        } else {
          push @work_set, $data_key;
        }
      }
    }
  }
  \@work_set;
}

sub load_subs {
  my $app = shift;
  my ($blog_id, $entry_id) = @_;
  my $blog_key = $blog_id.':0';
  my $entry_key = '0:'.$entry_id;
  my @work_opts;
  my @work_subs;
  my $data_rec = $app->read_record($FILESET, 'data', $entry_key);
  if ($data_rec) {
    if (my $sub_list = $data_rec->{subs}) {
      foreach my $sub (split(';', $sub_list)) {
        my ($sub_mail, $sub_type) = split(':', $sub);
        push @work_opts, $sub_mail if ($sub_type eq 'opt');
        push @work_subs, $sub_mail unless ($sub_type eq 'opt');
      }
    }
  }
  require MT::Placement;
  foreach my $placement (MT::Placement->load({ entry_id => $entry_id })) {
    my $category_key = $placement->category_id.':C';
    $data_rec = $app->read_record($FILESET, 'data', $category_key);
    if ($data_rec) {
      if (my $sub_list = $data_rec->{subs}) {
        foreach my $sub (split(';', $sub_list)) {
          my ($sub_mail, $sub_type) = split(':', $sub);
          push @work_opts, $sub_mail if ($sub_type eq 'opt');
          push @work_subs, $sub_mail unless ($sub_type eq 'opt');
        }
      }
    }
  }
  $data_rec = $app->read_record($FILESET, 'data', $blog_key);
  if ($data_rec) {
    if (my $sub_list = $data_rec->{subs}) {
      foreach my $sub (split(';', $sub_list)) {
        my ($sub_mail, $sub_type) = split(':', $sub);
        push @work_opts, $sub_mail if ($sub_type eq 'opt');
        push @work_subs, $sub_mail unless ($sub_type eq 'opt');
      }
    }
  }
  undef my %opts;
  undef my %subs;
  my @opts = sort grep(!$opts{$_}++, @work_opts);
  my @subs = sort grep(!$subs{$_}++, @work_subs);
  for (my $i = 0 ; $i < scalar @subs ; $i++) {
    splice(@subs, $i, 1) if (grep(/$subs[$i]/, @opts));
  }
  \@subs;
}

sub loop_addresses {
  my $app = shift;
  my $data_set = $app->load_data_set($FILESET, 'user');
  my @subs;
  foreach my $data_key (@$data_set) {
    my $user_rec = $app->read_record($FILESET, 'user', $data_key);
    push @subs, {
      sub_email => $data_key,
      sub_valid => $user_rec->{code}
    };
  }
  @subs = sort {
    $a->{sub_email} cmp $b->{sub_email}
  } @subs;
  @subs = ({ sub_email => 'Select an Address...' }, @subs) if scalar @subs;
  \@subs;
}

sub loop_blogs {
  my $app = shift;
  my $sort = shift;
  my $auth = $app->{author};
  my @blogs;
  require MT::Permission;
  foreach my $perms (MT::Permission->load({ author_id => $auth->id })) {
    next unless $perms->role_mask;
    require MT::Blog;
    my $blog = MT::Blog->load($perms->blog_id);
    if ($blog) {
      my $blog_key = $blog->id.':0';
      push @blogs, {
        blog_id => $blog->id,
        blog_name => $blog->name,
        blog_email_new_comments => $blog->email_new_comments,
        blog_subs => $app->count_subs('data', $blog_key)
      };
    }
  }
  if ($sort && $sort eq 'subs') {
    @blogs = sort {
      $b->{blog_subs} <=> $a->{blog_subs} ||
      $a->{blog_name} cmp $b->{blog_name}
    } @blogs;
  } else {
    @blogs = sort {
      $a->{blog_name} cmp $b->{blog_name}
    } @blogs;
  }
  @blogs = ({ blog_name => 'Select a Blog...' }, @blogs) if scalar @blogs;
  \@blogs;
}

sub loop_categories {
  my $app = shift;
  my $auth = $app->{author};
  my @cats;
  require MT::Permission;
  foreach my $perms (MT::Permission->load({ author_id => $auth->id })) {
    next unless $perms->role_mask;
    require MT::Category;
    foreach my $cat (MT::Category->load({ blog_id => $perms->blog_id })) {
      my $cat_key = $cat->id.':C';
      push @cats, {
         category_id => $cat->id,
         category_label => $cat->label,
         category_subs => $app->count_subs('data', $cat_key)
      };
    }
  }
  @cats = sort {
    $b->{category_subs} <=> $a->{category_subs} ||
    $a->{category_label} cmp $b->{category_label}
  } @cats;
  @cats = ({ category_label => 'Select a Category...' }, @cats) if scalar @cats;
  \@cats;
}

sub loop_entries {
  my $app = shift;
  my $auth = $app->{author};
  my @entries;
  require MT::Permission;
  foreach my $perms (MT::Permission->load({ author_id => $auth->id })) {
    next unless $perms->role_mask;
    require MT::Entry;
    foreach my $entry (MT::Entry->load({ blog_id => $perms->blog_id })) {
      my $entry_key = '0:'.$entry->id;
      push @entries, {
        entry_blog_id => $entry->blog_id,
        entry_id => $entry->id,
        entry_title => $entry->title,
        entry_subs => $app->count_subs('data', $entry_key)
      };
    }
  }
  @entries = sort {
    $b->{entry_subs} <=> $a->{entry_subs} ||
    $a->{entry_title} cmp $b->{entry_title}
  } @entries;
  @entries = ({ entry_title => 'Select an Entry...' }, @entries) if scalar @entries;
  \@entries;
}

sub loop_subs {
  my $app = shift;
  my ($sub_mode, $sub_list, $mail_key) = @_;
  my ($name, $type, $link);
  my @subs;
  if ($sub_list) {
    my $method = 'bya';
    foreach my $data_key (split(/;/, $sub_list)) {
      if ($mail_key) {
        ($name, $type, $link) = $app->read_sub($data_key);
        my $data_rec = $app->read_record($FILESET, 'data', $data_key);
        $method = 'byb' if ($type eq 'Blog');
        $method = 'byc' if ($type eq 'Category');
        $method = 'bye' if ($type eq 'Entry');
        push @subs, {
          sub_name   => $name,
          sub_type   => $type,
          sub_link   => $link,
          sub_key    => $data_key,
          sub_method => $method
        } if ($data_rec->{subs} =~ /$mail_key:$sub_mode/);
      } else {
        ($name, $type) = split(/:/, $data_key);
        if ($type eq $sub_mode) {
          my $user_rec = $app->read_record($FILESET, 'user', $name);
          push @subs, {
            sub_name   => $name,
            sub_type   => '',
            sub_key    => $name.':'.$user_rec->{code},
            sub_method => $method
          };
        }
      }
    }
  }
  @subs = sort {
    $a->{sub_type} cmp $b->{sub_type} ||
    $a->{sub_name} cmp $b->{sub_name}
  } @subs;
  \@subs;
}

sub manage_address {
  my $app = shift;
  my $akey = $app->{query}->param('akey');
  my $mode = $app->{query}->param('__mode');
  my $method = $app->{query}->param('method') if $mode;
  my ($mail, $code) = split(':', $akey) if $akey;
  my %param = (by_address => 1, do_javascript => 1, manage_items => 1, query => $method);
  my $error;
  if ($mail && $code) {
    $param{akey} = $akey;
    $param{code} = $code;
    $param{mail} = $mail;
    my $user_rec = $app->read_record($FILESET, 'user', $mail);
    if ($code eq $user_rec->{code}) {
      if ($app->{query}->param('purge')) {
        $error = 99 if $app->purge_user($mail);
        $user_rec = $app->read_record($FILESET, 'user', $mail);
      } elsif (my $off = $app->{query}->param('off')) {
        my ($key, $type) = split('~', $off);
        $error = $app->subs('rmv', $type, $key, $mail);
        $user_rec = $app->read_record($FILESET, 'user', $mail);
      } elsif (my $set = $app->{query}->param('set')) {
        $error = $app->subs('add', 'opt', $set, $mail);
        $user_rec = $app->read_record($FILESET, 'user', $mail);
      }
      my $sub_list = $user_rec->{subs};
      my $opts = $app->loop_subs('opt', $sub_list, $mail);
      $param{opt_foot} = scalar @$opts;
      $param{opt_loop} = \@$opts;
      my $subs = $app->loop_subs('sub', $sub_list, $mail);
      $param{sub_foot} = scalar @$subs;
      $param{sub_loop} = \@$subs;
      $param{valid} = 1;
    } else {
      $error = 10;
    }
  } elsif ($param{dkey} = $app->{query}->param('dkey')) {
    $mail = $app->{query}->param('mail');
    $error = $app->subs('add', 'sub', $param{dkey}, $mail);
    unless ($error) {
      my ($name, $type, $link) = $app->read_sub($param{dkey});
      $param{sub_link} = $link;
      $param{sub_name} = $name;
      $param{sub_type} = $type;
    } else {
      $param{error} = 1;
    }
    $param{manage_user} = 1;
    $param{mail} = $mail;
  }
  $param{notifier_message} = status_message($app, $error);
  $app->build_page('notifier.tmpl', \%param);
}

sub manage_record {
  my $app = shift;
  my $akey = $app->{query}->param('akey');
  my $dkey = $app->{query}->param('dkey');
  my $mode = $app->{query}->param('__mode');
  my $method = $app->{query}->param('method') if $mode;
  my %param = (do_javascript => 1, manage_items => 1, query => $method);
  $dkey = $app->{query}->param('off') unless $dkey;
  $dkey = $app->{query}->param('set') unless $dkey;
  my $error;
  if ($dkey) {
    $dkey =~ s/~(opt|sub)//;
    if ($app->test_data_key($dkey)) {
      my ($mail, $code) = split(':', $akey) if $akey;
      my ($blog_id, $entry_id) = split(':', $dkey);
      my $data_rec = $app->read_record($FILESET, 'data', $dkey);
      if ($app->{query}->param('purge')) {
        $error = 99 if $app->purge_data($dkey);
        $data_rec = $app->read_record($FILESET, 'data', $dkey);
      } elsif (my $drop = $app->{query}->param('remove')) {
        $data_rec->{from} = '';
        $app->save_record('data', $dkey, $data_rec);
      } elsif (my $from = $app->{query}->param('from')) {
        $data_rec->{from} = $from;
        $app->save_record('data', $dkey, $data_rec);
      } elsif (my $off = $app->{query}->param('off')) {
        my ($key, $type) = split('~', $off);
        $error = $app->subs('rmv', $type, $key, $mail);
        $data_rec = $app->read_record($FILESET, 'data', $dkey);
      } elsif (my $set = $app->{query}->param('set')) {
        $error = $app->subs('add', 'opt', $set, $mail);
        $data_rec = $app->read_record($FILESET, 'data', $dkey);
      }
      if ($method eq 'byb') {
        $param{by_blog} = 1;
        require MT::Blog;
        if (my $blog = MT::Blog->load($blog_id)) {
          $param{blog_name} = $blog->name;
          $param{blog_description} = $blog->description || 'No Description';
          $param{blog_url} = $blog->site_url;
        } else {
          $param{blog_name} = 'Unknown Blog';
          $param{blog_description} = 'Description Unavailable';
        }
      } elsif ($method eq 'byc') {
        $param{by_category} = 1;
        require MT::Category;
        if (my $category = MT::Category->load($blog_id)) {
          require MT::Blog;
          if (my $blog = MT::Blog->load($category->blog_id)) {
            $param{category_blog_name} = $blog->name;
            $param{category_blog_url} = $blog->site_url;
          } else {
            $param{category_blog_name} = 'Unknown Blog';
          }
          my ($name, $type, $link) = $app->read_sub($dkey);
          $param{category_description} = $category->description || 'No Description';
          $param{category_link} = $link;
          $param{category_label} = $category->label;
        } else {
          $param{category_label} = 'Unknown Category';
        }
      } elsif ($method eq 'bye') {
        $param{by_entry} = 1;
        require MT::Entry;
        if (my $entry = MT::Entry->load($entry_id)) {
          require MT::Blog;
          if (my $blog = MT::Blog->load($entry->blog_id)) {
            $param{entry_blog_name} = $blog->name;
            $param{entry_blog_url} = $blog->site_url;
          } else {
            $param{entry_blog_name} = 'Unknown Blog';
          }
          $param{entry_date} = format_ts("%B %d, %Y", $entry->created_on);
          $param{entry_excerpt} = $entry->get_excerpt;
          $param{entry_permalink} = $entry->permalink;
          $param{entry_title} = $entry->title;
        } else {
          $param{entry_title} = 'Unknown Entry';
        }
      }
      $param{sender_address} = $app->get_sender_address($dkey);
      my $sub_list = $data_rec->{subs};
      my $opts = $app->loop_subs('opt', $sub_list);
      $param{opt_foot} = scalar @$opts;
      $param{opt_loop} = \@$opts;
      my $subs = $app->loop_subs('sub', $sub_list);
      $param{sub_foot} = scalar @$subs;
      $param{sub_loop} = \@$subs;
      $param{valid} = 1;
      $param{akey} = $akey;
      $param{dkey} = $dkey;
    } else {
      $param{func_manager} = 1;
      $param{manage_items} = 0;
      $error = 4;
    }
  } else {
    $param{func_manager} = 1;
    $param{manage_items} = 0;
    $error = 3;
  }
  $param{notifier_message} = status_message($app, $error);
  $app->build_page('notifier.tmpl', \%param);
}

sub purge_data {
  # 0 - Data Purged
  # 1 - Purge Error
  my $app = shift;
  my $data_key = shift;
  my $error;
  my $data_rec = $app->read_record($FILESET, 'data', $data_key);
  $data_rec->{from} = undef;
  $app->save_record('data', $data_key, $data_rec);
  if (my $sub_list = $data_rec->{subs}) {
    foreach my $sub_key (split(/;/, $sub_list)) {
      my ($mail, $type) = split(':', $sub_key);
      $error = 1 if $app->subs('rmv', $type, $data_key, $mail);
    }
  }
  $error;
}

sub purge_user {
  # 0 - User Purged
  # 1 - Purge Error
  my $app = shift;
  my $user_key = shift;
  my $error;
  my $user_rec = $app->read_record($FILESET, 'user', $user_key);
  $user_rec->{code} = undef;
  $app->save_record('user', $user_key, $user_rec);
  if (my $sub_list = $user_rec->{subs}) {
    foreach my $data_key (split(/;/, $sub_list)) {
      my $data_rec = $app->read_record($FILESET, 'data', $data_key);
      if ($data_rec && $data_rec->{subs}) {
        if ($data_rec->{subs} =~ /$user_key:(opt|sub)/) {
          $error = 1 if $app->subs('rmv', $1, $data_key, $user_key);
        }
      }
    }
  }
  $error;
}


sub read_record {
  my $app = shift;
  my ($format, $type, $key) = @_;
  my %record;
  if ($format eq 'n1x') {
    require MT::PluginData;
    my $data = MT::PluginData->load({ plugin => 'Notifier', key => $key });
    if ($data) {
      $record{from} = $data->data->{'senderaddress'} if ($data->data->{'senderaddress'});
      $record{subs} = $data->data->{'subscriptions'} if ($data->data->{'subscriptions'});
    }
  } elsif ($format eq 'n2x') {
    require MT::PluginData;
    my $data = MT::PluginData->load({ plugin => 'Notifier (n2x)', key => $key });
    if ($data) {
      if ($type eq 'data') {
        $record{from} = $data->data->{'from'} if ($data->data->{'from'});
        $record{subs} = $data->data->{'subs'} if ($data->data->{'subs'});
      } elsif ($type eq 'user') {
        $record{code} = $data->data->{'code'} if ($data->data->{'code'});
        $record{subs} = $data->data->{'subs'} if ($data->data->{'subs'});
      } elsif ($type eq 'sys') {
        $record{from} = $data->data->{'from'} if ($data->data->{'from'});
      }
    }
    if ($type eq 'user') {
      $record{code} = $app->build_key($key) unless $record{code};
    }
  }
  \%record;
}

sub read_sub {
  my $app = shift;
  my $skey = shift;
  my ($link, $name, $type);
  my @subs;
  if ($app->test_data_key($skey)) {
    if ($skey =~ /^([0-9]+):0$/) {
      # (X:0) Blog
      my $blog_id = $1;
      $type = 'Blog';
      require MT::Blog;
      if (my $blog = MT::Blog->load($blog_id)) {
        $link = $blog->site_url;
        $name = $blog->name;
      }
    } elsif ($skey =~ /^([0-9]+):C$/) {
      # (Y:C) Category
      my $cat_id = $1;
      $type = 'Category';
      require MT::Category;
      if (my $cat = MT::Category->load($cat_id)) {
        $name = $cat->label;
        require MT::Blog;
        if (my $blog = MT::Blog->load($cat->blog_id)) {
          $link = $blog->archive_url;
          $link .= '/' unless $link =~ m/\/$/;
          $link .= archive_file_for ('',  $blog, $type, $cat);
        }
      }
    } elsif ($skey =~ /^0:([0-9]+)$/) {
      # (0:Z) Entry
      my $ent_id = $1;
      $type = 'Entry';
      require MT::Entry;
      if (my $ent = MT::Entry->load
        ({ id => $ent_id, status => MT::Entry::RELEASE() })) {
        $link = $ent->permalink;
        $name = $ent->title;
      }
    }
  }
  ($name, $type, $link);
}

sub save_record {
  # 0 - Error During Save
  # 1 - Record Saved
  my $app = shift;
  my ($type, $key, $record) = @_;
  my $content = 0;
  if ($record) {
    if ($type eq 'data') {
      $content = 1 if (
        $record->{from} ||
        $record->{subs}
     );
    } elsif ($type eq 'user') {
      $content = 1 if (
        $record->{subs}
     );
    } elsif ($type eq 'sys') {
      $content = 1 if (
        $record->{from}
     );
    }
  }
  if ($FILESET eq 'n2x') {
    require MT::PluginData;
    my $data = MT::PluginData->load
     ({ plugin => 'Notifier (n2x)',
        key => $key });
    if ($data) {
      if ($content) {
        $data->data ($record);
        $data->save or return 0;
      } else {
        $data->remove or return 0;
      }
    } else {
      if ($content) {
        $data = MT::PluginData->new;
        $data->key($key);
        $data->plugin('Notifier (n2x)');
        $data->data ($record);
        $data->save or return 0;
      }
    }
  }
  1;
}

sub subs {
  my $app = shift;
  my ($action, $method, $key, $mail) = @_;
  my %modes = (
    addopt => 1,
    addsub => 1,
    rmvopt => 1,
    rmvsub => 1
  );

  return 6 unless ($modes{$action.$method});

  if ($app->test_data_key($key)) {
    require MT::Util;
    if (my $fixed = MT::Util::is_valid_email($mail)) {
      $mail = $fixed;
    } else {
      return 8;
    }
  } else {
    return 4 unless ($action eq 'rmv');
  }

  my $data_rec = $app->read_record($FILESET, 'data', $key);
  my $user_rec = $app->read_record($FILESET, 'user', $mail);
  my $user_bak = $user_rec;
  my @data_subs;
  my @user_subs;
  my $found = 1;

  if ($data_rec->{subs}) {
    my $subs = $data_rec->{subs};
    if ($action eq 'add' && $method eq 'sub') {
      return 9 if ($subs =~ /$mail:opt/);
    }
    @data_subs = split(/;/, $subs);
    if ($subs =~ /$mail/) {
      $found = 0;
      for (my $i = 0 ; $i < scalar @data_subs ; $i++) {
        if ($data_subs[$i] =~ /^$mail:$method$/) {
          splice(@data_subs, $i, 1);
          $found = 1;
          last;
        } elsif ($data_subs[$i] =~ /$mail:sub/) {
          splice(@data_subs, $i, 1) if ($method eq 'opt');
          $found = 1;
          last;          
        }
      }
    }
  } else {
    return 0 unless ($action eq 'add');
  }

  if ($user_rec->{subs}) {
    @user_subs = split(/;/, $user_rec->{subs});
    if ($user_rec->{subs} =~ /$key/) {
      for (my $i = 0 ; $i < scalar @user_subs; $i++) {
        if ($user_subs[$i] =~ /$key/) {
          splice(@user_subs, $i, 1) if $found;
          last;
        }
      }
    }
  }

  if ($action eq 'add') {
    push @data_subs, $mail.':'.$method;
    push @user_subs, $key;
  }

  $data_rec->{subs} = join ';', @data_subs;
  $user_rec->{subs} = join ';', @user_subs;

  my $status;
  $status = $app->save_record('user', $mail, $user_rec) or return 1;
  $status = $app->save_record('data', $key, $data_rec)
    or $app->save_record('user', $mail, $user_bak);
  return 2 unless $status;
  0;
}

sub subscribe {
  my $app = shift;
  my $comment = shift;
  my $data_key = '0:'.$comment->entry_id;
  my $mail_key = $comment->email;
  $app->subs('add', 'sub', $data_key, $mail_key);
}

sub test_data_key {
  # 0 - Invalid Key
  # 1 - Valid Key
  my $app = shift;
  my ($data_key, $skip_perm) = @_;
  my $blog_id;
  if ($data_key eq '0:0') {
    # (0:0) Site
    return 1;
  } elsif ($data_key =~ /^([0-9]+):0$/) {
    # (X:0) Blog
    $blog_id = $1;
  } elsif ($data_key =~ /^([0-9]+):C$/) {
    # (Y:C) Category
    my $cat_id = $1;
    require MT::Category;
    my $cat = MT::Category->load
      ($cat_id) or return 0;
    $blog_id = $cat->blog_id;
  } elsif ($data_key =~ /^0:([0-9]+)$/) {
    # (0:Z) Entry
    my $ent_id = $1;
    require MT::Entry;
    my $ent = MT::Entry->load
     ($ent_id) or return 0;
    $blog_id = $ent->blog_id;
  } else {
    # (???) Invalid
    return 0;
  }
  require MT::Blog;
  my $blog = MT::Blog->load
    ($blog_id) or return 0;
  return 1 if $skip_perm;
  my $auth;
  eval { $auth = $app->{author} };
  unless ($@) {
    if ($auth) {
      require MT::Permission;
      my $perm = MT::Permission->load
        ({ author_id => $auth->id,
           blog_id => $blog_id });
      return 0 unless $perm;
    }
  }
  1;
}

# ===========================================================================
# Subs.
# ===========================================================================

sub build_page {
  my $app = shift;
  my($file, $param) = @_;
  $param->{notifier_script_url} = $app->path.$app->script;
  $param->{notifier_script_version} = $VERSION;
  if (my $auth = $app->{author}) {
    $app->{breadcrumbs} = [ { bc_name => 'Notifier', bc_uri => '?__mode=mnu' } ];
    if ($param->{manage_items}) {
      $app->add_breadcrumb('Manage MT-Notifier', '?__mode=mgr');
      $app->add_breadcrumb('By Address') if $param->{by_address};
      $app->add_breadcrumb('By Blog') if $param->{by_blog};
      $app->add_breadcrumb('By Category') if $param->{by_category};
      $app->add_breadcrumb('By Entry') if $param->{by_entry};
    } elsif ($param->{func_enabler}) {
      my $blogs = $app->loop_blogs;
      $param->{blog_loop} = \@$blogs;
      $param->{blog_count} = scalar @$blogs;
      $app->add_breadcrumb('Configure MT-Notifier');
    } elsif ($param->{func_transfer}) {
      $app->add_breadcrumb('Transfer to MT-Notifier');
    } elsif (!$param->{func_default}) {
      my $blogs = $app->loop_blogs('subs');
      $param->{blog_loop} = \@$blogs;
      $param->{blog_count} = scalar @$blogs;
      my $categories = $app->loop_categories;
      $param->{category_loop} = \@$categories;
      $param->{category_count} = scalar @$categories;
      my $entries = $app->loop_entries;
      $param->{entry_loop} = \@$entries;
      $param->{entry_count} = scalar @$entries;
      if ($param->{func_deleter}) {
        $app->add_breadcrumb('Purge MT-Notifier');
      } elsif ($param->{func_manager}) {
        my $addresses = $app->loop_addresses;
        $param->{address_loop} = \@$addresses;
        $param->{address_count} = scalar @$addresses;
        $app->add_breadcrumb('Manage MT-Notifier');
      }
    }
  } else {
    if ($param->{manage_user}) {
      $app->{breadcrumbs} = [ { bc_name => 'Comment Subscription' } ];
    } elsif ($param->{manage_items}) {
      $app->{breadcrumbs} = [ { bc_name => 'User Management' } ];
    }
  }
  $app->SUPER::build_page($file, $param);
}

sub module_magic {
  my ($module, $method) = @_;
  if (-f $module) {
    my @in;
    my @out;
    open (ONE, $module) || die "($module) Open Failed: $!\n";
    @in = <ONE>;
    close (ONE);
    if ($method eq 'verify') {
      my $count = grep { /jayseae::notifier/ } @in;
      return $count;
    }
    foreach my $line (@in) {
      next if ($line =~ m|jayseae::notifier|);
      push @out, $line;
      if ($line =~ m|\$comment->save;|) {
        if ($method eq 'update') {
          my $tag = "\t".'# jayseae::notifier';
          push @out, '                                                  '.$tag."\r\n";
          push @out, '        if ($q->param(\'subscribe\')) {           '.$tag."\r\n";
          push @out, '          require jayseae::notifier;              '.$tag."\r\n";
          push @out, '          jayseae::notifier->subscribe($comment); '.$tag."\r\n";
          push @out, '        }                                         '.$tag."\r\n";
        }
      }
    }
    open (TWO, ">$module") || die "($module) Open Failed: $!\n";
    foreach my $line (@out) {
      print TWO $line;
    }
    close ( TWO );
  }
}

sub status_message {
  my $app = shift;
  my $error = shift;
  my $msg;
  return unless $error;
  $msg = 'An error was encountered saving the record.'      if ($error == 1);
  $msg = 'An error was encountered, some data was changed.' if ($error == 2);
  $msg = 'Your request did not include a record key.'       if ($error == 3);
  $msg = 'Your request included an invalid record key.'     if ($error == 4);
  $msg = 'You do not have permission to that record.'       if ($error == 5);
  $msg = 'Your request did not specify a processing mode.'  if ($error == 6);
  $msg = 'You requested an invalid mode of processing.'     if ($error == 7);
  $msg = 'You specified an invalid email address.'          if ($error == 8);
  $msg = 'An opt-out record exists for the specified key.'  if ($error == 9);
  $msg = 'You entered an incorrect address and/or code.'    if ($error == 10);
  $msg .= '  Please correct the error and try again.';
  $msg = 'No file was found at the specified location.'     if ($error == 96);
  $msg = 'No records were found to match your request.'     if ($error == 97);
  $msg = 'Your purge request completed successfully.'       if ($error == 98);
  $msg = 'Some errors were encountered during processing.'  if ($error == 99);
  return $app->translate($msg);
}

1;

# ===========================================================================
# Data Record
# ---------------------------------------------------------------------------
# Record Key:
# ---------------------------------------------------------------------------
# x:0 for each blog.                               (v1.0)
# x:y for the entry.                               (v1.0)
#
# x:0 for each blog.                               (v2.0)
# y:C is a category.                               (v2.0)
# 0:z for the entry.                               (v2.0)
# ---------------------------------------------------------------------------
# Record Fields (name, layout, version):
# ---------------------------------------------------------------------------
# - subscriptions = name@domain.com:key;           (v1.0)
#
# - senderaddress = name@domain.com                (v1.2)
# - subscriptions = name@domain.com:key;           (v1.2)
#
# - senderaddress = name@domain.com:key            (v1.4)
# - subscriptions = name@domain.com:key;           (v1.4)
#
# - from = name@domain.com                         (v2.0)
# - subs = name@domain.com:opt or sub;             (v2.0)
# ===========================================================================

# ===========================================================================
# System Record
# ---------------------------------------------------------------------------
# Record Key:
# ---------------------------------------------------------------------------
# 0:0.
# ---------------------------------------------------------------------------
# Record Fields (name, layout, version):
# ---------------------------------------------------------------------------
# - from = name@domain.com                         (v2.0)
# ===========================================================================

# ===========================================================================
# User Record
# ---------------------------------------------------------------------------
# Record Key:
# ---------------------------------------------------------------------------
# name@domain.com (email address).                 (v2.0)
# ---------------------------------------------------------------------------
# Record Fields (name, layout, version):
# ---------------------------------------------------------------------------
# - code = user verification code                  (v2.0)
# - subs = user subscription keys;                 (v2.0)
# ===========================================================================

# ===========================================================================
# To add storage formats, modify:
# - sub load_data_set (to retrieve a selection of records)
# - sub read_record (to read a single record)
# - sub save_record (to save or delete a single record)
# ===========================================================================
