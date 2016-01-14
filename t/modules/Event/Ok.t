use strict;
use warnings;

BEGIN { require "t/tools.pl" };
use Test2::Util::Trace;
use Test2::Event::Ok;
use Test2::Event::Diag;

use Test2::API qw/context/;

my $trace;
sub before_each {
    # Make sure there is a fresh trace object for each group
    $trace = Test2::Util::Trace->new(
        frame => ['main_foo', 'foo.t', 42, 'main_foo::flubnarb'],
    );
}

tests Passing => sub {
    my $ok = Test2::Event::Ok->new(
        trace => $trace,
        pass  => 1,
        name  => 'the_test',
    );
    ok($ok->increments_count, "Bumps the count");
    ok(!$ok->causes_fail, "Passing 'OK' event does not cause failure");
    is($ok->pass, 1, "got pass");
    is($ok->name, 'the_test', "got name");
    is($ok->effective_pass, 1, "effective pass");
};

tests Failing => sub {
    local $ENV{HARNESS_ACTIVE} = 1;
    local $ENV{HARNESS_IS_VERBOSE} = 1;
    my $ok = Test2::Event::Ok->new(
        trace => $trace,
        pass  => 0,
        name  => 'the_test',
    );
    ok($ok->increments_count, "Bumps the count");
    ok($ok->causes_fail, "A failing test causes failures");
    is($ok->pass, 0, "got pass");
    is($ok->name, 'the_test', "got name");
    is($ok->effective_pass, 0, "effective pass");
};

tests "Failing TODO" => sub {
    local $ENV{HARNESS_ACTIVE} = 1;
    local $ENV{HARNESS_IS_VERBOSE} = 1;
    my $ok = Test2::Event::Ok->new(
        trace => $trace,
        pass  => 0,
        name  => 'the_test',
        todo  => 'A Todo',
    );
    ok($ok->increments_count, "Bumps the count");
    is($ok->pass, 0, "got pass");
    is($ok->name, 'the_test', "got name");
    is($ok->effective_pass, 1, "effective pass is true from todo");

    $ok = Test2::Event::Ok->new(
        trace => $trace,
        pass  => 0,
        name  => 'the_test2',
        todo  => '',
    );
    ok($ok->effective_pass, "empty string todo is still a todo");
};

tests init => sub {
    like(
        exception { Test2::Event::Ok->new(trace => $trace, pass => 1, name => "foo#foo") },
        qr/'foo#foo' is not a valid name, names must not contain '#' or newlines/,
        "Some characters do not belong in a name"
    );

    like(
        exception { Test2::Event::Ok->new(trace => $trace, pass => 1, name => "foo\nfoo") },
        qr/'foo\nfoo' is not a valid name, names must not contain '#' or newlines/,
        "Some characters do not belong in a name"
    );

    my $ok = Test2::Event::Ok->new(
        trace => $trace,
        pass  => 1,
    );
    is($ok->effective_pass, 1, "set effective pass");
};

done_testing;