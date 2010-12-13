package VCS::Packager;

use Coat;
use Coat::Types;
use Carp 'confess';

use vars '$VERSION';
$VERSION = '0.1';

use File::Remove 'remove';
use File::Spec;
use File::Basename 'dirname', 'basename';
use File::Temp 'tempdir';

use Archive::Tar;
use VCS::Packager::RemoteFile;
use VCS::Packager::Repository;

enum 'Lang' => 'fr', 'en', 'es', 'cn', 'de', 'pt';

subtype 'Date'
    => as 'Str'
    => where { /^\d{8}$/ };

coerce 'Date'
    => from 'Num'
    => via { 
        my $time = $_;
        my @buf = localtime($time);
        return $buf[5]+1900 
             . sprintf('%02d', $buf[4] + 1) 
             . sprintf('%02d', $buf[3]);
    };

has lang => (
    is => 'rw',
    isa => 'Lang',
);

has date => (
    is => 'rw',
    isa => 'Date',
    required => 1,
    default => time(),
    coerce => 1,
);

has repository => (
    is => 'ro',
    required => 1,
    isa => 'VCS::Packager::Repository',
);

has archive => (
    is => 'rw',
    isa => 'Archive::Tar',
);

has branch => (
    is => 'rw', 
    isa => 'Str',
);

has name => (
    is => 'rw',
    isa => 'Str',
);

sub BUILD {
    my ($self) = @_;

    $self->branch( basename($self->repository->working_copy->path ));

    $self->name( $self->branch
               . '_'
               . $self->repository->revision
               . '_'
               . (defined $self->lang ? $self->lang.'_' : '') 
               . $self->date
    );

    print "-> Building ".$self->name."\n";
}

sub change_directory {
    my ($self, $dir) = @_;
    confess "Not a valid directory: $dir" 
        unless -d $dir;

    print "-> Entering $dir\n";
    chdir $dir or confess "unable to enter directory: $dir";
}

sub parse_deploy_file {
    my ($self, $file, $current_lang) = @_;
    my $deploy = {};

    print "-> looking for DEPLOY file : $file ";
    if (-f $file) {
        print "found.\n";
        my $fh;
        open $fh, '<', $file 
            or confess "unable to open $file";

        print "-> Reading $file file\n";
        while (<$fh>) {
            chomp;
            next if /^#/;

            if (/(\S+)\s*=\s*"(.+)"/) {
                my ($key, $val) = ($1, $2);
                if ($key =~ /^([^:]+):(\w\w)$/) {
                    # per-language key
                    my ($localized_key, $lang) = ($1, $2);
                    next if $lang ne $current_lang;
                    $key = $localized_key;
                }

                if ($val =~ /,/) {
                    my @list = split(',', $val);
                    $deploy->{$key} = \@list;
                }
                else {
                    $deploy->{$key} = $val;
                }
            }
        }
        close $fh;
    } else {
        print "(none found)\n";
    }

    return $deploy;
}

sub _add_dir_to_archive($$$);
sub _add_dir_to_archive($$$) {
    my ($self, $tar, $dir) = @_;
    confess "canot read dir $dir" unless -d $dir;
    
    # valid dir, add it to the archive
    $tar->add_files($dir);

    my $dir_fh;
    opendir $dir_fh, $dir or confess "unable to opendir $dir";
    while (my $f = readdir($dir_fh)) {
        next if $f eq '.' or $f eq '..';

        if (-d "$dir/$f") {
            $tar = $self->_add_dir_to_archive($tar, "$dir/$f") if -d "$dir/$f";
        }
        # is it a localized file?
        elsif ($f =~ /[\._]([a-z][a-z])\.(\w+)$/) {
            my ($lang, $ext) = ($1, $2);
            if (__PACKAGE__->is_lang($lang) && ($lang ne $self->lang)) {
                print "- ignoring unwanted localized file: $f ($lang)\n";
            }
            else {
                $tar->add_files("$dir/$f") if -e "$dir/$f";
            }
        }
        else {
            $tar->add_files("$dir/$f") if -e "$dir/$f";
        }
    }
    closedir $dir_fh;
    return $tar;
}

sub is_lang {
    my ($class, $lang) = @_;
    return $lang =~ /(fr|es|cn|de|en|pt)/;
}

sub build_archive {
    my ($self, $dest) = @_;
    my $pwd = File::Spec->rel2abs( $dest || File::Spec->curdir );
    
    # Export
    my $working_copy = $self->repository->working_copy;
    print "-> exporting working-copy: ".$working_copy->path."\n";
    $working_copy->export or confess "unable to export";
    my $export =
    File::Spec->rel2abs($working_copy->export_dir);
    
    $self->change_directory($export);

    # prebuild
    my $deploy = $self->parse_deploy_file( $self->branch."/DEPLOY", $self->lang );
    if ($deploy->{prebuild}) {
        # Entering the branch for prebuild commands sanity
        $self->change_directory( $self->branch );

        # the prebuild stuff, actually
        my $prebuild = $deploy->{prebuild};
        my $script   = File::Spec->rel2abs( $prebuild );
        $prebuild = $script if (-f $script && -x $script);

        print "-> running prebuild command: $prebuild\n";
        (system($prebuild) == 0) ||
           confess "Error during prebuild: $!";

        # back to the export path
        $self->change_directory( $export );
    }

    # Archive build
    print "-> Building archive:\n";
    my $tar = Archive::Tar->new;
    $self->archive( 
        $self->_add_dir_to_archive(
            $tar, 
            $self->branch) );

    my $path;
    if ($deploy->{archive_destination}) {
        $path = $deploy->{archive_destination}.'/'.$self->name.'.tar.gz';
    } else {
        $path = "$pwd/".$self->name.'.tar.gz';
    }

    $self->change_directory( $pwd );
    $self->archive->write($path, 1)
        or confess "unable to write archive: $!";
    
    print "$path\n";        
    return basename($path);
}

# deploy with rsync
sub deploy {
    my ($self, $archive, $dest, @ignore) = @_;
    my $pwd  = File::Spec->rel2abs(File::Spec->curdir);

    if (VCS::Packager::RemoteFile->is_remote($archive)) {
        $archive = VCS::Packager::RemoteFile->fetch_archive($archive);
    }

    # TODO the archive unpacking should be refactored in a class
    $archive = File::Spec->rel2abs($archive);
    confess "archive is not a valid file"
        unless -f $archive;
    # extract the archive in a temp dir
    my $tar = Archive::Tar->new;
    $tar->read($archive, 1) or confess "unable to read archive: $!";
    my $tempdir = tempdir();
    $self->change_directory( $tempdir );
    $tar->extract;
    opendir DIR, $tempdir;
    my $branch;
    while (my $f = readdir(DIR)) {
        next if $f eq '.' or $f eq '..';
        $branch = "$tempdir/$f" if -d "$tempdir/$f";
    }
    closedir DIR;
    
    my $lang = '';
    $lang = $1 if basename($archive) =~ /[^_]+_\d+_([a-z][a-z])_\d+\.tar\.gz/;

    # if a DEPLOY file is found in the branch, read it
    my $deploy = $self->parse_deploy_file("$branch/DEPLOY", $lang);

    unless (defined $dest) {
        if (defined $deploy->{destination}) {
            $dest = $deploy->{destination};
        } else {
            confess "destination should be provided either on the command ".
                "line or in the archive's DEPLOY file";
        }
    }

    $dest = File::Spec->rel2abs($dest);
    confess "destination ($dest) should be a valid directory"
        unless -d "$dest";
    
    @ignore = (@ignore, @{ $deploy->{ignore} }) if $deploy->{ignore};

    # FIXME: keep a list of ignored files so we still ignore them
    # when we rollback
    my $ignore_list = "--exclude=FILES ";
    $ignore_list .= "--exclude='$_' " for @ignore;

    # archive the destination (foo -> foo.YYYYMMAA_REV)
    my $new_dir = $self->historize($branch, $dest, @ignore);

    print "-> rsync -av --delete $ignore_list $new_dir/ $dest/ >$dest/FILES\n";
    system("rsync -av --delete $ignore_list $new_dir/ $dest/ >$dest/FILES");

    if ($deploy->{postdeploy}) {
        $self->change_directory( $dest );
        
        my $postdeploy = $deploy->{postdeploy};
        my $script   = File::Spec->rel2abs( $postdeploy );
        $postdeploy = $script if (-f $script && -x $script);

        print "-> running postdeploy command: $postdeploy\n";
        (system($postdeploy) == 0) ||
           confess "Error during postdeploy: $!";
    }

    $self->change_directory( $pwd );

    remove(\1, $tempdir);
}

sub rollback {
    my ($self, $dest, $version) = @_;
    my $pwd  = File::Spec->rel2abs(File::Spec->curdir);

    confess "Cannot rollback without a destination and a version"
        unless (defined $dest and defined $version);

    $dest    = File::Spec->rel2abs( $dest );
    $version = File::Spec->rel2abs( $version );

    confess "destination is not a valid directory ($dest)"
        unless -d $dest;
    
    confess "version is not a valid directory ($version)"
        unless -d $version;

    # FIXME: delete unneeded files while keeping ignored files ?
    my $rollback_cmd = "rsync -av $version/* $dest/ > ROLLBACK";
    print "-> $rollback_cmd\n";
    (system($rollback_cmd) == 0) or confess "Cannot rollback";

    my $fh;
    open $fh, '>', "$dest/ROLLBACK_VERSION";
    print $fh "$version\n";
    close $fh;
}

sub historize {
    my ($self, $source, $dest, @ignore) = @_;
    
    my $root = dirname($dest);

    mkdir "$root" unless -d "$root";
    mkdir "$root/releases" unless -d "$root/releases";

    my ($sec, $min, $hour, $day, $mon, $year) = localtime;
    $mon++;
    $year += 1900;
    $sec = sprintf('%02d', $sec);
    $min = sprintf('%02d', $min);
    $hour = sprintf('%02d', $hour);
    $mon = sprintf('%02d', $mon);
    $day = sprintf('%02d', $day);

    my $today = "${year}${mon}${day}";
    mkdir "$root/releases/$today" unless -d "$root/releases/$today";

    my $dest_histo = "$root/releases/$today/${hour}${min}${sec}";
    mkdir $dest_histo;
    print "Historizing $source into $dest_histo\n";

    my $ignore = "";
    $ignore   .= "--exclude='$_' " for @ignore;

    print "-> rsync $ignore -a $source/ $dest_histo/\n";
    (system("rsync $ignore -a $source/ $dest_histo/ ") == 0) ||
        confess "unable to historize $source to $dest_histo";

    return $dest_histo;
}

1;

