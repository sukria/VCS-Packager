package VCS::Packager::RemoteFile;

use Carp 'confess';
use File::Temp 'tempdir';
use LWP::UserAgent;

sub is_remote ($)
{
    my ($class, $location) = @_;
    return $location =~ /^http:/;
}

sub fetch_archive ($)
{
    my ($class, $archive) = @_;

    my $ua = new LWP::UserAgent();
    my $req = new HTTP::Request(GET => $archive);
    my $res = $ua->request($req);

    my $tempdir = tempdir();
    my $filename = $archive;
    $filename =~s/.+\/(.*\.tar\.gz)/$1/g;

    my $content_type = $res->header("Content-Type");
    if ($content_type =~ m,^application/x-archive-list,) {
        my @versions = split("\n", $res->content);
        my $latest_version = pop @versions;
        confess "No archive in this repository" unless defined $latest_version;

        $latest_version =~ s/^(\S+).*/$1/g;
        $filename = $tempdir."/".$latest_version;
        print "Got archive list, choosing latest version: $latest_version\n";
        $req = new HTTP::Request(GET => $archive.'/'.$latest_version);
        $res = $ua->request($req);
        $content_type = $res->header("Content-Type");
    }

    confess "Could not get remote location ".$req->uri if (!$res->is_success);

    if ($content_type =~ m,^(application/x-gzip|application/x-tar),) {
        open FH, '>', $filename;
        binmode FH;
        print FH $res->content;
        close FH;
        #FIXME: keep a record that this file was downloaded
        # and should be cleaned up later
    } else {
        confess "Got unknown content type: $content_type";
    }

    return $filename;
}

1;
