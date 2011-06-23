# ===========================================================================
# A Movable Type plugin with subscription options for your installation
# Copyright 2003-2011 Everitz Consulting <everitz.com>.
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

# unused, keeping for reference

sub load_config {
    my $plugin = shift;
    my ($args, $scope) = @_;

    $plugin->SUPER::load_config(@_);

    my $app = MT->instance;
    if ($app->isa('MT::App')) {
        $args->{static_uri} = $app->static_path;
        if ($scope =~ /blog:(\d+)/) {
            my $blog_id = $1;
            $args->{blog_id} = $blog_id;
        }
    }
}

# subscription functions

sub create_subscription {
    require MT::Util;
    require Notifier::Data;
    # break apart incoming record parameters
    my ($email, $record, $blog_id, $category_id, $entry_id, $author_id, $bulk) = @_;
    # only valid records are allowed past this point
    return unless ($record eq Notifier::Data::OPT_OUT() || $record eq Notifier::Data::SUBSCRIBE());
    # only valid e-mails are allowed past this point
    if (my $fixed = MT::Util::is_valid_email($email)) {
        $email = $fixed;
    } else {
        return 1;
    }
    # all good - now what sort of record do we have?
    require MT::Blog;
    my $blog;
    if ($author_id) {
        require MT::Author;
        my $author = MT::Author->load($author_id);
        return 2 unless ((ref $author) && $author->isa('MT::Author'));
        if ($blog_id) {
            $blog = MT::Blog->load($blog_id);
            return 2 unless ((ref $blog) && $blog->isa('MT::Blog'));
        } else {
            $blog_id = 0;
        }
        $category_id = 0;
        $entry_id = 0;
    } elsif ($entry_id) {
        require MT::Entry;
        my $entry = MT::Entry->load($entry_id);
        return 2 unless ((ref $entry) && $entry->isa('MT::Entry'));
        $blog = MT::Blog->load($entry->blog_id);
        return 2 unless ((ref $blog) && $blog->isa('MT::Blog'));
        $blog_id = $blog->id;
        $category_id = 0;
        $author_id = 0;
    } elsif ($category_id) {
        require MT::Category;
        my $category = MT::Category->load($category_id);
        return 2 unless ((ref $category) && $category->isa('MT::Category'));
        $blog = MT::Blog->load($category->blog_id);
        return 2 unless ((ref $blog) && $blog->isa('MT::Blog'));
        $blog_id = $blog->id;
        $entry_id = 0;
        $author_id = 0;
    } elsif ($blog_id) {
        $blog = MT::Blog->load($blog_id);
        return 2 unless ((ref $blog) && $blog->isa('MT::Blog'));
        $category_id = 0;
        $entry_id = 0;
        $author_id = 0;
    }
    if ($blog_id) {
        require MT::Request;
        my $r = MT::Request->instance;
        $r->cache('mtn_blog', $blog);
    }
    my $data = Notifier::Data->load({
        blog_id => $blog_id,
        category_id => $category_id,
        entry_id => $entry_id,
        author_id => $author_id,
        email => $email,
        record => $record
    });
    if ($data) {
        return 3;
    } else {
        require Notifier::Util;
        $data = Notifier::Data->new;
        $data->blog_id($blog_id);
        $data->category_id($category_id);
        $data->entry_id($entry_id);
        $data->author_id($author_id);
        $data->email($email);
        $data->record($record);
        $data->cipher(Notifier::Util::produce_cipher(
            'a'.$email.'b'.$blog_id.'c'.$category_id.'d'.$entry_id.'e'.$author_id
        ));
        my $confirm = Notifier::Util::check_config_flag('confirm');
        if (($confirm == Notifier::Data::FULL()) || ($author_id && ($confirm == Notifier::Data::SITE()))) {
            $data->status(Notifier::Data::RUNNING()) if ($bulk);
            $data->status(Notifier::Data::PENDING()) unless ($bulk);
        } else {
            $data->status(Notifier::Data::RUNNING());
        }
        $data->ip(MT->app->remote_ip);
        $data->type(0); # 6.0?
        $data->save;
        data_confirmation($data) if ($data->status == Notifier::Data::PENDING());
    }
    return 0;
}

sub data_confirmation {
    my ($data) = @_;
    my ($blog, $category, $entry, $author, $type);
    my $plugin = MT->component('Notifier');
    if ($data->author_id) {
        require MT::Author;
        $author = MT::Author->load($data->author_id);
        return unless ((ref $author) && $author->isa('MT::Author'));
        $type = $plugin->translate('Author');
    } elsif ($data->entry_id) {
        require MT::Entry;
        $entry = MT::Entry->load($data->entry_id);
        return unless ((ref $entry) && $entry->isa('MT::Entry'));
        $blog = MT::Blog->load($entry->blog_id);
        return 2 unless ((ref $blog) && $blog->isa('MT::Blog'));
        $type = $plugin->translate('Entry');
        $author = ($entry->author) ? $entry->author : '';
    } elsif ($data->category_id) {
        require MT::Category;
        $category = MT::Category->load($data->category_id);
        return unless ((ref $category) && $category->isa('MT::Category'));
        $blog = MT::Blog->load($category->blog_id);
        return 2 unless ((ref $blog) && $blog->isa('MT::Blog'));
        $type = $plugin->translate('Category');
    } else {
        $blog = MT::Blog->load($data->blog_id);
        return 2 unless ((ref $blog) && $blog->isa('MT::Blog'));
        $type = $plugin->translate('Blog');
    }
    require Notifier::Util;
    my $sender_address = Notifier::Util::load_sender_address($author, $blog);
    return unless ($sender_address);
    require MT::Util;
    require Notifier::Data;
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
    if ($author) {
        my $link = $author->url;
        $param{'notifier_record_link'} = $link;
        $param{'notifier_record_text'} = MT::Util::remove_html($author->nickname);
    }
    # load confirmation subject template
    my %parms = (
        'identifier'  => 'notifier_confirmation_subject',
        'blog_id'     => $data->blog_id,
        'category_id' => $data->category_id,
        'entry_id'    => $data->entry_id,
        'author_id'   => $data->author_id,
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
    require MT::Mail;
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

sub notification_list {
    # generates a subscription list for a specific object and record type
    my $obj = shift;
    my $record = shift;
    require MT::Comment;
    require MT::Entry;
    my ($author_id, $entry, $entry_id, $comment, $comment_id, $categories);
    my ($class, $type);
    my $plugin = MT->component('Notifier');
    if ((ref $obj) && $obj->isa('MT::Comment')) {
        $entry = MT::Entry->load($obj->entry_id);
        return unless ((ref $entry) && $entry->isa('MT::Entry'));
        $class = 'comment';
        $comment = $obj;
        $comment_id = $comment->id;
        $entry_id = $comment->entry->id;
        $type = $plugin->translate('Comment');
        # store current categories for use later if needed
        if ($plugin->get_config_value('blog_all_comments', 'blog:'.$obj->blog_id)) {
            $categories = $comment->entry->categories;
        }
        # store author id for use later if needed
        $author_id = $comment->entry->author_id;
    }
    if ((ref $obj) && $obj->isa('MT::Entry')) {
        $class = 'entry';
        $comment_id = 0;
        $entry = $obj;
        $entry_id = 0;
        $type = $plugin->translate('Entry');
        # store current categories for use later if needed
        $categories = $entry->categories;
        # store author id for use later if needed
        $author_id = $entry->author_id;
    }
    require MT::Blog;
    my $blog = MT::Blog->load($obj->blog_id);
    return unless ((ref $blog) && $blog->isa('MT::Blog'));
    # set terms hash with blog id of current entry
    require Notifier::Data;
    my %terms = (
        'blog_id' => $blog->id,
        'category_id' => 0,
        'entry_id' => $entry_id,
        'author_id' => 0,
        'record' => $record,
        'status' => Notifier::Data::RUNNING(),
    );
    # load current blog subs to notify users of new entries
    my @work_subs = Notifier::Data->load(\%terms);
    # load categories, update terms hash, load category subs
    foreach my $cat (@$categories) {
        require MT::Category;
        next unless ((ref $cat) && $cat->isa('MT::Category'));
        $terms{'category_id'} = $cat->id;
        my @category_subs = Notifier::Data->load(\%terms);
        foreach (@category_subs) {
            push @work_subs, $_;
        }
    }
    # update terms hash by adding author_id, load author subs
    $terms{'category_id'} = 0;
    $terms{'author_id'} = $author_id;
    my @author_subs = Notifier::Data->load(\%terms);
    foreach (@author_subs) {
        push @work_subs, $_;
    }
    # update terms hash for site-wide author_id, load author subs
    $terms{'blog_id'} = 0;
    @author_subs = Notifier::Data->load(\%terms);
    foreach (@author_subs) {
        push @work_subs, $_;
    }
    # return the list of subscriptions
    return \@work_subs;
}

sub notify_users {
    # sends mail, writes history
    my ($obj, $subs) = @_;
    require MT::Comment;
    require MT::Entry;
    my ($author_id, $entry, $entry_id, $comment, $comment_id, $category);
    my ($class, $type);
    my $plugin = MT->component('Notifier');
    if ((ref $obj) && $obj->isa('MT::Comment')) {
        $entry = MT::Entry->load($obj->entry_id);
        return unless ((ref $entry) && $entry->isa('MT::Entry'));
        $class = 'comment';
        $comment = $obj;
        $comment_id = $comment->id;
        $entry_id = $comment->entry->id;
        $type = $plugin->translate('Comment');
        # store current category for use later if needed
        $category = $comment->entry->category;
        # store author id for use later if needed
        $author_id = $comment->entry->author_id;
    }
    if ((ref $obj) && $obj->isa('MT::Entry')) {
        $class = 'entry';
        $comment_id = 0;
        $entry = $obj;
        $entry_id = $entry->id;
        $type = $plugin->translate('Entry');
        # store current category for use later if needed
        $category = $entry->category;
        # store author id for use later if needed
        $author_id = $entry->author_id;
    }
    require MT::Blog;
    my $blog = MT::Blog->load($obj->blog_id);
    return unless ((ref $blog) && $blog->isa('MT::Blog'));
    # load sender address
    require Notifier::Util;
    my $sender_address = Notifier::Util::load_sender_address($entry->author, $blog);
    return unless ($sender_address);
    my %head = (
        'From' => $sender_address,
    );
    # load notification subject template
    my %parms = (
        'identifier'  => 'notifier_'.$class.'_notification_subject',
        'blog_id'     => $blog->id,
        'category_id' => $category,
        'entry_id'    => $entry_id,
        'comment_id'  => $comment_id,
        'author_id'   => $author_id,
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
    my $bypass = Notifier::Util::check_config_flag('bypass');
    # check queued flags
    my $queued = Notifier::Util::check_config_flag('queued');
    my %sent;
    foreach my $sub (@$subs) {
        next if ($comment && $comment->email eq $sub->email);
        next if ($sent{$sub});
        my %terms;
        $terms{'data_id'} = $sub->id;
        $terms{'entry_id'} = $entry_id;
        $terms{'comment_id'} = $comment_id;
        require Notifier::History;
        my $history = Notifier::History->load(\%terms);
        if ($history) {
            $sent{$sub} = 1;
            next;
        }
        if ($bypass == Notifier::Data::FULL()) {
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
        if ($queued == Notifier::Data::FULL()) {
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