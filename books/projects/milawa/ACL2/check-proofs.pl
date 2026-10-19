#!/usr/bin/env perl

# check-proofs.pl -- consistency and staleness checks for ../Proofs.
#
# Milawa's ACL2 build generates proof files (../Proofs/<libdir>/<book>/...) and
# .events manifests (../Proofs/*.events) as side effects of provisionally
# certifying books.  Nothing in make knows about those files, so a mistake in
# the filename generator, an interrupted build, or a stale certificate can
# leave an .events file that names a proof which was never written, or a proof
# that predates the image/source it was supposedly derived from.
#
# This script checks, for every file in ../Proofs:
#
#   * every "Proofs/..." path named by an .events file exists, and has the
#     per-book layout Proofs/<libdir>/<book>/<name>.{proof,proofs};
#   * every proof and .events file is newer than the book source (.lisp) and
#     the ACL2 image that produced it;
#   * every .mpcert checksum still matches its book source (ACL2's check-sum,
#     as written by interface/pcert.lisp);
#   * every (%save-events "x.events") producer has its .events file when the
#     producer has been provisionally certified;
#   * proofs that no .events file references are reported as warnings.
#
# Note on .mpcert timestamps: PCERT writes the proof files while replaying the
# book and writes the .mpcert afterwards, so a fresh proof is normally a few
# milliseconds OLDER than its own .mpcert.  We therefore compare proofs against
# the inputs (book source and image), not against the .mpcert mtime.
#
# Exit status is nonzero if any error is found.  With --warn, findings are
# reported but the exit status is zero.  Run from the ACL2/ directory (the
# Makefile's check-proofs target does this for you).

use strict;
use warnings;

use File::Basename qw(basename dirname);
use File::Find ();
use File::Spec;
use Getopt::Long;

my $warn_only = 0;
GetOptions('warn' => \$warn_only)
    or die "Usage: $0 [--warn]\n";

my $here   = File::Spec->rel2abs(dirname($0));
my $root   = File::Spec->catdir($here, File::Spec->updir);
my $proofs = File::Spec->catdir($root, 'Proofs');
my $images = File::Spec->catdir($here, 'acl2-images');

my @errors   = ();
my @warnings = ();

sub error   { push @errors,   sprintf(shift, @_); }
sub warning { push @warnings, sprintf(shift, @_); }

sub mtime {
    my $path = shift;
    my @st = stat($path);
    return @st ? $st[9] : undef;
}

# True if $target is older than $source.  Compare whole seconds so that a
# target written in the same second as its source is not flagged.
sub stale {
    my ($target, $source) = @_;
    my $t = mtime($target);
    my $s = mtime($source);
    return 0 if (!defined $t || !defined $s);
    return int($s) > int($t);
}

# ---------------------------------------------------------------------------
# Index the books by "<libdir>/<stem>", the layout that generate-filename
# uses.  Milawa's own books live under bootstrap/; other directories (levels/,
# interface/, ...) are included too, but bootstrap/ wins on a name collision
# (e.g. bootstrap/utilities/top.lisp vs utilities/top.lisp).

my %book;      # "libdir/stem" -> path to .lisp

File::Find::find(
    {   no_chdir => 1,
        wanted   => sub {
            my $path = $File::Find::name;
            return if $path =~ m{/(?:Proofs|acl2-images|autodoc|\.sys|\.git)(?:/|$)};
            return unless $path =~ /\.lisp\z/;
            my ($libdir, $stem) = $path =~ m{/([^/]+)/([^/]+)\.lisp\z};
            return unless defined $libdir;
            my $key = "$libdir/$stem";
            my $is_bootstrap = ($path =~ m{/bootstrap/}) ? 1 : 0;
            if (exists $book{$key}) {
                my $old_bootstrap = ($book{$key} =~ m{/bootstrap/}) ? 1 : 0;
                return if (!$is_bootstrap || $old_bootstrap);
            }
            $book{$key} = $path;
        }
    },
    $here);

# ---------------------------------------------------------------------------
# Find the book that writes each .events file.

my %events_book;    # "utilities.events" -> path to producing .lisp

for my $path (sort values %book) {
    open(my $fh, '<', $path) or do { warning("cannot read %s: %s", $path, $!); next; };
    local $/ = undef;
    my $text = <$fh>;
    close($fh);
    while ($text =~ /\(%save-events\s+"([^"]+)"\)/g) {
        my $name = $1;
        if (exists $events_book{$name} && $events_book{$name} ne $path) {
            warning("both %s and %s write Proofs/%s", $events_book{$name}, $path, $name);
        }
        $events_book{$name} = $path;
    }
}

# ---------------------------------------------------------------------------
# The ACL2 image a book is certified with: "<book>.image" next to the book if
# present, else "cert.image" in its directory (see pcert-util.pl).  Return the
# newest of acl2-images/<name> and its companion data file, or undef.

sub image_for_book {
    my $bookfile = shift;
    my $dir = dirname($bookfile);
    my $stem = basename($bookfile, '.lisp');
    my $name;
    for my $candidate ("$dir/$stem.image", "$dir/cert.image") {
        next unless -f $candidate;
        open(my $fh, '<', $candidate) or next;
        my $line = <$fh>;
        close($fh);
        next unless defined $line;
        $line =~ s/^\s+//;
        $line =~ s/\s+$//;
        if ($line =~ /^[A-Za-z0-9_\-.\/]+$/) {
            $name = $line;
            last;
        }
    }
    return undef unless defined $name;
    my $base = File::Spec->catfile($images, $name);
    my @paths = grep { -e $_ } ($base, glob("$base.*"));
    return undef unless @paths;
    my $newest = $paths[0];
    for my $p (@paths) {
        $newest = $p if mtime($p) > mtime($newest);
    }
    return $newest;
}

# ---------------------------------------------------------------------------
# ACL2's file checksum, as computed by check-sum in basis-b.lisp and recorded
# in .mpcert by interface/pcert.lisp.

my $CHECK_SUM_MAX  = 268435399;    # first prime below 2^28
my $CHECK_LEN_MAX  = 2097143;      # first prime below 2^21

sub acl2_check_sum {
    my $file = shift;
    my $len = $CHECK_LEN_MAX - 1;
    my $sum = 0;
    open(my $fh, '<:raw', $file) or return undef;
    while (read($fh, my $buf, 65536)) {
        for my $c (unpack('C*', $buf)) {
            $len = ($len == 0) ? ($CHECK_LEN_MAX - 1) : ($len - 1);
            my $inc = ($c == 0 || $c == 128) ? 1 : (($c > 127) ? $c - 128 : $c);
            $inc = 9 if $inc == 0;    # tab
            $sum = ($sum + $inc * $len) % $CHECK_SUM_MAX;
        }
    }
    close($fh);
    return $sum;
}

# ---------------------------------------------------------------------------
# Check every .mpcert against the source it certified.

my @mpcerts;
File::Find::find(
    {   no_chdir => 1,
        wanted   => sub {
            my $path = $File::Find::name;
            return if $path =~ m{/(?:Proofs|acl2-images|\.git)(?:/|$)};
            push @mpcerts, $path if $path =~ /\.mpcert\z/;
        }
    },
    $here);

for my $mpcert (sort @mpcerts) {
    open(my $fh, '<', $mpcert) or do { error("cannot read %s: %s", $mpcert, $!); next; };
    local $/ = undef;
    my $text = <$fh>;
    close($fh);
    my ($source, $want) = $text =~ /"([^"]+)"\s+check-sum\s+(\d+)/;
    if (!defined $want) {
        warning("%s does not contain a check-sum line", $mpcert);
        next;
    }
    my $sourcefile = File::Spec->file_name_is_absolute($source)
        ? $source
        : File::Spec->catfile(dirname($mpcert), $source);
    my $got = acl2_check_sum($sourcefile);
    if (!defined $got) {
        error("%s names %s, which cannot be read", $mpcert, $sourcefile);
    }
    elsif ($got != $want) {
        error("%s is stale: check-sum of %s is %d, not %d; re-run make",
              $mpcert, $sourcefile, $got, $want);
    }
    my $image = image_for_book($sourcefile);
    if (defined $image && stale($mpcert, $image)) {
        error("%s is older than the image %s; re-run make", $mpcert, $image);
    }
}

# ---------------------------------------------------------------------------
# Check the .events manifests.

my %referenced;
my %checked_proof;
my %libdir_covered;    # libdir -> some .events file refers to it

sub check_against_inputs {
    my ($file, $source, $what) = @_;
    my $image = image_for_book($source);
    if (stale($file, $source)) {
        error("%s is older than its source %s; re-run the ACL2 build", $what, $source);
    }
    if (defined $image && stale($file, $image)) {
        error("%s is older than the image %s used to make it; re-run the ACL2 build",
              $what, $image);
    }
}

my @events = sort glob(File::Spec->catfile($proofs, '*.events'));
my %events_seen = map { basename($_) => 1 } @events;

for my $events (@events) {
    my $name = basename($events);
    my $producer = $events_book{$name};
    if (!defined $producer) {
        warning("%s has no (%%save-events \"%s\") producer in the sources",
                $events, $name);
    }
    else {
        check_against_inputs($events, $producer, $events);
    }

    open(my $fh, '<', $events) or do { error("cannot read %s: %s", $events, $!); next; };
    local $/ = undef;
    my $text = <$fh>;
    close($fh);

    while ($text =~ /"(Proofs\/[^"\n]*\.proofs?)"/g) {
        my $rel = $1;
        my $path = File::Spec->catfile($root, split(m{/}, $rel));
        $referenced{$path} = 1;

        if (!-f $path) {
            error("%s names %s, which does not exist", $name, $rel);
            next;
        }

        my ($rel_libdir) = $rel =~ m{^Proofs/([^/]+)/};
        $libdir_covered{$rel_libdir} = 1 if defined $rel_libdir;

        my ($libdir, $bookname) = $rel =~ m{^Proofs/([^/]+)/([^/]+)/[^/]+$};
        if (!defined $bookname) {
            error("%s names %s, which lacks the Proofs/<libdir>/<book>/ layout",
                  $name, $rel);
            next;
        }
        my $key = "$libdir/$bookname";
        my $source = $book{$key};
        if (!defined $source) {
            error("%s names %s, but there is no source book for %s",
                  $name, $rel, $key);
            next;
        }
        if (!$checked_proof{$path}) {
            $checked_proof{$path} = 1;
            check_against_inputs($path, $source, $rel);
        }
    }
}

# ---------------------------------------------------------------------------
# Require an .events file for every producer whose book has been certified,
# and look for proof files that no manifest mentions.

for my $name (sort keys %events_book) {
    next if $events_seen{$name};
    my $producer = $events_book{$name};
    (my $mpcert = $producer) =~ s/\.lisp\z/.mpcert/;
    if (-f $mpcert) {
        error("%s was built but %s is missing; re-run the ACL2 build",
              $mpcert, File::Spec->catfile('Proofs', $name));
    }
}

my @all_proofs;
File::Find::find(
    {   no_chdir => 1,
        wanted   => sub {
            push @all_proofs, $File::Find::name
                if $File::Find::name =~ /\.proofs?\z/;
        }
    },
    $proofs);

for my $proof (sort @all_proofs) {
    next if $checked_proof{$proof};
    my ($libdir, $bookname) = $proof =~ m{/Proofs/([^/]+)/([^/]+)/[^/]+$};
    if (!defined $bookname) {
        warning("%s is not in the Proofs/<libdir>/<book>/ layout", $proof);
        next;
    }
    my $source = $book{"$libdir/$bookname"};
    if (!defined $source) {
        warning("%s has no source book (bootstrap/*/%s/%s.lisp)",
                $proof, $libdir, $bookname);
        next;
    }
    $checked_proof{$proof} = 1;
    check_against_inputs($proof, $source, $proof);
    if ($libdir_covered{$libdir} && !$referenced{$proof}) {
        warning("%s is not referenced by any .events file", $proof);
    }
}

# ---------------------------------------------------------------------------
# Report.

for my $w (@warnings) {
    print "check-proofs: warning: $w\n";
}
for my $e (@errors) {
    print "check-proofs: error: $e\n";
}

if (@errors) {
    print "\ncheck-proofs: ", scalar(@errors), " error(s)";
    print ", ", scalar(@warnings), " warning(s)" if @warnings;
    print ".\n";
    if ($warn_only) {
        print "check-proofs: --warn given, so exiting successfully anyway.\n";
        exit 0;
    }
    print "check-proofs: run 'make clean' (or delete the affected .mpcert\n";
    print "              files and ../Proofs) and rebuild.\n";
    exit 1;
}

print "check-proofs: ok (", scalar(@all_proofs), " proof file(s)";
print ", ", scalar(@events), " events file(s)" if @events;
print ")\n";
exit 0;
