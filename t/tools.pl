use Scalar::Util qw/blessed/;

use Test2::Util qw/try/;
use Test2 qw/context run_subtest/;

use Test2::Hub::Interceptor();
use Test2::Hub::Interceptor::Terminator();

sub ok($;$@) {
    my ($bool, $name, @diag) = @_;
    my $ctx = context();
    $ctx->ok($bool, $name, \@diag);
    $ctx->release;
    return $bool ? 1 : 0;
}

sub is($$;$@) {
    my ($got, $want, $name, @diag) = @_;
    my $ctx = context();

    my $bool;
    if (defined($got) && defined($want)) {
        $bool = "$got" eq "$want";
    }
    elsif (defined($got) xor defined($want)) {
        $bool = 0;
    }
    else { # Both are undef
        $bool = 1;
    }

    unless ($bool) {
        $got  = '*NOT DEFINED*' unless defined $got;
        $want = '*NOT DEFINED*' unless defined $want;
        unshift @diag => (
            "GOT:      $got",
            "EXPECTED: $want",
        );
    }

    $ctx->ok($bool, $name, \@diag);
    $ctx->release;
    return $bool;
}

sub isnt($$;$@) {
    my ($got, $want, $name, @diag) = @_;
    my $ctx = context();

    my $bool;
    if (defined($got) && defined($want)) {
        $bool = "$got" ne "$want";
    }
    elsif (defined($got) xor defined($want)) {
        $bool = 1;
    }
    else { # Both are undef
        $bool = 0;
    }

    unshift @diag => "Strings are the same (they should not be)"
        unless $bool;

    $ctx->ok($bool, $name, \@diag);
    $ctx->release;
    return $bool;
}

sub like($$;$@) {
    my ($thing, $pattern, $name, @diag) = @_;
    my $ctx = context();

    my $bool;
    if (defined($thing)) {
        $bool = "$thing" =~ $pattern;
        unshift @diag => (
            "Value: $thing",
            "Does not match: $pattern"
        ) unless $bool;
    }
    else {
        $bool = 0;
        unshift @diag => "Got an undefined value.";
    }

    $ctx->ok($bool, $name, \@diag);
    $ctx->release;
    return $bool;
}

sub unlike($$;$@) {
    my ($thing, $pattern, $name, @diag) = @_;
    my $ctx = context();

    my $bool;
    if (defined($thing)) {
        $bool = "$thing" !~ $pattern;
        unshift @diag => (
            "Unexpected pattern match (it should not match)",
            "Value:   $thing",
            "Matches: $pattern"
        ) unless $bool;
    }
    else {
        $bool = 0;
        unshift @diag => "Got an undefined value.";
    }

    $ctx->ok($bool, $name, \@diag);
    $ctx->release;
    return $bool;
}

sub is_deeply($$;$@) {
    my ($got, $want, $name, @diag) = @_;
    my $ctx = context();

    no warnings 'once';
    require Data::Dumper;
    local $Data::Dumper::Sortkeys = 1;
    local $Data::Dumper::Deparse  = 1;
    local $Data::Dumper::Freezer = 'XXX';
    local *UNIVERSAL::XXX = sub {
        my ($thing) = @_;
        if (ref($thing)) {
            $thing = {%$thing}  if "$thing" =~ m/=HASH/;
            $thing = [@$thing]  if "$thing" =~ m/=ARRAY/;
            $thing = \"$$thing" if "$thing" =~ m/=SCALAR/;
        }
        $_[0] = $thing;
    };

    my $g = Data::Dumper::Dumper($got);
    my $w = Data::Dumper::Dumper($want);

    my $bool = $g eq $w;

    $ctx->ok($bool, $name, [$g, $w, @diag]);
    $ctx->release;
    return $bool;
}

sub diag {
    my $ctx = context();
    $ctx->diag( join '', @_ );
    $ctx->release;
}

sub note {
    my $ctx = context();
    $ctx->note( join '', @_ );
    $ctx->release;
}

sub skip_all {
    my ($reason) = @_;
    my $ctx = context();
    $ctx->plan(0, SKIP => $reason);
    $ctx->release if $ctx;
}

sub plan {
    my ($max) = @_;
    my $ctx = context();
    $ctx->plan($max);
    $ctx->release;
}

sub done_testing {
    my $ctx = context();
    $ctx->done_testing;
    $ctx->release;
}

sub warnings(&) {
    my $code = shift;
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings => @_ };
    $code->();
    return \@warnings;
}

sub exception(&) {
    my $code = shift;
    local ($@, $!, $SIG{__DIE__});
    my $ok = eval { $code->(); 1 };
    return $ok ? undef : $@;
}

sub tests {
    my ($name, $code) = @_;
    my $ctx = context();

    before_each() if __PACKAGE__->can('before_each');

    my $bool = run_subtest($name, $code, 1);

    $ctx->release;

    return $bool;
}

1;
