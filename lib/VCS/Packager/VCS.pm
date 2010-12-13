package VCS::Packager::VCS;

# interface for VCS engines (svn, cvs, bzr, ...)

use Coat;
use Carp 'confess';

has name => (is => 'rw', isa => 'Str', required => 1);
has bin  => (is => 'rw', isa => 'Str', required => 1);

has update_cmd   => (is => 'rw', isa => 'Str');
has info_cmd     => (is => 'rw', isa => 'Str');
has export_cmd   => (is => 'rw', isa => 'Str');
has checkout_cmd => (is => 'rw', isa => 'Str');
has full_version_info_cmd => (is => 'rw', isa => 'Str');

# default checkout method
sub checkout {
    my ($self, %args) = @_;
    my $repo_url = $args{repo_url};
    my $working_copy = $args{working_copy};

    confess "Cannot checkout without a repo_url and a working_copy" 
        unless defined $repo_url && defined $working_copy;

    my $pwd = File::Spec->rel2abs(File::Spec->curdir);
    chdir $working_copy or confess "unable to chdir $working_copy : $!";

    (system( $self->checkout_cmd." $repo_url >/dev/null") == 0) ||
        confess "unable to checkout : $!";

    chdir $pwd;
}

# default export method
sub export {
    my ($self, %args) = @_;
    my $pwd = File::Spec->rel2abs(File::Spec->curdir);

    my $working_copy = File::Spec->rel2abs( $args{working_copy} );
    my $destination  = File::Spec->rel2abs( $args{destination} );

    confess "Cannot export without working_copy and destination"
        unless defined $working_copy and $destination;

    # update the working copy (to get real last revision)
    chdir $working_copy or confess "unable to chdir $working_copy";
    (system( $self->update_cmd ) == 0) 
        or confess "Unable to update working copy $working_copy";

    chdir $destination or confess "unable to chdir $destination : $!";

    (system( $self->export_cmd." $working_copy >/dev/null") == 0) ||
        confess "unable to export: $!";

    chdir $pwd;
}

sub write_version_info {
    my ($self, %args) = @_;

    my $destination  = File::Spec->rel2abs( $args{destination} );
    my $working_copy = File::Spec->rel2abs( $args{working_copy} );
    my $filename = $destination."/".$args{branch}."/".$args{filename};

    print "-> Writing revision info: ".$filename."\n";
    (system($self->full_version_info_cmd." $working_copy > $filename") == 0) ||
        confess "unable to write revision info: $!";
}

# those ones are VCS-sepcific and should then be implemented 
# in daughters classes.
sub read_meta_field    { confess "method not implemented" }
sub read_revision      { confess "method not implemented" }
sub read_url           { confess "method not implemented" }

1;
