use ExtUtils::MakeMaker;

WriteMakefile(
    NAME => 'VCS::Packager',
    VERSION_FROM => 'lib/VCS/Packager.pm',
    EXE_FILES => [
        'bin/pack', 
        'bin/unpack',
        'bin/rollback',
        'bin/list-releases',
    ],
    PREREQ_PM => {
        'Coat' => '0.320',
        'File::Remove' => 0,
        'Archive::Tar' => 0,
        'LWP' => 0,
    },
    ABSTRACT => "Packager for VCS projects",
    test => {TESTS => join( ' ', glob( 't/*.t' ))},
);
