use 5.012004;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'PNP::Comms',
    VERSION_FROM      => 'lib/PNP/Comms.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/PNP/Comms.pm', # retrieve abstract from module
       AUTHOR         => 'root <root@(none)>') : ()),
);
