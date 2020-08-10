package Test2::API::InterceptResult;
use strict;
use warnings;

use Scalar::Util qw/blessed/;
use Storable qw/dclone/;
use Carp qw/croak/;

use Test2::API::InterceptResult::Event;
use Test2::API::InterceptResult::Squasher;

use Test2::Util::HashBase qw{
    +hub +subtest_event

    <raw_events <context

    <state

    +squash_info

    +subtest_results

    +events
    +asserts
    +subtests
    +diags
    +notes
    +errors
    +plans
};

sub init {
    my $self = shift;

    if (my $hub = $self->{+HUB}) {
        $self->{+STATE} ||= $hub->state;
    }
    elsif (my $se = $self->{+SUBTEST_EVENT}) {
        my ($sf) = $se->subtest or croak "not a subtest event";
        $self->{+STATE}      ||= $sf->{state};
        $self->{+RAW_EVENTS} ||= $sf->{children};
    }

    $self->{+STATE}      ||= {};
    $self->{+RAW_EVENTS} ||= [];

    $self->squash_info(1) unless defined $self->{+SQUASH_INFO};
}

sub squash_info {
    my $self = shift;
    return $self->{+SQUASH_INFO} unless @_;

    my $old = $self->{+SQUASH_INFO};
    my ($new) = @_;

    # No change if it was true and is true again or false and false again
    return $old if $old && $new;
    return $old if !$old && !$new;

    delete $self->{$_} for EVENTS, ASSERTS, SUBTESTS, DIAGS, NOTES, ERRORS, PLANS, SUBTEST_RESULTS;

    return $self->{+SQUASH_INFO} = $new;
}

sub upgrade_events {
    my $self = shift;
    my ($raw_events, %params) = @_;

    my (@events, $squasher);

    if ($self->{+SQUASH_INFO}) {
        $squasher = Test2::API::InterceptResult::Squasher->new(events => \@events);
    }

    for my $raw (@$raw_events) {
        my $fd = dclone(blessed($raw) ? $raw->facet_data : $raw);

        my $event = Test2::API::InterceptResult::Event->new(facet_data => $fd, result_class => blessed($self));

        if (my $parent = $fd->{parent}) {
            $parent->{children} = $self->upgrade_events($parent->{children} || []);
        }

        if ($squasher) {
            $squasher->process($event);
        }
        else {
            push @events => $event;
        }
    }

    $squasher->flush_down() if $squasher;

    return \@events;
}

sub flatten         {[ map { $_->flatten(@_) } @{shift->events} ]}
sub event_briefs    {[ map { $_->brief }       @{$_[0]->events} ]}
sub event_summaries {[ map { $_->summary }     @{$_[0]->events} ]}

sub subtest_results { $_[0]->{+SUBTEST_RESULTS} ||= [ map { $_->subtest_result } @{$_[0]->subtests} ] }

sub events   { $_[0]->{+EVENTS}   ||= $_[0]->upgrade_events($_[0]->{+RAW_EVENTS}) }
sub asserts  { $_[0]->{+ASSERTS}  ||= [grep { $_->assert  } @{$_[0]->events}]     }
sub subtests { $_[0]->{+SUBTESTS} ||= [grep { $_->subtest } @{$_[0]->events}]     }
sub diags    { $_[0]->{+DIAGS}    ||= [grep { $_->diags   } @{$_[0]->events}]     }
sub notes    { $_[0]->{+NOTES}    ||= [grep { $_->notes   } @{$_[0]->events}]     }
sub errors   { $_[0]->{+ERRORS}   ||= [grep { $_->errors  } @{$_[0]->events}]     }
sub plans    { $_[0]->{+PLANS}    ||= [grep { $_->plan    } @{$_[0]->events}]     }

sub diag_messages  {[ map { $_->{details} } @{$_[0]->diags}  ]}
sub note_messages  {[ map { $_->{details} } @{$_[0]->notes}  ]}
sub error_messages {[ map { $_->{details} } @{$_[0]->errors} ]}

# state delegation
sub assert_count { $_[0]->{+STATE}->{count} }
sub bailed_out   { $_[0]->{+STATE}->{bailed_out} }
sub failed_count { $_[0]->{+STATE}->{failed} }
sub follows_plan { $_[0]->{+STATE}->{follows_plan} }
sub is_passing   { $_[0]->{+STATE}->{is_passing} }
sub nested       { $_[0]->{+STATE}->{nested} }
sub skipped      { $_[0]->{+STATE}->{skip_reason} }

1;
