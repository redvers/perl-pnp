package QxServ::JsonRpcService;
use Mojo::Base -base;
 
# whenever a service method is about to be executed, the dispatcher calls the
# "allow_rpc_access" method to determine if the incoming request should be satisfied.
# You can use this facility to enforce access control to the methods of your service.
# Make sure to only allow access to the things you want to be public. Also the answers
# of the "allow_rpc_access" method could depend on the session status.
 
our %allow_access =  (
    echo => 1
);
 
sub allow_rpc_access {
    my $self = shift;
    my $method = shift;
    return $allow_access{$method};
}
 
# the echo method returns what it hears except when it hears 'die' then
# it dies. Here we use a hash pointer with a code and a message property
# with this we can control what gets sent back to the qooxdoo application.
 
sub echo {
    my $self = shift;
    my $arg = shift;
    if ($arg eq 'die'){
       die {code=>666,message=>"Aaaargh!"};
    }
    return "I hear: $arg";
}
