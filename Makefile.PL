use strict;
use warnings;
use ExtUtils::MakeMaker;

my @programs = qw( mint );

WriteMakefile(
    NAME                => 'Text::Mint',
    AUTHOR              => 'Shawn Boyette <mdxi@cpan.org>',
    VERSION_FROM        => 'lib/Text/Mint.pm',
    ABSTRACT_FROM       => 'lib/Text/Mint.pm',
    # EXE_FILES           => [ map {"bin/$_"} @programs],
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Text-Mint-*' },
);
