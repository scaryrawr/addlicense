#!/usr/bin/env perl
# Copyright (c) 2013, Michael Wallio
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions 
# are met:
#   - Redistributions of source code must retain the above copyright
#     notice, this list of conditions and the following disclaimer.
#   - Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in 
#     the documentation and/or other materials provided with the 
#     distribution.
#   - Neither the name of ScaryRawr nor the names of its 
#     contributors may be used to endorse or promote products derived 
#     from this software without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS 
# FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL 
# ScaryRawr BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT 
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF 
# USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, 
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT 
# OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF 
# SUCH DAMAGE.

use strict;
use warnings;

use Env;
use File::Basename;
use File::Copy;
use File::Spec;
use FindBin '$RealBin';
use Getopt::Long;

my $MAJOR = 0;
my $MINOR = 2;
my $PATCH = 0;

sub get_licenses
{
    my @licenses;
    my $license_dir = File::Spec->catfile("${RealBin}", "license_files");
    opendir(DIRHANDLE, $license_dir) or die $!;
    while (my $file = readdir(DIRHANDLE)) {
        my $file_path = File::Spec->catfile($license_dir, $file);
        next unless (-f "${file_path}" and $file =~ m/\.lic$/);
        $file =~ s/\.[^.]+$//;
        push(@licenses, $file);
    }

    closedir(DIRHANDLE);

    return @licenses;
}

sub print_version
{
    my $file_name = basename($0);
    print "${file_name} ${MAJOR}.${MINOR}.${PATCH}\n";
    print "Written by Michael Wallio.\n\n";
    print "Copyright (c) 2013 ScaryRawr.\n";
    print "This is free software; see the source for license. There is NO\n";
    print "warranty; not even for MERCHANTABILITY or FITNESS FOR A \n";
    print "PARTICULAR PURPOSE.\n";
    exit 0;
}

sub print_help
{
    my $file_name = basename($0);
    print "Usage: ${file_name} [OPTIONS]...\n";
    print " -f, --file <file>        specify the output file(s)\n";
    print " -l, --license <license>  specify the license to use\n";
    print " -n, --name <name>        specify the author's name\n";
    print " -o, --org <organization> specify the organization\n";
    print " -h, --help               display this help and exit\n";
    print " -v, --version            output version information and exit\n";
    exit 0;
}

sub print_licenses
{
    print "Available Licenses:\n";
    print "  $_\n" for (@_);
    exit 0;
}

sub contains
{
    my ($listref, $find) = @_;
    my @list = @$listref;
    my %is_list = ();
    $is_list{$_} = 1 for (@list);
    return $is_list{$find};
}

sub sub_special
{
    my ($line, $name, $org, $file) = @_;
    $file = basename($file);
    my @months = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
    my $month = $months[(localtime)[4]];
    my $day  = (localtime)[3];
    my $year = (localtime)[5] + 1900;

    $line =~ s/<year>/$year/g;
    $line =~ s/<month>/$month/g;
    $line =~ s/<day>/$day/g;
    $line =~ s/<name>/$name/g;
    $line =~ s/<organization>/$org/g;

    return $line;
}

sub get_comment
{
    if ($_[0] =~ m/\.(h|hpp|c|cc|cpp|cxx|C|H|java|js|cs)$/) {
        return "//";
    } elsif ($_[0] =~ m/\.(vb)$/) {
        return "'";
    }else {
        return "#";
    }
}

sub do_new_file
{
    my $file = $_[0];

    if ($file =~ m/\.(h|H|hpp|hxx)$/) {
        my $guard = uc($file);

        $guard =~ s/(-| |\.|\\|\/)/_/g;
        $guard .= "_";

        # include guard
        my $retval = "#ifndef ${guard}\n#define ${guard}\n\n";
        my $export = uc(basename($file));
        $export =~ s/(-| |\.)/_/g;
        $export =~ s/_[A-Z]+$//;

        # Export statements.
        $retval .= "#if defined(_WIN32) && !defined(__GNUC__)\n";
        $retval .= "#  ifdef ${export}_EXPORTS\n";
        $retval .= "#      define ${export}_EXPORT __declspec(dllexport)\n";
        $retval .= "#  else\n";
        $retval .= "#      define ${export}_EXPORT __declspec(dllimport)\n";
        $retval .= "#  endif\n";
        $retval .= "#else\n";
        $retval .= "#  if __GNUC__ > 4\n";
        $retval .= "#    define ${export}_EXPORT __attribute__ ((visibility (\"default\")))\n";
        $retval .= "#  else\n";
        $retval .= "#    define ${export}_EXPORT\n";
        $retval .= "#  endif\n";
        $retval .= "#endif\n\n";

        # C header specials.
        if ($file =~ m/\.h$/) {
            $retval .= "#ifdef __cplusplus\n";
            $retval .= "extern \"C\" {\n";
            $retval .= "#endif\n\n\n";
            $retval .= "#ifdef __cplusplus\n";
            $retval .= "}\n";
            $retval .= "#endif\n";
        }

        return $retval . "\n#endif  // ${guard}\n\n";
    }

}

my @files = ();
my @licenses = get_licenses();
my $get_version = '';
my $get_help = '';
my $license = '';
(my $name = `whoami`) =~ s/\s+$//g;
my $organization = $name;

GetOptions(
    'version'        => \$get_version, 
    'help'           => \$get_help,
    'license=s'      => \$license,
    'name=s'         => \$name,
    'organization=s' => \$organization,
    'file=s{,}'      => \@files);


print_version() if ($get_version);

print_help() if ($get_help);

print_licenses(@licenses) unless (contains(\@licenses, $license));

my $license_path = File::Spec->catfile($RealBin, "license_files", "${license}.lic");
open(LICENSEFILE, "<${license_path}") or die $!;

if (not @files) {
    while (<LICENSEFILE>) {
        print sub_special($_, $name, $organization, "stdout");
    }
} else {
    for (@files) {
        my $curfile = $_;
        if ( -r $curfile) {
            move($curfile, "${curfile}.orig");
        }

        my $comment = get_comment($curfile);

        open(OUTFILE, ">${curfile}") or die $!;

        # Move to the beginning of the license file.
        seek(LICENSEFILE, 0, 0);
        while (<LICENSEFILE>) {
            my $out_line = "${comment} " . sub_special($_, $name, $organization, $curfile);
            $out_line =~ s/\r\n/\n/g;
            $out_line =~ s/\s+\n/\n/g;
            print OUTFILE $out_line;
        }

        print OUTFILE "\n";

        if ( -r "${curfile}.orig") {
            open(ORIGFILE, "<${curfile}.orig") or die $!;
            my $skipLine = 0;
            my $canSkip = 1;
            my $commentPattern = qr/$comment/;
            while (<ORIGFILE>) {
                if (($canSkip) && ($_ =~ m/^${commentPattern}.*Copyright/)) {
                    $skipLine = 1;
                }

                if ($skipLine)
                {
                    unless (($_ =~ m/^$commentPattern/) || ($_ =~ m/^\s*$/)) {
                        $skipLine = 0;
                    }
                }

                unless ($skipLine)
                {
                    $_ =~ s/\r\n/\n/g;
                    $_ =~ s/\s+\n/\n/g;
                    print OUTFILE $_;
                }
            }

            close(ORIGFILE);
        } else {
            my $to_append = do_new_file($curfile);
            print OUTFILE $to_append;
        }

        close(OUTFILE);
    }
}

close(LICENSEFILE);

