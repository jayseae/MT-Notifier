# ===========================================================================
# A Movable Type plugin with subscription options for your installation
# Copyright 2003-2008 Everitz Consulting <everitz.com>.
#
# This program may not be redistributed without permission.
# ===========================================================================
package Notifier::Manager;

use strict;

use MT::Util qw(format_ts relative_date);

my $Notifier = MT::Plugin::Notifier->instance;

sub _output_itemset_action_widget {
  my ($cb, $app, $template, $param, $tmpl) = @_;
  my ($n, $new, $old);

  my @text = (
    'Add Subscription(s)',
    'Add Subscription Block(s)',
    'View Subscription Count',
    'Block Subscription(s)',
    'Clear Subscription(s)',
    'Verify Subscription(s)'
  );
  foreach (@text) {
    $n = $Notifier->translate($_);
    $old = qq{$_};
    $old = quotemeta($old);
    $new = qq{$n};
    $$template =~ s/$old/$new/;
  }
}

sub _param_list_notification {
  my ($cb, $app, $param) = @_;
  my %param = $_[0] ? %{ $_[0] } : ();
  my $q = $app->param;
  my $type = $q->param('_type');
  my $blog_id = $app->param('blog_id');

  # verify userlist override
  return unless check_userlist($app);

  my (%terms, %args);
  my $list_pref = $app->list_pref($type);
  %param = ( %param, %$list_pref );

  require Notifier::Data;
  my $cols = Notifier::Data->column_names;
  my $limit = $list_pref->{rows};
  my $offset = $limit eq 'none' ? 0 : ($app->param('offset') || 0);

  # seems to be set - reset
  # without, short filtered
  # pages have link to next
  # page, which is empty...
  $param->{next_offset} = 0;

  # set %terms
  for my $name (@$cols) {
    $terms{blog_id} = $blog_id, last
      if $name eq 'blog_id';
  }
  if (my $filter = $q->param('filter_val')) {
    if ($filter eq 'active') {
      $terms{record} = 1;
      $terms{status} = 1;
    }
    if ($filter eq 'blocked') {
      $terms{record} = 0;
    }
    if ($filter eq 'pending') {
      $terms{status} = 0;
    }
    $param->{filter_val} = $filter;
    $param->{filter} = 1;
  }

  # set %args
  $args{direction} = 'descend';
  $args{offset} = $offset;
  $args{limit} = $limit + 1 if $limit ne 'none';

  # load data
  my @data;
  require MT::Blog;
  my $blog = MT::Blog->load($blog_id, {cached_ok=>1});
  my $iter = Notifier::Data->load_iter(\%terms, \%args);
  while (my $obj = $iter->()) {
    my $row = $obj->column_values;
    if (my $ts = $obj->created_on) {
      $row->{created_on_formatted} = format_ts("%Y.%m.%d", $ts);
      $row->{created_on_time_formatted} = format_ts("%Y.%m.%d %H:%M:%S", $ts);
      $row->{created_on_relative} = relative_date($ts, time, $blog);
    }
    $row->{category_record} = 1 if ($obj->category_id);
    $row->{entry_record} = 1 if ($obj->entry_id);
    $row->{url_block} = !$obj->record;
    $row->{visible} = $obj->status;
    if ($limit && $limit ne 'none' && (scalar @data == $limit)) {
      $param->{next_offset} = 1;
      last;
    }
    push @data, $row;
  } # end loop over the set of objects;

  $param->{object_loop} = \@data;
  $param->{object_count} = scalar @data;
  $param->{offset} = $offset;
  $param->{list_start} = $offset + 1;
  delete $args{direction};
  delete $args{limit};
  delete $args{offset};
  $param->{list_total} = Notifier::Data->count(\%terms, \%args);
  $param->{list_end} = $offset + (scalar @data);
  $param->{next_offset_val} = $offset + (scalar @data);
  $param->{next_max} = $param->{list_total} - ($limit eq 'none' ? 0 : $limit);
  $param->{next_max} = 0 if ($param->{next_max} || 0) < $offset + 1;
  if ($offset > 0) {
    $param->{prev_offset} = 1;
    $param->{prev_offset_val} = $offset - ($limit eq 'none' ? 0 : $limit);
    $param->{prev_offset_val} = 0 if $param->{prev_offset_val} < 0;
  }
  $param->{list_noncron} = 0;

  # update "notification" to "subscription"
  my $page_titles = $param->{page_titles};
  my @page_titles = @$page_titles;
  foreach my $page_title (@page_titles) {
    $page_title->{bc_name} =~ s/^Notification/Subscription/;
  }
  my $breadcrumbs = $param->{breadcrumbs};
  my @breadcrumbs = @$breadcrumbs;
  foreach my $breadcrumbs (@breadcrumbs) {
    $breadcrumbs->{bc_name} =~ s/^Notification/Subscription/;
  }
}

sub _source_blog_left_nav {
  my ($cb, $app, $template) = @_;
  my ($n, $new, $old);

  # verify userlist override
  return unless check_userlist($app);

  $n = $Notifier->translate('Edit Subscription List');
  $old = qq{<MT_TRANS phrase="Edit Notification List">};
  $old = quotemeta($old);
  $new = qq{$n};
  $$template =~ s/$old/$new/;

  $n = $Notifier->translate('Subscriptions');
  $old = qq{<MT_TRANS phrase="Notifications">};
  $old = quotemeta($old);
  $new = qq{$n};
  $$template =~ s/$old/$new/;
}

sub _source_header {
  my ($cb, $app, $template) = @_;
  my ($new, $old);

  # verify userlist override
  return unless check_userlist($app);

  $old = qq{<style type="text/css">};
  $old = quotemeta($old);
  $new = <<HTML;
<script type="text/javascript">
function doDeleteItems (f, singular, plural, nameRestrict, args) {
    var count = countMarked(f, nameRestrict);
    if (!count) {
        alert(trans('You did not select any [_1] to delete.', plural));
        return false;
    }
    var toRemove = "";
    for (var i = 0; i < f.childNodes.length; i++) {
        if (f.childNodes[i].name == '_type') {
            toRemove = f.childNodes[i].value;
            break;
        }
    }
    singularMessage = trans('Are you sure you want to delete this [_1]?');
    pluralMessage = trans('Are you sure you want to delete the [_1] selected [_2]?');

    if (confirm(count == 1 ? trans(singularMessage, singular) : trans(pluralMessage, count, plural))) {
        return doForMarkedInThisWindow(f, singular, plural, nameRestrict, 'delete_subs', args, trans('to delete'));
    }
}
</script>
<style type="text/css">
.list table td.status-block img { background-image: url(<TMPL_VAR NAME=STATIC_URI>images/status_icons/neutral.gif); }};
.list table tr.selected td.status-block img { background-image: url(<TMPL_VAR NAME=STATIC_URI>images/status_icons/invert-neutral.gif); }};
HTML
  $$template =~ s/$old/$new/;
}

sub _source_list_notification {
  my ($cb, $app, $template) = @_;
  my $q = $app->param;
  my ($n, $new, $old);

  # verify userlist override
  return unless check_userlist($app);

  $n = $Notifier->translate('Subscriptions');
  $old = qq{<MT_TRANS phrase="Notifications">};
  $old = quotemeta($old);
  $new = qq{$n};
  $$template =~ s/$old/$new/;

  $old = qq{<p class="page-desc"><MT_TRANS phrase="Below is the notification list for this blog. When you manually send notifications on published entries, you can select from this list."></p>};
  $old = quotemeta($old);
  $new = '';
  $$template =~ s/$old/$new/;

  $n = $Notifier->translate('Create New Blog Subscription');
  $old = qq{<MT_TRANS phrase="Create New Notification">};
  $old = quotemeta($old);
  $new = qq{$n};
  $$template =~ s/$old/$new/g;

  $n = $Notifier->translate('[_1] is currently providing this list. You may change this behavior from the plugins settings menu.', 'MT-Notifier');
  $old = qq{<div class="tabs">};
  $old = quotemeta($old);
  $new = <<HTML;
<h4 class="message">$n</h4>

<div class="tabs">
HTML
  $$template =~ s/$old/$new/;

  my $n1 = $Notifier->translate('Only show');
  my $n2 = $Notifier->translate('active');
  my $n3 = $Notifier->translate('blocked');
  my $n4 = $Notifier->translate('or');
  my $n5 = $Notifier->translate('pending');
  my $n6 = $Notifier->translate('subscriptions');
  my $n7 = $Notifier->translate('Show all subscriptions');
  my $n8 = $Notifier->translate('(Showing all subscriptions.)');
  my $n9 = $Notifier->translate('Showing only '.$q->param('filter_val').' subscriptions.');
  $old = qq{<div class="create-inline" id="create-inline-notification">};
  $old = quotemeta($old);
  $new = <<HTML;
<div class="list-filters">
<div class="inner">
<div id="filter-active">
<div class="rightcol">
<TMPL_UNLESS NAME=FILTER>
<MT_TRANS phrase="Quickfilter:"> $n1 <a href="<TMPL_VAR NAME=SCRIPT_URL>?__mode=list&amp;_type=notification<TMPL_IF NAME=BLOG_ID>&amp;blog_id=<TMPL_VAR NAME=BLOG_ID></TMPL_IF>&amp;filter_val=active">$n2</a>, <a href="<TMPL_VAR NAME=SCRIPT_URL>?__mode=list&amp;_type=notification<TMPL_IF NAME=BLOG_ID>&amp;blog_id=<TMPL_VAR NAME=BLOG_ID></TMPL_IF>&amp;filter_val=blocked">$n3</a> $n4 <a href="<TMPL_VAR NAME=SCRIPT_URL>?__mode=list&amp;_type=notification<TMPL_IF NAME=BLOG_ID>&amp;blog_id=<TMPL_VAR NAME=BLOG_ID></TMPL_IF>&amp;filter_val=pending">$n5</a> $n6
<TMPL_ELSE>
<a href="<TMPL_VAR NAME=SCRIPT_URL>?__mode=list&amp;_type=notification<TMPL_IF NAME=BLOG_ID>&amp;blog_id=<TMPL_VAR NAME=BLOG_ID></TMPL_IF>" title="$n7"><MT_TRANS phrase="Reset"></a>
</TMPL_UNLESS>
</div> 
<strong><MT_TRANS phrase="Filter">:</strong>
<TMPL_UNLESS NAME=FILTER>
<MT_TRANS phrase="None."> <span class="hint">$n8</span>
<TMPL_ELSE>
$n9
</TMPL_UNLESS>
</div>
</div>
</div>

<div class="create-inline" id="create-inline-notification">
HTML
  $$template =~ s/$old/$new/;

  $old = qq{<input type="hidden" name="blog_id" value="<TMPL_VAR NAME=BLOG_ID>" />};
  $old = quotemeta($old);
  $new = qq{<input type="hidden" name="id" value="<TMPL_VAR NAME=BLOG_ID>" />};
  $$template =~ s/$old/$new/;

  $old = qq{<input type="hidden" name="__mode" value="save" />};
  $old = quotemeta($old);
  $new = qq{<input type="hidden" name="__mode" value="create_subs" />};
  $$template =~ s/$old/$new/;

  $old = qq{<input type="hidden" name="_type" value="notification" />};
  $old = quotemeta($old);
  $new = <<HTML;
<input type="hidden" name="_type" value="blog" />
<input type="hidden" name="record" value="1" />
HTML
  $$template =~ s/$old/$new/;

  $old = qq{<MT_TRANS phrase="Email Address">: <input name="email" id="email" value="<TMPL_VAR NAME=EMAIL>" />};
  $old = quotemeta($old);
  $new = qq{<MT_TRANS phrase="Email Address">: <input name="addresses" id="email" value="<TMPL_VAR NAME=EMAIL>" />};
  $$template =~ s/$old/$new/;

  $n = $Notifier->translate('Add Subscription');
  $old = qq{<MT_TRANS phrase="Add Recipient">};
  $old = quotemeta($old);
  $new = qq{$n};
  $$template =~ s/$old/$new/;

  $n = $Notifier->translate('No subscriptions could be found.');
  $old = qq{<MT_TRANS phrase="No notifications could be found.">};
  $old = quotemeta($old);
  $new = qq{$n};
  $$template =~ s/$old/$new/;
}

sub _source_notification_actions {
  my ($cb, $app, $template) = @_;
  my ($new, $old);

  # verify userlist override
  return unless check_userlist($app);

  my $n1 = $Notifier->translate('subscription address');
  my $n2 = $Notifier->translate('subscription addresses');
  my $n3 = $Notifier->translate('Delete selected subscription addresses (x)');
  $old = qq{<input type="button" name="delete" value="<MT_TRANS phrase="Delete">" onclick="doRemoveItems(this.form, '<MT_TRANS phrase="notification address">', '<MT_TRANS phrase="notification addresses">')" accesskey="x" title="<MT_TRANS phrase="Delete selected notification addresses (x)">" />};
  $old = quotemeta($old);
  $new = qq{<input type="button" name="delete" value="<MT_TRANS phrase="Delete">" onclick="doDeleteItems(this.form, '$n1', '$n2')" accesskey="x" title="$n3" />};
  $$template =~ s/$old/$new/;
}

sub _source_notification_table {
  my ($cb, $app, $template) = @_;
  my ($n, $new, $old);

  # verify userlist override
  return unless check_userlist($app);

  # code between these lines only needed until bug fixed (#45254)

  $old = qq{<input type="hidden" name="itemset_action_input" value="" />};
  $old = quotemeta($old);
  $new = <<HTML;
<input type="hidden" name="action_name" value="" />
<input type="hidden" name="itemset_action_input" value="" />
HTML
  $$template =~ s/$old/$new/;

  # code between these lines only needed until bug fixed (#45254)

  $old = qq{<th class="cb" id="delete-col-head"><input type="checkbox" name="id-head" value="all" class="select" /></th>};
  $old = quotemeta($old);
  $new = <<HTML;
<th class="cb" id="delete-col-head"><input type="checkbox" name="id-head" value="all" class="select" /></th>
<th id="nt-status"><img src="<TMPL_VAR NAME=STATIC_URI>images/status_icons/flag.gif" alt="<MT_TRANS phrase="Status">" title="<MT_TRANS phrase="Status">" width="9" height="9" /></th>
HTML
  $$template =~ s/$old/$new/;

  $old = qq{<th id="nt-email"><MT_TRANS phrase="Email Address"></th>};
  $old = quotemeta($old);
  $new = <<HTML;
<th id="nt-email"><MT_TRANS phrase="Email Address"></th>
<th id="nt-type"><MT_TRANS phrase="Type"></th>
HTML
  $$template =~ s/$old/$new/;

  $old = qq{<th id="nt-url"><MT_TRANS phrase="URL"></th>};
  $old = quotemeta($old);
  $new = '';
  $$template =~ s/$old/$new/;

  my $n1 = $Notifier->translate('Only show blocked subscriptions');
  my $n2 = $Notifier->translate('Blocked');
  my $n3 = $Notifier->translate('Only show active subscriptions');
  my $n4 = $Notifier->translate('Active');
  my $n5 = $Notifier->translate('Only show pending subscriptions');
  my $n6 = $Notifier->translate('Pending');
  $old = qq{<td class="cb" id="delete-<TMPL_VAR NAME=ID>"><input type="checkbox" name="id" value="<TMPL_VAR NAME=ID>" class="select" /></td>};
  $old = quotemeta($old);
  $new = <<HTML;
<td class="cb" id="delete-<TMPL_VAR NAME=ID>"><input type="checkbox" name="id" value="<TMPL_VAR NAME=ID>" class="select" /></td>
<td class="<TMPL_IF NAME=VISIBLE><TMPL_IF NAME=URL_BLOCK>status-block<TMPL_ELSE>status-publish</TMPL_IF><TMPL_ELSE>status-pending</TMPL_IF>">
<TMPL_IF NAME=VISIBLE>
<TMPL_IF NAME=URL_BLOCK>
<a href="<TMPL_VAR NAME=SCRIPT_URL>?__mode=list&amp;_type=notification<TMPL_IF NAME=BLOG_ID>&amp;blog_id=<TMPL_VAR NAME=BLOG_ID></TMPL_IF>&amp;filter_val=blocked" title="$n1"><img src="<TMPL_VAR NAME=STATIC_URI>images/spacer.gif" alt="$n2" width="9" height="9" /></a>
<TMPL_ELSE>
<a href="<TMPL_VAR NAME=SCRIPT_URL>?__mode=list&amp;_type=notification<TMPL_IF NAME=BLOG_ID>&amp;blog_id=<TMPL_VAR NAME=BLOG_ID></TMPL_IF>&amp;filter_val=active" title="$n3"><img src="<TMPL_VAR NAME=STATIC_URI>images/spacer.gif" alt="$n4" width="9" height="9" /></a>
</TMPL_IF>
<TMPL_ELSE>
<a href="<TMPL_VAR NAME=SCRIPT_URL>?__mode=list&amp;_type=notification<TMPL_IF NAME=BLOG_ID>&amp;blog_id=<TMPL_VAR NAME=BLOG_ID></TMPL_IF>&amp;filter_val=pending" title="$n5"><img src="<TMPL_VAR NAME=STATIC_URI>images/spacer.gif" alt="$n6" width="9" height="9" /></a>
</TMPL_IF>
</td>
HTML
  $$template =~ s/$old/$new/;

  $n = $Notifier->translate('Subscription');
  $old = qq{<td><a href="mailto:<TMPL_VAR NAME=EMAIL ESCAPE=URL>"><TMPL_VAR NAME=EMAIL ESCAPE=HTML></td>};
  $old = quotemeta($old);
  $new = <<HTML;
<td><a href="mailto:<TMPL_VAR NAME=EMAIL ESCAPE=URL>"><TMPL_VAR NAME=EMAIL ESCAPE=HTML></td>

<td><img src="<TMPL_VAR NAME=STATIC_URI>images/nav_icons/mini/<TMPL_IF NAME=ENTRY_RECORD>comments<TMPL_ELSE><TMPL_IF NAME=CATEGORY_RECORD>entries<TMPL_ELSE>docs</TMPL_IF></TMPL_IF>.gif" alt="<TMPL_IF NAME=ENTRY_RECORD><MT_TRANS phrase="Entry"><TMPL_ELSE><TMPL_IF NAME=CATEGORY_RECORD><MT_TRANS phrase="Category"><TMPL_ELSE><MT_TRANS phrase="Blog"></TMPL_IF></TMPL_IF> <MT_TRANS phrase="Subscription">"  title="<TMPL_IF NAME=ENTRY_RECORD><MT_TRANS phrase="Entry"><TMPL_ELSE><TMPL_IF NAME=CATEGORY_RECORD><MT_TRANS phrase="Category"><TMPL_ELSE><MT_TRANS phrase="Blog"></TMPL_IF></TMPL_IF> <MT_TRANS phrase="Subscription">"width="9" height="11" /></td>
HTML
  $$template =~ s/$old/$new/;

  $old = qq{<td><TMPL_IF NAME=URL><a href="<TMPL_VAR NAME=URL>"><TMPL_VAR NAME=URL ESCAPE=HTML></a><TMPL_ELSE><TMPL_VAR NAME=URL ESCAPE=HTML></TMPL_IF></td>};
  $old = quotemeta($old);
  $new = '';
  $$template =~ s/$old/$new/;
}

sub check_userlist {
  my $app = shift;
  my $blog_id = $app->param('blog_id');
  my ($blog_userlist, $system_userlist, $userlist);

  if ($blog_id) {
    $blog_userlist = $Notifier->get_config_value('blog_userlist', 'blog:'.$blog_id);
  }

  # blog_userlist:
  # 1 = system
  # 2 = mt
  # 3 = mt-notifier

  # system userlist
  # 1 = mt
  # 2 = mt-notifier

  if (!$blog_userlist || $blog_userlist == 1) {
    $system_userlist = $Notifier->get_config_value('system_userlist');
    $userlist = ($system_userlist == 1) ? 0 : 1;
  } else {
    $userlist = ($blog_userlist == 2) ? 0 : 1;
  }

  return $userlist;
}

1;