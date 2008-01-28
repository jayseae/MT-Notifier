# ---------------------------------------------------------------------------
# MT-Notifier: Configure subscriptions to your blog entries.
# A Plugin for Movable Type
#
# Release 1.4.1
# March 17, 2004
#
# http://www.cxliv.org/jayseae/notifier/
#
# Copyright 2003-2004, Chad Everett (plugins@cxliv.org)
#
# The program is licensed under the Open Software License version 2.0
# http://www.opensource.org/licenses/osl-2.0.php
#
# If you find the software useful or even like it, then a simple 'thank you'
# is always appreciated.  A reference back is even nicer so others can find
# out about me.  If you figure out how you can make money from the software,
# do what you feel is right.  I do have a wish list at Amazon if you are in
# need of an idea.  :)
# ---------------------------------------------------------------------------
package jayseae::notifier;

use strict;

use vars qw( @ISA $VERSION );
$VERSION = 1.4.1;

use MT::App;
@ISA = qw( MT::App );

sub init {
  my $app = shift;
  $app->SUPER::init (@_) or return;
  $app->add_methods (
    default => \&default,
    csg     => \&convertsg,
    purge   => \&purgedata,
    cfg     => \&subscribe,
    uncfg   => \&subscribe,
    sub     => \&subscribe,
    unsub   => \&subscribe,
    mod     => \&fixmodule,
    unmod   => \&fixmodule,
    addback => \&fixmodule,
    delback => \&fixmodule,
    resback => \&fixmodule
    );
  $app->{default_mode} = 'default';
  $app->{template_dir} = 'cms';
  my $auth = $app->{query}->param ( '__auth' );
  my $mode = $app->{query}->param ( '__mode' );
  $app->{requires_login} =
    !$mode ||
    $mode eq 'inmtn' ||
    $mode eq 'csg' ||
    $mode eq 'purge' ||
    $mode eq 'cfg' ||
    $mode eq 'uncfg' ||
    $mode eq 'mod' ||
    $mode eq 'unmod' ||
    $mode eq 'addback' ||
    $mode eq 'delback' ||
    $mode eq 'resback' ||
    $auth ?
    1 : 0;
  $app->{user_class} = 'MT::Author';
  $app->{is_admin} = 1;
  $app;
}

sub default {
  my $app = shift;
  my %param = (
    app_version => $VERSION,
    mt_script_url => $app->{cfg}->CGIPath . 'mt.cgi'
  );
  if ( my $auth = $app->{author} ) {
    $param{author_id} = $auth->id;
    $param{author_name} = $auth->name;
    $param{blog_loop} = _loop_blogs ();
    $param{entry_loop} = _loop_entries ();
    $param{module_loop} = _loop_modules ();
    $param{cfg_loop} = _loop_subs ( 'cfgs', $auth );
    $param{opt_loop} = _loop_subs ( 'opts', $auth );
    $param{sub_loop} = _loop_subs ( 'subs', $auth );
    $param{top_blog_loop} = _loop_top_blogs ( $auth );
  }
  $app->build_page( 'notifier.tmpl', \%param );
}

sub convertsg {
  my $app = shift;
  my $auth = $app->{author};
  my %param = (
    author_id => $auth->id,
    author_name => $auth->name,
    blog_loop => _loop_blogs (),
    entry_loop => _loop_entries (),
    module_loop => _loop_modules (),
    cfg_loop => _loop_subs ( 'cfgs', $auth ),
    opt_loop => _loop_subs ( 'opts', $auth ),
    sub_loop => _loop_subs ( 'subs', $auth ),
    top_blog_loop => _loop_top_blogs ( $auth ),
  );
  my %stats = (
    conversion => 1,
  );

  #
  # specify the full path to the scriptygoddess subscription file
  # this is the same as $pathToLists, found in comment_config.php
  # append / and the name of the file - usually subscriptions.inc
  #
  my $sgs = '/home/username/public_html/commentsubscribe/subscriptions.inc';
  #
  # then call script with __mode=csg:
  # http://www.example.com/cgi-bin/mt/mt-notifier.cgi?__mode=csg
  #
  open ( FILE, $sgs ) || die "( $sgs ) Open Failed: $!\n";
  my @file = <FILE>;
  close (FILE);

  foreach my $line (@file) {
    my ( $email, $entry_id, $entry_title, $entry_path ) = split ( /\|/, $line );
    $app->{sub_entry_id} = $entry_id;
    $app->{sub_email} = $email;
    subscribe ( $app, 'api' );
  }

  $param{notifier_message} = _parse_status_message ( \%param, \%stats );
  $app->build_page( 'notifier.tmpl', \%param );
}

sub fixmodule {
  my $app = shift;
  my $auth = $app->{author};
  my $q = $app->{query};
  my %param = (
    app_version => $VERSION,
    mod_mode => $q->param ( '__mode' ),
    mt_script_url => $app->{cfg}->CGIPath . 'mt.cgi'
  );
  my %stats = (
    backupdone => 0,
    backupfail => 0,
    cannotsave => 0,
    notamodule => 0,
    removedone => 0,
    removefail => 0,
    rescuedone => 0,
    rescuefail => 0,
    updatedone => 0,
    updatefail => 0
  );

  $param{mod_id} = $q->param ( 'mod_id' ) or $stats{notamodule} = 1;

  unless ( $stats{notamodule} ) {
    my $status = _update_module ( $param{mod_id}, $param{mod_mode} );
    if ( $param{mod_mode} eq 'mod' ) {
      $stats{updatedone} = 1 if ( $status == 0 );
      $stats{updatefail} = 1 if ( $status != 0 );
    } elsif ( $param{mod_mode} eq 'unmod' ) {
      $stats{removedone} = 1 if ( $status == 1 );
      $stats{removefail} = 1 if ( $status != 1 );
    } elsif ( $param{mod_mode} eq 'addback' ) {
      $stats{backupfail} = 1 if ( $status == 4 );
      $stats{cannotsave} = 1 if ( $status == 5 );
      $stats{backupdone} = 1 if ( $status == 6 );
    } elsif ( $param{mod_mode} eq 'delback' ) {
      $stats{removefail} = 1 if ( $status == 7 );
      $stats{cannotsave} = 1 if ( $status == 8 );
      $stats{removedone} = 1 if ( $status == 9 );
    } elsif ( $param{mod_mode} eq 'resback' ) {
      $stats{rescuefail} = 1 if ( $status == 10 );
      $stats{rescuedone} = 1 if ( $status == 11 );
    }
  }

  $param{author_id} = $auth->id;
  $param{author_name} = $auth->name;
  $param{blog_loop} = _loop_blogs ();
  $param{entry_loop} = _loop_entries ();
  $param{module_loop} = _loop_modules ();
  $param{cfg_loop} = _loop_subs ( 'cfgs', $auth );
  $param{opt_loop} = _loop_subs ( 'opts', $auth );
  $param{sub_loop} = _loop_subs ( 'subs', $auth );
  $param{top_blog_loop} = _loop_top_blogs ( $auth );
  $param{notifier_message} = _parse_status_message ( \%param, \%stats );
  $app->build_page( 'notifier.tmpl', \%param );
}

sub notify {
  my ( $app, $blog, $entry, $comment ) = @_;
  my $blog_id = $blog->id;
  my $key = $comment->blog_id . ':' . $comment->entry_id;
  my $not_uri = $app->base . $app->path . 'mt-notifier.cgi?';
  my $q = $app->{query};
  my @opt = ();
  my $data = '';

  subscribe ( $app, 'api' ) if ( $q->param ( 'subscribe' ) );

  require MT::PluginData;
  $data = MT::PluginData->load ( { plugin => 'Notifier', key => $comment->blog_id . ':0' } );
  if ( $data ) {
    foreach my $opt ( split ( /;/, $data->data->{'subscriptions'} ) ) {
      my ( $opt_add, $opt_key ) = split ( /:/, $opt );
      push @opt, $opt_add;
    }
  }
  my $sender = _get_sender_address ( $comment->blog_id, $comment->entry_id );
  $data = MT::PluginData->load ( { plugin => 'Notifier', key => $key } );
  if ( $data ) {
    require MT::Mail;
    foreach my $sub ( split ( /;/, $data->data->{'subscriptions'} ) ) {
      my ( $sub_add, $sub_key ) = split ( /:/, $sub );
      my $opt_on = 0;
      foreach my $opt_add ( @opt ) {
        $opt_on = 1 if ( $opt_add eq $sub_add );
      }
      if ( !$opt_on ) {
        my %head = (
               To => $sub_add,
             From => $sender,
          Subject => '[' . $blog->name . '] ' . $app->translate('New Comment Posted to \'[_1]\'', $entry->title )
        );
        my $charset = $app->{cfg}->PublishCharset || 'iso-8859-1';
        $head{'Content-Type'} = qq ( text/plain; charset="$charset" );
        my $body = $app->translate ( 'A new comment has been posted to \'[_1]\'.', $entry->title );
        require Text::Wrap;
        $Text::Wrap::cols = 72;
        $body = Text::Wrap::wrap ( '', '', $body ) . "\n" .
          $entry->permalink . "\n\n" .
          $app->translate ( 'Author: ' ) . $comment->author . "\n" .
          ( $comment->url ? $app->translate ( 'Web Site: ' ) . $comment->url . "\n\n" : "\n" ) .
          $app->translate ( 'Comment: ' ) . "\n" . $comment->text . "\n\n--\n\n" .
          $app->translate ( 'Unsubscribe From This Entry' ) . "\n" .
          $not_uri . "__mode=unsub&sub_id=$key:$sub_add:$sub_key\n\n" .
          $app->translate ( 'Block All Subscriptions From This Site' ) . "\n" .
          $not_uri . "__mode=sub&email=$sub_add&blog_id=$blog_id\n\n" .
          $app->translate ( 'Delivered to you by ' ) . "MT-Notifier v$VERSION\n" .
          "http://www.cxliv.org/jayseae/notifier/\n";
        MT::Mail->send( \%head, $body );
      }
    }
  }
}

sub purgedata {
  my $app = shift;
  my $auth = $app->{author};
  my $q = $app->{query};
  my %param = (
    app_version => $VERSION,
    mt_script_url => $app->{cfg}->CGIPath . 'mt.cgi',
    what => $q->param ( 'what' )
  );
  my %stats = (
    cannotsave => 0,
    datapurged => 1
  );

  my @auth = ();
  require MT::Permission;
  my @perms = MT::Permission->load ( { author_id => $auth->id } );
  for my $perms ( @perms ) {
    next unless $perms->role_mask;
    push @auth, $perms->blog_id;
  }

  require MT::PluginData;
  foreach my $data ( MT::PluginData->load ( { plugin => 'Notifier' } ) ) {
    my ( $sub_blog, $sub_entry ) = split ( /:/, $data->key );
    foreach my $sub_auth ( @auth ) {
      next unless ( ( $sub_blog eq $sub_auth ) || ( $sub_blog eq '0' ) );
      if ( $param{what} eq 'all' ) {
        $data->remove or $stats{cannotsave} = 1;
      } elsif ( $param{what} eq 'allcfg' && !$sub_entry ) {
        my $subs = $data->data->{'subscriptions'};
        if ( $subs ) {
          my $info = {
            senderaddress => '',
            subscriptions => $subs
          };
          $data->data ( $info );
          $data->save or $stats{cannotsave} = 1;
        } else {
          $data->remove or $stats{cannotsave} = 1;
        }
      } elsif ( $param{what} eq 'allopt' && !$sub_entry ) {
        my $send = $data->data->{'senderaddress'};
        if ( $send ) {
          my $info = {
            senderaddress => $send,
            subscriptions => ''
          };
          $data->data ( $info );
          $data->save or $stats{cannotsave} = 1;
        } else {
          $data->remove or $stats{cannotsave} = 1;
        }
      } elsif ( $param{what} eq 'allsub' && $sub_entry ) {
        $data->remove or $stats{cannotsave} = 1;
      } elsif ( $param{what} eq 'entinv' ) {
        my $invalid = 0;
        require MT::Blog;
        my $blog = MT::Blog->load ( $sub_blog ) or $invalid = 1;
        if ( $invalid ) {
          $data->remove or $stats{cannotsave} = 1;
        } elsif ( $sub_entry ) {
          require MT::Entry;
          my $entry = MT::Entry->load ( $sub_entry ) or $invalid = 1;
          if ( $invalid ) {
            $data->remove or $stats{cannotsave} = 1;
          }
        }
      } elsif ( $param{what} eq 'entopt' && $sub_entry ) {
        my @subs = ();
        foreach my $sub ( split ( /;/, $data->data->{'subscriptions'} ) ) {
          my ( $sub_add, $sub_key ) = split ( /:/, $sub );
          my $opt = MT::PluginData->load ( { plugin => 'Notifier', key => $sub_blog . ":0" } );
          foreach my $opt ( split ( /;/, $opt->data->{'subscriptions'} ) ) {
            my ( $opt_add, $opt_key ) = split ( /:/, $opt );
            push @subs, $sub unless ( $sub_add eq $opt_add );
          }
        }
        if ( scalar @subs ) {
          my $subs = join ( ';', @subs );
          my $info = {
            subscriptions => $subs
          };
          $data->data ( $info );
          $data->save or $stats{cannotsave} = 1;
        } else {
          $data->remove or $stats{cannotsave} = 1;
        }
      }
    }
  }

  $stats{datapurged} = 0 if $stats{cannotsave};

  $param{author_id} = $auth->id;
  $param{author_name} = $auth->name;
  $param{blog_loop} = _loop_blogs ();
  $param{entry_loop} = _loop_entries ();
  $param{module_loop} = _loop_modules ();
  $param{cfg_loop} = _loop_subs ( 'cfgs', $auth );
  $param{opt_loop} = _loop_subs ( 'opts', $auth );
  $param{sub_loop} = _loop_subs ( 'subs', $auth );
  $param{top_blog_loop} = _loop_top_blogs ( $auth );
  $param{notifier_message} = _parse_status_message ( \%param, \%stats );
  $app->build_page( 'notifier.tmpl', \%param );
}

sub subscribe {
  my ( $app, $sub_mode ) = @_;
  my $q = $app->{query};
  my %param = (
    app_version => $VERSION,
    mt_script_url => $app->{cfg}->CGIPath . 'mt.cgi'
  );
  my %stats = (
    alreadyout => 0,
    alreadysub => 0,
    cannotsave => 0,
    isoptedout => 0,
    noemailadd => 0,
    notanentry => 0,
    notablogid => 0,
    outremoved => 0,
    subremoved => 0,
    subscribed => 0,
    unknownout => 0,
    unknownsub => 0
  );

  $param{sub_mode} = $q->param ( '__mode' ) if ( $q->param ( '__mode' ) );
  $param{sub_mode} = $sub_mode if ( $sub_mode );

  if ( $q->param ( 'cfg_id' ) ) {
    ( $param{blog_id}, $param{entry_id}, $param{email}, $param{sub_key} ) = split ( /:/, $q->param ( 'cfg_id' ) );
  } elsif ( $q->param ( 'opt_id' ) ) {
    ( $param{blog_id}, $param{entry_id}, $param{email}, $param{sub_key} ) = split ( /:/, $q->param ( 'opt_id' ) );
  } elsif ( $q->param ( 'sub_id' ) ) {
    ( $param{blog_id}, $param{entry_id}, $param{email}, $param{sub_key} ) = split ( /:/, $q->param ( 'sub_id' ) );
  } elsif ( $app->{sub_entry_id} ) {
    $param{entry_id} = $app->{sub_entry_id};
    $param{email} = $app->{sub_email};
  } else {
    $param{blog_id} = $q->param ( 'blog_id' );
    $param{entry_id} = $q->param ( 'entry_id' );
    $param{email} = $q->param ( 'email' );
  }

  my $key = '';
  if ( $param{entry_id} ) {
    require MT::Entry;
    my $entry = MT::Entry->load ( $param{entry_id} ) or $stats{notanentry} = 1;
    if ( $stats{notanentry} ) {
      undef $key;
    } else {
      $param{entry_blog} = $entry->blog_id;
      $param{entry_title} = $entry->title;
      $param{redirect_title} = $entry->title;
      $param{redirect_url} = $entry->permalink;
      $key = $param{entry_blog} . ':' . $param{entry_id};
    }
  } elsif ( defined $param{blog_id} ) {
    if ( $param{blog_id} eq '0' ) {
      $param{blog_name} = '* All Blogs *';
      $key = '0:0';
    } else {
      require MT::Blog;
      my $blog = MT::Blog->load ( $param{blog_id} ) or $stats{notablogid} = 1;
      if ( $stats{notablogid} ) {
        undef $key;
      } else {
        $param{blog_name} = $blog->name;
        $param{redirect_title} = $blog->name;
        $param{redirect_url} = $blog->site_url;
        $key = $param{blog_id} . ':0';
      }
    }
  }

  if ( !$stats{notablogid} && !$stats{notanentry} ) {
    if ( $param{email}  ) {
      require MT::Util;
      if ( my $fixed = MT::Util::is_valid_email( $param{email} ) ) {
        $param{email} = $fixed;
      } else {
        $stats{emailerror} = 1;
        undef $key;
      }
    } else {
      if ( $param{sub_mode} ne 'uncfg' ) {
        $stats{noemailadd} = 1;
        undef $key;
      }
    }
  }

  if ( defined $key ) {
    require MT::PluginData;
    my @subs = ();
    my $send = '';
    my $data = MT::PluginData->load ( { plugin => 'Notifier', key => $key } );
    if ( $data ) {
      $send = $data->data->{'senderaddress'};
      if ( $param{sub_mode} eq 'uncfg' ) {
        my ( $sub_add, $sub_key ) = split ( /:/, $send );
        if ( $sub_add eq $param{email} ) {
          $stats{cfgremoved} = 1 if ( $sub_key eq $param{sub_key} );
          $stats{invalidkey} = 1 if ( $sub_key ne $param{sub_key} );
        } else {
          $stats{unknowncfg} = 1;
        }
      }
      my $subs = $data->data->{'subscriptions'};
      foreach my $sub ( split ( /;/, $subs ) ) {
        my ( $sub_add, $sub_key ) = split ( /:/, $sub );
        if ( $sub_add eq $param{email} && $param{sub_mode} ne 'cfg' && $param{sub_mode} ne 'uncfg' ) {
          $stats{alreadysub} = 1 if ( $param{sub_mode} eq 'sub' );
          $stats{subremoved} = 1 if ( $param{sub_mode} eq 'unsub' && $sub_key eq $param{sub_key} );
          $stats{invalidkey} = 1 if ( $param{sub_mode} eq 'unsub' && $sub_key ne $param{sub_key} );
        } else {
          push @subs, $sub;
        }
      }
    } else {
      $data = MT::PluginData->new;
      $data->key ( $key );
      $data->plugin ( 'Notifier' );
    }

    if ( $param{sub_mode} eq 'api' || $param{sub_mode} eq 'cfg' || $param{sub_mode} eq 'sub' ) {
      if ( $stats{alreadysub} ) {
        if ( defined ( $param{blog_id} ) ) {
          $stats{alreadyout} = 1;
          $stats{alreadysub} = 0;
        }
      } else {
        srand ( time | $$ );
        my $salt = sprintf (
          "%c%c",
          int ( rand ( 26 ) ) + 0x41 + ( int ( rand ( 2 ) ) * 0x20 ),
          int ( rand ( 26 ) ) + 0x41 + ( int ( rand ( 2 ) ) * 0x20 )
        );
        if ( $param{sub_mode} eq 'api' || $param{sub_mode} eq 'sub' ) {
          push @subs, $param{email} . ':' . crypt ( $param{email}, $salt );
        } elsif ( $param{sub_mode} eq 'cfg' ) {
          $send = $param{email} . ':' . crypt ( $param{email}, $salt );
        }
        my $subs = join ( ';', @subs );
        my $info;
        $info = {
          subscriptions => $subs
        } if $param{entry_id};
        $info = {
          senderaddress => $send,
          subscriptions => $subs
        } unless $param{entry_id};
        $data->data ( $info );
        $data->save or $stats{cannotsave} = 1;
        $stats{subscribed} = 1 unless $stats{cannotsave};
        $stats{configdone} = 1 if ( $param{sub_mode} eq 'cfg' && $stats{subscribed} );
        $stats{subscribed} = 0 if ( $param{sub_mode} eq 'cfg' && $stats{subscribed} );
      }
    } elsif ( $param{sub_mode} eq 'unsub' ) {
      if ( $stats{subremoved} ) {
        if ( scalar @subs ) {
          my $subs = join ( ';', @subs );
          my $info = {
            senderaddress => '',
            subscriptions => $subs
          };
          $data->data ( $info );
          $data->save or $stats{cannotsave} = 1;
        } else {
          $data->remove or $stats{cannotsave} = 1;
        }
        $stats{subremoved} = 0 if $stats{cannotsave};
      } elsif ( !$stats{invalidkey} ) {
        if ( $param{entry_id} ) {
          $stats{unknownout} = 0;
          $stats{unknownsub} = 1;
        } else {
          $stats{unknownout} = 1;
          $stats{unknownsub} = 0;
        }
      }
    } elsif ( $param{sub_mode} eq 'uncfg' ) {
      if ( $stats{cfgremoved} ) {
        if ( scalar @subs ) {
          my $subs = join ( ';', @subs );
          my $info = {
            subscriptions => $subs
          };
          $data->data ( $info );
          $data->save or $stats{cannotsave} = 1;
        } else {
          $data->remove or $stats{cannotsave} = 1;
        }
        $stats{cfgremoved} = 0 if $stats{cannotsave};
      }
    }
  }

  if ( $stats{subscribed} ) {
    if ( defined ( $param{blog_id} ) ) {
      $stats{isoptedout} = 1;
      $stats{subscribed} = 0;
    }
  } elsif ( $stats{subremoved} ) {
    if ( !$param{entry_id} ) {
      $stats{outremoved} = 1;
      $stats{subremoved} = 0;
    }
  }

  if (my $auth = $app->{author}) {
    $param{author_id} = $auth->id;
    $param{author_name} = $auth->name;
    $param{blog_loop} = _loop_blogs ();
    $param{entry_loop} = _loop_entries ();
    $param{module_loop} = _loop_modules ();
    $param{cfg_loop} = _loop_subs ( 'cfgs', $auth );
    $param{opt_loop} = _loop_subs ( 'opts', $auth );
    $param{sub_loop} = _loop_subs ( 'subs', $auth );
    $param{top_blog_loop} = _loop_top_blogs ( $auth );
  }

  $param{notifier_message} = _parse_status_message ( \%param, \%stats );
  return $param{email} if ( $param{sub_mode} eq 'api' );
  $app->build_page( 'notifier.tmpl', \%param );
}

sub _get_sender_address {
  my ( $blog_id, $entry_id ) = @_;
  my $data = '';
  my $sender = '';
  my $sender_key = '';

  require MT::PluginData;
  $data = MT::PluginData->load ( { plugin => 'Notifier', key => $blog_id . ':0' } );
  $sender = $data->data->{'senderaddress'} if $data;
  ( $sender, $sender_key ) = split ( /:/, $sender );

  if ( !$sender ) {
    $data = MT::PluginData->load ( { plugin => 'Notifier', key => '0:0' } );
    $sender = $data->data->{'senderaddress'} if $data;
    ( $sender, $sender_key ) = split ( /:/, $sender );
  }

  if ( !$sender ) {
    require MT::Entry;
    $data = MT::Entry->load ( $entry_id );
    require MT::Author;
    $data = MT::Author->load ( $data->author_id ) if $data;
    $sender = $data->email if $data;
  }

  $sender = 'user@domain.com' if ( !$sender );
  $sender;
}

sub _loop_blogs {
  my @blogs = ();

  require MT::Blog;
  foreach my $blog ( MT::Blog->load ) {
    push @blogs, {
      blog_id => $blog->id,
      blog_name => $blog->name
    };
  }

  @blogs = sort {
    $a->{blog_id}   <=> $b->{blog_id}
  } @blogs;
  my $blogs = \@blogs;
  $blogs;
}

sub _loop_entries {
  my @entries = ();

  require MT::Entry;
  foreach my $entry ( MT::Entry->load ) {
    push @entries, {
      entry_id => $entry->id,
      entry_title => $entry->title
    };
  }

  @entries = sort {
    $a->{entry_title} cmp $b->{entry_title} ||
    $a->{entry_id}    <=> $b->{entry_id}
  } @entries;
  my $entries = \@entries;
  $entries;
}

sub _loop_modules {
  my @modules = ();

  my $status = _update_module ( 'mtappc', 'check' );
  my $backup = _update_module ( 'mtappc', 'checkbu' );
  push @modules, {
    module_id => 'mtappc',
    module_title => 'Movable Type',
    module_error => $status == 2 ? 1 : 0,
    module_ready => $status == 1 ? 1 : 0,
    module_saved => $backup == 12 ? 1 : 0
  };

  $status = _update_module ( 'mtbl162', 1 );
  if ( $status != 3 ) {
    $backup = _update_module ( 'mtbl162', 'checkbu' );
    push @modules, {
      module_id => 'mtbl162',
      module_title => 'MT-Blacklist v1.62 (or greater)',
      module_error => $status == 2 ? 1 : 0,
      module_ready => $status == 1 ? 1 : 0,
      module_saved => $backup == 12 ? 1 : 0
    };
  } else {
    $status = _update_module ( 'mtbl161', 1 );
    if ( $status != 3 ) {
      $backup = _update_module ( 'mtbl162', 'checkbu' );
      push @modules, {
        module_id => 'mtbl161',
        module_title => 'MT-Blacklist v1.61 (or earlier)',
        module_error => $status == 2 ? 1 : 0,
        module_ready => $status == 1 ? 1 : 0,
        module_saved => $backup == 12 ? 1 : 0
      };
    }
  }

  my $modules = \@modules;
  $modules;
}

sub _loop_subs {
  my ( $load, $auth ) = @_;
  my @auth = ();
  my @subs = ();
  my $zero = 0;

  require MT::Permission;
  my @perms = MT::Permission->load ( { author_id => $auth->id } );
  for my $perms ( @perms ) {
    next unless $perms->role_mask;
    push @auth, $perms->blog_id;
  }

  require MT::PluginData;
  foreach my $sub ( MT::PluginData->load ( { plugin => 'Notifier' }  ) ) {
    my ( $sub_blog, $sub_entry ) = split ( /:/, $sub->key );
    foreach my $sub_auth ( @auth ) {
      next unless ( ( $sub_blog eq $sub_auth ) || ( $sub_blog eq '0' ) );
      if ( $load eq 'subs' && $sub_entry ) {
        my $entrytitle;
        require MT::Entry;
        my $entry = MT::Entry->load ( $sub_entry );
        $entrytitle = $entry->title if $entry;
        $entrytitle = '&lt;Entry Not Found&gt;' unless $entry;
        foreach my $add ( split ( /;/, $sub->data->{'subscriptions'} ) ) {
          my ( $sub_add, $sub_key ) = split ( /:/, $add );
          push @subs, {
            sub_blog => $sub_blog,
            sub_entry => $sub_entry,
            sub_address => $sub_add,
            sub_key => $sub_key,
            sub_title => $entrytitle
          };
        }
      } elsif ( $sub_entry eq '0' && !$zero ) {
        if ( $load eq 'cfgs' || $load eq 'opts' ) {
          $zero = 1 if ( $sub_blog eq '0' && $load eq 'cfgs' );
          my $blog_name;
          my $type_data;
          require MT::Blog;
          my $blog = MT::Blog->load ( $sub_blog );
          $blog_name = $blog->name if $blog;
          $blog_name = '* Blog Not Found *' unless $blog;
          $blog_name = '* All Blogs *' if ( $sub_blog eq '0' );
          $type_data = $sub->data->{'senderaddress'} if ( $load eq 'cfgs' );
          $type_data = $sub->data->{'subscriptions'} if ( $load eq 'opts' );
          foreach my $add ( split ( /;/, $type_data ) ) {
            my ( $sub_add, $sub_key ) = split ( /:/, $add );
            push @subs, {
              sub_blog => $sub_blog,
              sub_entry => 0,
              sub_address => $sub_add,
              sub_key => $sub_key,
              sub_title => $blog_name
            };
          }
        }
      }
    }
  }

  if ( $load eq 'cfgs' ) {
    @subs = sort {
      $a->{sub_title}    cmp $b->{sub_title}
    } @subs;
  } elsif ( $load eq 'opts' ) {
    @subs = sort {
      $a->{sub_address} cmp $b->{sub_address} ||
      $a->{sub_title}   cmp $b->{sub_title}
    } @subs;
  } elsif ( $load eq 'subs' ) {
    @subs = sort {
      $a->{sub_address} cmp $b->{sub_address} ||
      $a->{sub_title}   cmp $b->{sub_title} ||
      $a->{sub_entry}   <=> $b->{sub_entry}
    } @subs;
  }

  my $subs = \@subs;
  $subs;
}

sub _loop_top_blogs {
  my $auth = shift;
  my @data = ();

  require MT::Permission;
  my @perms = MT::Permission->load ( { author_id => $auth->id } );
  for my $perms ( @perms ) {
    next unless $perms->role_mask;
    my $blog = MT::Blog->load ( $perms->blog_id );
    push @data, { top_blog_id => $blog->id,
                  top_blog_name => $blog->name };
  }

  @data = sort { $a->{top_blog_name} cmp $b->{top_blog_name} } @data;
  my $data = \@data;
  $data;
}

sub _parse_status_message {
  my ( $param, $stats ) = @_;

  # success - backup/conversion/installation/purge
  return 'Your backup request processed successfully.' if $stats->{backupdone};
  return 'Your conversion request processed successfully.' if $stats->{conversion};
  return 'Your purge request processed successfully.' if $stats->{datapurged};
  return 'Your removal request processed successfully.' if $stats->{removedone};
  return 'Your restore request processed successfully.' if $stats->{rescuedone};
  return 'Your installation request processed successfully.' if $stats->{updatedone};

  # success - subscriptions
  return 'Address ' . $param->{email} . ' removed as default "from" address from blog #' . $param->{blog_id} . ' (' . $param->{blog_name} . ').' if $stats->{cfgremoved};
  return 'Address ' . $param->{email} . ' entered as the default "from" address for blog #' . $param->{blog_id} . ' (' . $param->{blog_name} . ').' if $stats->{configdone};
  return 'Address ' . $param->{email} . ' added to opt-out list for blog #' . $param->{blog_id} . ' (' . $param->{blog_name} . ').' if $stats->{isoptedout};
  return 'Address ' . $param->{email} . ' removed from opt-out list for blog #' . $param->{blog_id} . ' (' . $param->{blog_name} . ').' if $stats->{outremoved};
  return 'Address ' . $param->{email} . ' removed from subscription to entry #' . $param->{entry_id} . ' (' . $param->{entry_title} . ').' if $stats->{subremoved};
  return 'Address ' . $param->{email} . ' subscribed to entry #' . $param->{entry_id} . ' (' . $param->{entry_title} . ').' if $stats->{subscribed};

  # failure - backup/conversion/installation/purge
  return 'Your backup request did not complete successfully.  If you have already saved a backup of this module, you need to delete that backup copy before saving another.' if $stats->{backupfail};
  return 'Your removal request did not complete successfully.  Already removed?' if $stats->{removefail};
  return 'Your restore request did not complete successfully.  If you do not have a backup copy of the module, you cannot restore it.  Please create a backup first, then you will be able to restore as needed.' if $stats->{rescuefail};
  return 'Your installation request did not complete successfully.  Already installed?' if $stats->{updatefail};

  # failure - subscriptions
  return 'Address ' . $param->{email} . ' has already opted out of blog #' . $param->{blog_id} . ' (' . $param->{blog_name} . ').' if $stats->{alreadyout};
  return 'Address ' . $param->{email} . ' is already subscribed to entry #' . $param->{entry_id} . ' (' . $param->{entry_title} . ').' if $stats->{alreadysub};
  return 'Address ' . $param->{email} . ' is not a valid email address.  Please correct the address and try again.' if $stats->{emailerror};
  return 'Your request specifies an invalid record key.  Please correct your data and submit your request again.' if $stats->{invalidkey};
  return 'Email address is required for subscription functions.  Specify an email address to try again.' if $stats->{noemailadd};
  return 'Blog #' . $param->{blog_id} . ' does not exist on this system.  Request not processed.' if $stats->{notablogid};
  return 'Entry #' . $param->{entry_id} . ' does not exist on this system.  Request not processed.' if $stats->{notanentry};
  return 'Address ' . $param->{email} . ' was not found as a default "from" address on blog #' . $param->{blog_id} . ' (' . $param->{blog_name} . ').' if $stats->{unknowncfg};
  return 'Address ' . $param->{email} . ' was not found on the opt-out list for blog #' . $param->{blog_id} . ' (' . $param->{blog_name} . ').' if $stats->{unknownout};
  return 'Address ' . $param->{email} . ' is not subscribed to entry #' . $param->{entry_id} . ' (' . $param->{entry_title} . ').' if $stats->{unknownsub};

  # uh-oh
  return 'Error encountered while saving MT::PluginData.  Request not processed.' if $stats->{cannotsave};
}

sub _update_module {
  my ( $module, $method, $count, $error, $fixed ) = @_;
  my @in = ();
  my @out = ();

  my $root = "$ENV{SCRIPT_FILENAME}~";
  $root =~ s/\/([^\/]|\n)*\~//;

  my %paths = (
    jayallen => $root . '/extlib/jayallen',
    mt       => $root . '/lib/MT/App'
  );

  my %files = (
    mtappc => $paths{mt} . '/Comments.pm',
    mtbl161 => $paths{jayallen} . '/Blacklist.pm',
    mtbl162 => $paths{jayallen} . '/MTBlPost.pm'
  );

  if ( -f $files{$module} ) {
    open ( ONE, $files{$module} );
    @in = <ONE>;
    close ( ONE );

    if ( $method eq 'check' || $method eq 'mod' || $method eq 'unmod' ) {
      foreach my $line ( @in ) {
        if ( $line =~ m|}| ) {
          if ( $in[$count - 2] =~ m|MT::Mail->send| && $in[$count - 1] =~ m|}| && $in[$count + 1] =~ m|\$app->redirect| ) {
            unless ( $error ) {
              push @out, '        require jayseae::notifier;' . "\r\n";
              push @out, '        &jayseae::notifier::notify ( $app, $blog, $entry, $comment );' . "\r\n";
              push @out, $line;
              $fixed = 1;
            }
          } else {
            push @out, $line;
          }
        } elsif ( $line =~ m|jayseae::notifier| ) {
          $error = 1;
          $fixed = 0;
        } else {
          push @out, $line;
        }

        $count++;
      }

      if ( $fixed ) {
        if ( $method eq 'mod' ) {
          _write_module ( $files{$module}, @out );
        }
        return 0;                                         # not installed yet, or mod updated successfully
      } elsif ( $error ) {
        if ( $method eq 'unmod' ) {
          _write_module ( $files{$module}, @out );
        }
        return 1;                                         # already installed, or mod removed successfully
      } else {
        return 2;                                         # unable to install, code pattern does not match
      }
    } else {
      require MT::PluginData;
      my $data = MT::PluginData->load ( { plugin => 'Notifier', key => $module } );
      if  ( $method eq 'addback' ) {
        return 4 if $data;                                # data already exists - cannot create new backup
        $data = MT::PluginData->new;
        $data->key ( $module );
        $data->plugin ( 'Notifier' );
        my $code = join ( ':::dbd:::', @in );
        my $info = {
          module_backup => $code
        };
        $data->data ( $info );
        $data->save or return 5;                          # error during save, unable to create new backup
        return 6;                                         # successfully saved a backup of the module code
      } elsif  ( $method eq 'delback' ) {
        return 7 unless $data;                            # no backup data, unable to remove backup record
        $data->remove or return 8;                        # error during remove, unable to remove a backup
        return 9;                                         # successfully removed the backup of module code
      } elsif  ( $method eq 'resback' ) {
        return 10 unless $data;                           # no backup data, cannot restore from the backup
        my $code = $data->data->{'module_backup'};
        @out = split ( ':::dbd:::', $code );
        _write_module ( $files{$module}, @out );
        return 11;                                        # successfully rescued the backup of module code
      } else {
        return 12 if $data;                               # this module is backed up (mode: checkbu) in db
        return 0;                                         # no back up for this module found in plugindata
      }
    }
  } else {
    return 3;                                             # module specified on command line doesn't exist
  }
}

sub _write_module {
  my ( $module, @out ) = @_;

  open ( TWO, ">$module" ) || die "Write Failed ( $module ): $!\n";

  foreach my $line ( @out ) {
    print TWO $line;
  }

  close ( TWO );
}

1;
