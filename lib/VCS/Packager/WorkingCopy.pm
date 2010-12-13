package VCS::Packager::WorkingCopy;

use File::Temp 'tempdir';
use File::Remove 'remove';
use File::Basename 'basename';

use Coat;

has vcs => (
    is => 'rw', 
    isa => 'Object', 
);

has path => (
    is => 'rw',
    isa => 'Str',
);

has revision => (
    is => 'rw',
    isa => 'Num'
);

has export_dir => (
    is => 'rw',
    required => 1,
    default => tempdir(),
    isa => 'Str'
);

sub BUILD { 
    my ($self) = @_;
}

sub DEMOLISH { 
    my ($self) = @_;
    remove(\1, $self->export_dir);
}

sub export {
    my ($self) = @_;

    $self->vcs->export(
        working_copy => $self->path,
        destination  => $self->export_dir,
        branch       => basename($self->path)
    );

    $self->vcs->write_version_info(
        working_copy => $self->path,
        destination  => $self->export_dir,
        branch       => basename($self->path),
        filename     => "VERSION"
    );
}

1;
