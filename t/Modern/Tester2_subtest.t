use strict;
use warnings;
use utf8;

use Test::More qw/modern/;
use Test::Tester2;

my $events = intercept {
    ok(0, "test failure" );
    ok(1, "test success" );

    subtest 'subtest' => sub {
        ok(0, "subtest failure" );
        ok(1, "subtest success" );

        subtest 'subtest_deeper' => sub {
            ok(0, "deeper subtest failure" );
            ok(1, "deeper subtest success" );
        };
    };

    ok(0, "another test failure" );
    ok(1, "another test success" );
};

#events_are {
#    check $events;
#    check intercept {
#
#    };
#
#    e ok => {};
#    e ok => {};
#}

events_are(
    $events,

    ok   => {bool => 0},
    diag => {},
    ok   => {bool => 1},

    child => {action => 'push'},
        note => {message => 'Subtest: subtest'},
        ok   => {bool => 0},
        diag => {},
        ok   => {bool => 1},

        child => {action => 'push'},
            note => {message => 'Subtest: subtest_deeper'},
            ok   => {bool => 0},
            diag => {},
            ok   => {bool => 1},

            plan   => {},
            finish => {},

            diag => {tap  => qr/Looks like you failed 1 test of 2/},
            ok   => {bool => 0},
            diag => {},
        child => {action => 'pop'},

        plan   => {},
        finish => {},

        diag => {tap  => qr/Looks like you failed 2 tests of 3/},
        ok   => {bool => 0},
        diag => {},
    child => {action => 'pop'},

    ok   => {bool => 0},
    diag => {},
    ok   => {bool => 1},

    end => "subtest events as expected",
);

done_testing;
