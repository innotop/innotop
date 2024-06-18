#
# spec file for package innotop
#
Name:      innotop
Summary:   A MySQL and InnoDB monitor program.
Version:   1.15.1
Release:   1%{?dist}
Vendor:    Baron Schwartz <baron@percona.com>
Packager:  Frederic Descamps <lefred@percona.com>
License:   GPL/Artistic
Group:     System/Monitoring
URL:       http://innotop.googlecode.com/
Buildroot: %{_tmppath}/%{name}-%{version}-%(id -u -n)
Buildarch: noarch
Source:    http://%{name}.googlecode.com/files/%{name}-%{version}.tar.gz
BuildRequires: perl-ExtUtils-MakeMaker, perl-Test-Simple, make
BuildRequires: perl-DBI, perl-DBD-MySQL, perl-TermReadKey
Requires: perl-DBI, perl-DBD-MySQL, perl-TermReadKey
%if 0%{?rhel} > 4
BuildRequires:  perl-Time-HiRes
Requires:	perl-Time-HiRes
%endif


%define filelist %{name}-%{version}-filelist
%{!?maketest: %define maketest 1}

%description
MySQL and InnoDB transaction/status monitor.  Like 'top' for MySQL.  Displays
queries, InnoDB transactions, lock waits, deadlocks, foreign key errors, open
tables, replication status, buffer information, row operations, logs, I/O
operations, load graph, and more.  You can monitor many servers at once with
innotop.

%prep
%setup

%build
grep -rsl '^#!.*perl' . |
grep -v '.bak$' |xargs --no-run-if-empty \
%__perl -MExtUtils::MakeMaker -e 'MY->fixin(@ARGV)'
CFLAGS="$RPM_OPT_FLAGS"
%{__perl} Makefile.PL `%{__perl} -MExtUtils::MakeMaker -e ' print qq|PREFIX=%{buildroot}%{_prefix}| if \$ExtUtils::MakeMaker::VERSION =~ /5\.9[1-6]|6\.0[0-5]/ '`
%{__make} 
%if %maketest
%{__make} test
%endif

%install
[ "%{buildroot}" != "/" ] && rm -rf %{buildroot}

%{makeinstall} `%{__perl} -MExtUtils::MakeMaker -e ' print \$ExtUtils::MakeMaker::VERSION <= 6.05 ? qq|PREFIX=%{buildroot}%{_prefix}| : qq|DESTDIR=%{buildroot}| '`

cmd=/usr/share/spec-helper/compress_files
[ -x $cmd ] || cmd=/usr/lib/rpm/brp-compress
[ -x $cmd ] && $cmd

# SuSE Linux

if [ -e /etc/SuSE-release -o -e /etc/UnitedLinux-release ]
then
    %{__mkdir_p} %{buildroot}/var/adm/perl-modules
    fname=`find %{buildroot} -name "perllocal.pod" | head -1`
    if [ -f "$fname" ] ; then                             \
        %{__cat} `find %{buildroot} -name "perllocal.pod"`  \
        | %{__sed} -e s+%{buildroot}++g                     \
        < /dev/null                                         \
        > %{buildroot}/var/adm/perl-modules/%{name} ;      \
    fi
fi

# remove special files
find %{buildroot} -name "perllocal.pod" \
    -o -name ".packlist"                \
    -o -name "*.bs"                     \
    |xargs -i rm -f {}

# no empty directories
find %{buildroot}%{_prefix}             \
    -type d -depth                      \
    -exec rmdir {} \; 2>/dev/null

%{__perl} -MFile::Find -le '
    find({ wanted => \&wanted, no_chdir => 1}, "%{buildroot}");
    print "%doc  Changelog INSTALL";
    for my $x (sort @dirs, @files) {
        push @ret, $x unless indirs($x);
        }
    print join "\n", sort @ret;

    sub wanted {
        return if /auto$/;

        local $_ = $File::Find::name;
        my $f = $_; s|^\Q%{buildroot}\E||;
        return unless length;
        return $files[@files] = $_ if -f $f;

        $d = $_;
        /\Q$d\E/ && return for reverse sort @INC;
        $d =~ /\Q$_\E/ && return
            for qw|/etc %_prefix/man %_prefix/bin %_prefix/share|;

        $dirs[@dirs] = $_;
        }

    sub indirs {
        my $x = shift;
        $x =~ /^\Q$_\E\// && $x ne $_ && return 1 for @dirs;
        }
    ' > %filelist

[ -z %filelist ] && {
    echo "ERROR: empty %files listing"
    exit -1
    }

%clean
[ "%{buildroot}" != "/" ] && rm -rf %{buildroot}

%files -f %filelist
%defattr(-,root,root)

%changelog
* Tue Aug 22 2023 yoku0825 <yoku0825@gmail.com> - 1.14.0-1
 - Support MySQL 8.1.0

* Wed Apr 07 2021 Frederic Descamps <lefred@lefred.be> - 1.13.0-1
 - New version

* Fri Jan 20 2017 Frederic Descamps <lefred@lefred.be> - 1.11.4-1
 - Package for github new tag 1.11.4

* Fri Jul 12 2013 Frederic Descamps <lefred@lefred.be> - 1.9.1-1
 - Package for svn source code revision 113

* Thu Jul 11 2013 Frederic Descamps <lefred@lefred.be> - 1.9.0-3
 - Add MySQL 5.6 support (patch https://code.google.com/p/innotop/issues/detail?id=83)
 - Add extra build requirement packages

* Fri Sep 14 2012 Frederic Descamps <lefred@lefred.be> - 1.9.0-2
 - fix perl-TermReadKey requirement - typo

* Fri Sep 07 2012 Frederic Descamps <lefred@lefred.be>
 - add build requirements

* Mon Jan 08 2007 Lenz Grimmer <lenz@grimmer.com>
 - Updated the spec file to reflect the changes in 1.0, fixed the URLs
 - removed the reference to innotop.html, added INSTALL to the docs instead

* Thu Nov 16 2006 Lenz Grimmer <lenz@grimmer.com>
 - Initial spec file for version 0.1.160
   (with some help from cpan2rpm - http://perl.arix.com/)
