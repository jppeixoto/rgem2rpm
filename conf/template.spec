%define __os_install_post    \
	/usr/lib/rpm/brp-compress \
	%{!?__debug_package:/usr/lib/rpm/brp-strip %{__strip}} \
	/usr/lib/rpm/brp-strip-static-archive %{__strip} \
	/usr/lib/rpm/brp-strip-comment-note %{__strip} %{__objdump} \
%{nil}

%define distnum %{expand:%%(/usr/lib/rpm/redhat/dist.sh --distnum)}
%define disttype %{expand:%%(/usr/lib/rpm/redhat/dist.sh --disttype)}
%define name <%=name%>
%define version <%=version%>
%define release <%=release%>.%{disttype}%{distnum}

Name: %{name}
Version: %{version}
Release: %{release}
License: <%=license%>
Summary: <%=summary%>
Group: <%=group%>
Source: %{name}-%{version}.tar.gz
Prefix: <%=installdir%>
BuildRoot: %(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)
<%="BuildArch: noarch" unless buildarch.nil?%>
<%="Requires: #{requires}" unless requires == ""%>
<%="Provides: #{provides}" unless provides == ""%>

%description
<%=description%>

%prep
%setup -q

%install
<%=installlist%>

%files
<%=filelist%>

%changelog
<%=changelog%>