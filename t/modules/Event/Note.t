use strict;
use warnings;

BEGIN { require "t/tools.pl" };
use Test2::Event::Note;
use Test2::Util::Trace;

my $note = Test2::Event::Note->new(
    trace => Test2::Util::Trace->new(frame => [__PACKAGE__, __FILE__, __LINE__]),
    message => 'foo',
);

$note = Test2::Event::Note->new(
    trace => Test2::Util::Trace->new(frame => [__PACKAGE__, __FILE__, __LINE__]),
    message => undef,
);

is($note->message, 'undef', "set undef message to undef");

$note = Test2::Event::Note->new(
    trace => Test2::Util::Trace->new(frame => [__PACKAGE__, __FILE__, __LINE__]),
    message => {},
);

like($note->message, qr/^HASH\(.*\)$/, "stringified the input value");

done_testing;
