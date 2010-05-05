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
package Notifier;

use base qw(MT::App);
use strict;

use MT;

sub init_app { 1; }

# subscription functions

sub create_subscription {
    require MT::Blog;
    require MT::Util;
    require Notifier::Data;
    require Notifier::Util;
    my $app = MT->app;
    my $plugin = MT->component('Notifier');
    my ($email, $record, $blog_id, $category_id, $entry_id, $bulk) = @_;
    my $blog;
    if (my $fixed = MT::Util::is_valid_email($email)) {
        $email = $fixed;
    } else {
        return 1;
    }
    return unless ($record eq Notifier::Data::OPT_OUT() || $record eq Notifier::Data::SUBSCRIBE());
    if ($entry_id) {
        require MT::Entry;
        my $entry = MT::Entry->load($entry_id);
        return 2 unless ((ref $entry) && $entry->isa('MT::Entry'));
        $blog = MT::Blog->load($entry->blog_id);
        return 2 unless ((ref $blog) && $blog->isa('MT::Blog'));
        $blog_id = $blog->id;
        $category_id = 0;
    } elsif ($category_id) {
        require MT::Category;
        my $category = MT::Category->load($category_id);
        return 2 unless ((ref $category) && $category->isa('MT::Category'));
        $blog = MT::Blog->load($category->blog_id);
        return 2 unless ((ref $blog) && $blog->isa('MT::Blog'));
        $blog_id = $blog->id;
        $entry_id = 0;
    } elsif ($blog_id) {
        $blog = MT::Blog->load($blog_id);
        return 2 unless ((ref $blog) && $blog->isa('MT::Blog'));
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
        $data->cipher(Notifier::Util::produce_cipher(
            'a'.$email.'b'.$blog_id.'c'.$category_id.'d'.$entry_id
        ));
        my $system_confirm = $plugin->get_config_value('system_confirm');
        my $blog_confirm = $plugin->get_config_value('blog_confirm', 'blog:'.$blog->id);
        if ($system_confirm && $blog_confirm) {
            $data->status(Notifier::Data::PENDING()) unless ($bulk);
            $data->status(Notifier::Data::RUNNING()) if ($bulk);
        } else {
            $data->status(Notifier::Data::RUNNING());
        }
        $data->ip($app->remote_ip);
        $data->type(0); # 5.0?
        $data->save;
        data_confirmation($data) if ($data->status == Notifier::Data::PENDING());
    }
    return 0;
}

sub data_confirmation {
    my ($data) = @_;
    require MT::Mail;
    require MT::Util;
    require Notifier::Data;
    require Notifier::Util;
    my ($category, $entry, $type, $author);
    my $plugin = MT->component('Notifier');
    if ($data->entry_id) {
        require MT::Entry;
        $entry = MT::Entry->load($data->entry_id);
        return unless ((ref $entry) && $entry->isa('MT::Entry'));
        $type = $plugin->translate('Entry');
        $author = ($entry->author) ? $entry->author : '';
    } elsif ($data->category_id) {
        require MT::Category;
        $category = MT::Category->load($data->category_id);
        return unless ((ref $category) && $category->isa('MT::Category'));
        $type = $plugin->translate('Category');
    } else {
        $type = $plugin->translate('Blog');
    }
    my $sender_address = Notifier::Util::load_sender_address($data, $author);
    return unless ($sender_address);
    my $blog = Notifier::Util::load_blog($data);
    return unless ((ref $blog) && $blog->isa('MT::Blog'));
    my $record_description = ($data->record == Notifier::Data::SUBSCRIBE()) ?
        $plugin->translate('subscribe to') :
        $plugin->translate('opt-out of');
    my %head = (
        'From' => $sender_address,
        'To' => $data->email,
    );
    my %param = (
        'notifier_record_cipher' => $data->cipher,
        'notifier_record_description' => $record_description,
    );
    if ($entry) {
        $param{'notifier_record_link'} = $entry->permalink;
        $param{'notifier_record_text'} = MT::Util::remove_html($entry->title);
    } elsif ($category) {
        my $link = $blog->archive_url;
        $link .= '/' unless ($link =~ m/\/$/);
        $link .= MT::Util::archive_file_for ('',  $blog, $type, $category);
        $param{'notifier_record_link'} = $link;
        $param{'notifier_record_text'} = MT::Util::remove_html($category->label);
    } elsif ($blog) {
        $param{'notifier_record_link'} = $blog->site_url;
        $param{'notifier_record_text'} = MT::Util::remove_html($blog->name);
    }
    # load confirmation subject template
    my %parms = (
        'identifier'  => 'notifier_confirmation_subject',
        'blog_id'     => $data->blog_id,
        'category_id' => $data->category_id,
        'entry_id'    => $data->entry_id,
        'text'        => 'Confirmation Subject',
        'type'        => 'email',
    );
    my ($body, $tmpl);
    $tmpl = Notifier::Util->load_notifier_tmpl(\%parms);
    if ($tmpl) {
        $tmpl->param(\%param);
        my $html = $tmpl->output();
        $html = $tmpl->errstr unless (defined $tmpl);
        $head{'Subject'} = $html;
    }
    # load confirmation body template
    $parms{'identifier'} = 'notifier_confirmation_body';
    $parms{'text'} = 'Confirmation Body';
    $tmpl = Notifier::Util->load_notifier_tmpl(\%parms);
    if ($tmpl) {
        $tmpl->param(\%param);
        my $html = $tmpl->output();
        $html = $tmpl->errstr unless (defined $tmpl);
        $body = $html;
    }
    my $mail = MT::Mail->send(\%head, $body);
    unless ($mail) {
        my $app = MT->app;
        $app->log($plugin->translate(
            'Error sending confirmation message to [_1], error [_2]',
            $head{'To'},
            MT::Mail->errstr
        ));
    }
}

sub entry_notifications {
    my $entry_id = shift;
    require MT::Category;
    require MT::Entry;
    require MT::Placement;
    require Notifier::Data;
    my $entry = MT::Entry->load($entry_id);
    return unless ((ref $entry) && $entry->isa('MT::Entry'));
    my %terms = (
        'blog_id' => $entry->blog_id,
        'category_id' => 0,
        'entry_id' => 0,
        'record' => Notifier::Data::SUBSCRIBE(),
        'status' => Notifier::Data::RUNNING(),
    );
    my @work_subs = Notifier::Data->load(\%terms);
    my @places = MT::Placement->load({
        blog_id => $entry->blog_id,
        entry_id => $entry->id,
    });
    foreach my $place (@places) {
        my $cat = MT::Category->load($place->category_id);
        next unless ((ref $cat) && $cat->isa('MT::Category'));
        $terms{'category_id'} = $cat->id;
        my @category_subs = Notifier::Data->load(\%terms);
        foreach (@category_subs) {
            push @work_subs, $_;
        }
    }
    return unless (scalar @work_subs);
    notify_users($entry, \@work_subs);
}

sub notify_users {
    my ($obj, $work_subs) = @_;
    require MT::Blog;
    require MT::Category;
    require MT::Entry;
    require MT::Placement;
    require MT::Util;
    require Notifier::Data;
    require Notifier::History;
    require Notifier::Util;
    my ($entry, $entry_id, $comment, $comment_id);
    my ($class, $type);
    my $plugin = MT->component('Notifier');
    if ((ref $obj) && $obj->isa('MT::Comment')) {
        $entry = MT::Entry->load($obj->entry_id);
        return unless ((ref $entry) && $entry->isa('MT::Entry'));
        $class = 'comment';
        $comment = $obj;
        $comment_id = $comment->id;
        $entry_id = 0;
        $type = $plugin->translate('Comment');
    }
    if ((ref $obj) && $obj->isa('MT::Entry')) {
        $class = 'entry';
        $comment_id = 0;
        $entry = $obj;
        $entry_id = $entry->id;
        $type = $plugin->translate('Entry');
    }
    my $blog = MT::Blog->load($obj->blog_id);
    return unless ((ref $blog) && $blog->isa('MT::Blog'));
    my %terms = (
        'blog_id' => $blog->id,
        'category_id' => 0,
        'entry_id' => 0,
        'record' => Notifier::Data::OPT_OUT(),
        'status' => Notifier::Data::RUNNING(),
    );
    my @work_opts = Notifier::Data->load(\%terms);
    my @places = MT::Placement->load({
        blog_id => $entry->blog_id,
        entry_id => $entry->id,
    });
    foreach my $place (@places) {
        my $cat = MT::Category->load($place->category_id);
        next unless ((ref $cat) && $cat->isa('MT::Category'));
        $terms{'category_id'} = $cat->id;
        my @category_opts = Notifier::Data->load(\%terms);
        foreach (@category_opts) {
            push @work_opts, $_;
        }
    }
    my %opts = map { $_->email => 1 } @work_opts;
    my @subs = grep { !exists $opts{$_->email} } @$work_subs;
    return unless (scalar @subs);
    my $sender_address = Notifier::Util::load_sender_address($obj, $entry->author);
    return unless ($sender_address);
    my %head = (
        'From' => $sender_address,
    );
    # load notification subject template
    my %parms = (
        'identifier'  => 'notifier_'.$class.'_notification_subject',
        'blog_id'     => $blog->id,
        'category_id' => $entry ? $entry->category : 0,
        'entry_id'    => $comment ? $comment->entry_id : $entry->id,
        'comment_id'  => $comment ? $comment->id : 0,
        'text'        => $type.' Notification Subject',
        'type'        => 'email',
    );
    my %param;
    my $tmpl = Notifier::Util->load_notifier_tmpl(\%parms);
    if ($tmpl) {
        $tmpl->param(\%param);
        my $html = $tmpl->output();
        $html = $tmpl->errstr unless (defined $tmpl);
        $head{'Subject'} = $html;
    }
    # check bypass flags
    my $blog_bypass = $plugin->get_config_value('blog_bypass', 'blog:'.$blog->id);
    my $system_bypass = $plugin->get_config_value('system_bypass');
    # check queued flags
    my $blog_queued = $plugin->get_config_value('blog_queued', 'blog:'.$blog->id);
    my $system_queued = $plugin->get_config_value('system_queued');
    my %sent;
    foreach my $sub (@subs) {
        next if ($comment && $comment->email eq $sub->email);
        next if ($sent{$sub});
        my %terms;
        $terms{'data_id'} = $sub->id;
        $terms{'comment_id'} = $comment_id;
        $terms{'entry_id'} = $entry_id;
        my $history = Notifier::History->load(\%terms);
        if ($history) {
            $sent{$sub} = 1;
            next;
        }
        if ($system_bypass && $blog_bypass) {
            if ($obj->isa('MT::Entry')) {
                if ($sub->created_on ge $entry->authored_on) {
                    # create history for entries written before user subscribed
                    Notifier::History->create(\%terms);
                    $sent{$sub} = 1;
                    next;
                }
            }
        }
        $head{'To'} = $sub->email;
        $param{'notifier_record_cipher'} = $sub->cipher;
        # load notification body template
        my $body;
        $parms{'identifier'} = 'notifier_'.$class.'_notification_body';
        $parms{'text'} = $type.' Notification Body';
        $tmpl = Notifier::Util->load_notifier_tmpl(\%parms);
        if ($tmpl) {
            $tmpl->param(\%param);
            my $html = $tmpl->output();
            $html = $tmpl->errstr unless (defined $tmpl);
            $body = $html;
        }
        if ($system_queued && $blog_queued) {
            require Notifier::Queue;
            Notifier::Queue->create(\%head, $body);
        } else {
            require MT::Mail;
            MT::Mail->send(\%head, $body);
        }
        Notifier::History->create(\%terms);
        $sent{$sub} = 1;
    }
}

1;