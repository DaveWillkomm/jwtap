Name:          jwtap
Version:       1.1.0
Release:       %{?release_number}%{!?release_number:1}%{?dist}
Summary:       JSON Web Token Authentication Proxy
License:       MIT
URL:           https://github.com/DaveWillkomm/%{name}
%global        ngx_mruby_version 1.19.4
Source0:       https://github.com/matsumotory/ngx_mruby/archive/v%{ngx_mruby_version}.tar.gz#/ngx_mruby-%{ngx_mruby_version}.tar.gz
Source1:       jwtap
Source2:       jwtap.service
BuildRequires: bison git openssl-devel ruby rubygem-rake wget
Requires(pre): shadow-utils


%global builddir_jwtap %{_builddir}/%{name}-%{version}
%global builddir_ngx_mruby %{builddir_jwtap}/ngx_mruby-%{ngx_mruby_version}
%global debug_package %{nil}


%description
JSON Web Token Authentication Proxy (jwtap, pronounced "jot app") is an HTTP reverse proxy that provides authentication
services, in concert with an external user authentication service, to both HTTP web applications and APIs. Jwtap is
implemented as a Ruby script that runs in the context of Nginx + ngx_mruby + mruby-jwt.


%prep
%setup -T -c
cp -r %{_topdir}/../lib %{builddir_jwtap}
%setup -T -D -q -a 0
cd %{builddir_ngx_mruby}
%{_topdir}/../bin/add_gems.sh


%build
cd %{builddir_ngx_mruby}
options="
  --build=%{name}
  --conf-path=%{_sysconfdir}/%{name}/%{name}.conf
  --error-log-path=%{_localstatedir}/log/%{name}/error.log
  --group=%{name}
  --http-log-path=%{_localstatedir}/log/%{name}/access.log
  --pid-path=/run/%{name}.pid
  --prefix=/opt/%{name}
  --sbin-path=sbin/%{name}
  --user=%{name}
  --with-http_ssl_module"
NGINX_CONFIG_OPT_ENV="$(echo ${options})" sh build.sh


%install
cd %{builddir_ngx_mruby}
%make_install

install -d %{buildroot}%{_sysconfdir}/logrotate.d
install -d %{buildroot}%{_unitdir}
cp -r %{builddir_jwtap}/lib %{buildroot}/opt/%{name}
install %{SOURCE1} %{buildroot}%{_sysconfdir}/logrotate.d
install %{SOURCE2} %{buildroot}%{_unitdir}


%files
%attr(-, %{name}, %{name}) /opt/%{name}
%config %{_sysconfdir}/%{name}/*
%config %{_sysconfdir}/logrotate.d/%{name}
%{_localstatedir}/log/%{name}
%{_unitdir}/%{name}.service
/opt/%{name}/sbin/%{name}


%pre
getent group %{name} > /dev/null || groupadd --system --gid %{uid} %{name}
getent passwd %{name} > /dev/null || \
  useradd --system --uid %{uid} --gid %{name} --home-dir /opt/apps/%{name} --shell /sbin/nologin %{name}


%post
/usr/bin/systemctl daemon-reload

%changelog
