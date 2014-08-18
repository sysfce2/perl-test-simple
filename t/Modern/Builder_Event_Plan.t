use strict;
use warnings;

use Test::More 'modern';

require_ok 'Test::Builder::Event::Plan';

my $one = Test::Builder::Event::Plan->new;

isa_ok($one, 'Test::Builder::Event::Plan');
isa_ok($one, 'Test::Builder::Event');

can_ok($one, qw/max directive reason/);

$one->max(5);
is($one->to_tap, "1..5\n", "Got plan");

$one->directive('SKIP');
is($one->to_tap, "1..5 # SKIP\n", "Got plan with directive");

$one->reason('blah blah');
is($one->to_tap, "1..5 # SKIP blah blah\n", "Got plan with directive");

done_testing;