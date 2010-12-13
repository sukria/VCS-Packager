package VCS::Packager::VCS::SVN;

use Coat;
use Carp 'confess';

use File::Spec;

extends 'VCS::Packager::VCS';

has '+name' => (default => 'svn');
has '+bin'  => (default => '/usr/bin/svn');

sub BUILD {
    my ($self) = @_;
    
    $self->update_cmd('LC_ALL=C '.$self->bin.' update >/dev/null');
    $self->info_cmd(  'LC_ALL=C '.$self->bin.' info');
    $self->export_cmd('LC_ALL=C '.$self->bin.' export');
    $self->checkout_cmd('LC_ALL=C '.$self->bin.' checkout');
    $self->full_version_info_cmd('LC_ALL=C '.$self->bin.' info');
}

sub read_meta_field {
    my ($self, %args) = @_;

    my $field = $args{field};
    my $working_copy = $args{working_copy};

    confess "field is needed" unless defined $field;
    confess "working_copy is needed" unless defined $working_copy;

    my $pwd = File::Spec->rel2abs( File::Spec->curdir() );
    chdir $working_copy or confess "unable to chdir $working_copy : $!";

    # Reading info from svn
    open(CMD, $self->info_cmd.' |')
        or confess "unable to get information for repo: $!";
    my @lines = <CMD>;
    close CMD;
    chdir $pwd;

    # looking for the Revision entry
    my @match = grep /$field/, @lines;
    my $line = $match[0];
    confess "Unable to find $field in [ @lines ]" 
        unless defined $line;

    chomp $line;
    if ($line =~ /$field: (\S+)$/) {
        return "$1";
    }
    else {
        confess "cannot match $field in: '$line'";
    }
}

# suggar over read_meta_field for fetching repository meta information
sub read_revision { 
    my ($self, $working_copy) = @_;
    $self->read_meta_field( 
        field        => 'Revision', 
        working_copy => $working_copy,
    ); 
}

sub read_url { 
    my ($self, $working_copy) = @_;
    $self->read_meta_field( 
        field        => 'URL', 
        working_copy => $working_copy,
    ); 
}


1;
