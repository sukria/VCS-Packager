package VCS::Packager::Repository;

use Coat::Types;
use VCS::Packager::WorkingCopy;
use VCS::Packager::VCS::SVN;
use VCS::Packager::VCS::BZR;

# list here supported VCS
enum 'VCS' => 'svn', 'bzr';

subtype 'Path'
    => as 'Str'
    => where { -e "$_" }
    => message { "'$_' is not a valid path" };

coerce 'VCS::Packager::WorkingCopy' 
    => from 'Path'
    => via { VCS::Packager::WorkingCopy->new(path => $_)};


use Coat;

has type => (
    is => 'ro',
    isa => 'VCS',
    required => 1,
);

has vcs => (
    is => 'rw', 
    isa => 'Object', 
);

has url => (is => 'rw', isa => 'Str');

has working_copy => (
    is => 'rw',
    isa => 'VCS::Packager::WorkingCopy',
    coerce => 1,
);

sub BUILD { 
    my ($self) = @_;

    my $vcs_class = "VCS::Packager::VCS::".uc($self->type);
    $self->vcs( $vcs_class->new );

    $self->working_copy->vcs( $self->vcs );
    
    $self->url($self->vcs->read_url($self->working_copy->path))
        unless defined $self->url;
}

sub revision {
    my ($self) = @_;
    $self->vcs->read_revision($self->working_copy->path);
}

sub DEMOLISH {
    my ($self) = @_;
}

sub sniff_vcs_type {
    my ($class, $working_copy_path) = @_;

    return undef unless defined $working_copy_path;

    if (-d "$working_copy_path/.svn") {
        return 'svn';

    } elsif (-d "$working_copy_path/.bzr") {
        return 'bzr';
    }

    return undef;
}

1;
__END__
