use Test2::IPC::Driver::Files2;
use Test2::Bundle::Extended -target => 'Test2::Workflow::Task::Action';

can_ok($CLASS, 'around');

done_testing;
