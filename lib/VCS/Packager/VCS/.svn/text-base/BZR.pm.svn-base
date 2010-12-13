package VCS::Packager::VCS::BZR;

use Coat;
use Carp 'confess';

use File::Spec;

extends 'VCS::Packager::VCS';

has '+name' => (default => 'bzr');
has '+bin'  => (default => '/usr/bin/bzr');

has version_info_cmd => (is => 'rw', isa => 'Str');


sub BUILD {
    my ($self) = @_;
    
    $self->update_cmd('LC_ALL=C '.$self->bin.' update >/dev/null');
    $self->info_cmd(  'LC_ALL=C '.$self->bin.' info -v');
    $self->export_cmd('LC_ALL=C '.$self->bin.' export');
    $self->checkout_cmd('LC_ALL=C '.$self->bin.' checkout');
    $self->version_info_cmd('LC_ALL=C '.$self->bin.' version-info --custom --template "{revno}"');
    $self->full_version_info_cmd('LC_ALL=C '.$self->bin.' version-info --rio');
}

# default export method
sub export {
    my ($self, %args) = @_;
    my $pwd = File::Spec->rel2abs(File::Spec->curdir);

    my $working_copy = File::Spec->rel2abs( $args{working_copy} );
    my $destination  = File::Spec->rel2abs( $args{destination} );

    confess "Cannot export without working_copy and destination"
        unless defined $working_copy and $destination;

    (system( $self->export_cmd." $destination/$args{branch} $working_copy >/dev/null") == 0) ||
        confess "unable to export: $!";

    chdir $pwd;
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

    return undef unless defined $line;

    chomp $line;
    if ($line =~ /\s*$field: (\S+)$/) {
        return "$1";
    }
    else {
        return undef;
    }
}

sub read_revision { 
    my ($self, $working_copy) = @_;

    my $pwd = File::Spec->rel2abs( File::Spec->curdir() );
    chdir $working_copy or confess "unable to chdir $working_copy : $!";

    open(CMD, $self->version_info_cmd.' |')
        or confess "unable to get information for repo: $!";
    my @lines = <CMD>;
    close CMD;
    chdir $pwd;

	return $lines[0];
}

sub read_url { 
    my ($self, $working_copy) = @_;

    my $url = $self->read_meta_field( 
        field        => 'checkout of branch', 
        working_copy => $working_copy,
    );

    return $url if defined $url;

    return $working_copy;
}


1;
