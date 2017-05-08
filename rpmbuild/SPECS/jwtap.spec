Summary:            Nginx MRuby
Name: jwtap
Version: 1.0.0
Release: %{?BUILD_NUMBER}
License: GPL
URL: https://github.com/matsumoto-r/ngx_mruby/releases

%description
A Fast and Memory-Efficient Web Server Extension Mechanism Using Scripting Language mruby for nginx

Requires(pre):	    /usr/sbin/useradd, /usr/bin/getent
Requires(postun):   /usr/sbin/userdel
Requires(post):     /usr/bin/systemctl

%pre
/usr/bin/getent group jwtap || /usr/sbin/groupadd -r jwtap --gid 420
/usr/bin/getent passwd jwtap || /usr/sbin/useradd -r -d /opt/jwtap/ -s /sbin/nologin --uid 420 jwtap -g jwtap

%post
/usr/bin/systemctl daemon-reload

%postun
# /usr/sbin/userdel jwtap

%build
rm -fr vendor/ngx_mruby
mkdir -p vendor/ngx_mruby
git clone https://github.com/matsumoto-r/ngx_mruby.git vendor/ngx_mruby
cd vendor/ngx_mruby

# Add mruby-jwt
sed -i.bak "s/^end$/  conf.gem :github => 'prevs-io\/mruby-jwt'\\
  conf.gem :github => 'mattn\/mruby-base64'\\
  conf.gem :github => 'mattn\/mruby-http'\\
end/" build_config.rb

NGINX_CONFIG_OPT_ENV='--with-http_ssl_module --prefix=/opt/jwtap' sh build.sh

%install
# rm -rf %{buildroot}
cd vendor/ngx_mruby
%make_install
mkdir -p  %{buildroot}/opt/jwtap/lib/jwtap
mkdir -p  %{buildroot}/usr/lib/systemd/system/

cp ../../../jwtap/lib/jwtap/access_handler.rb %{buildroot}/opt/jwtap/lib/jwtap/
cp ../../../SOURCES/jwtap.service %{buildroot}/usr/lib/systemd/system/
cp -f ../../../SOURCES/nginx.conf %{buildroot}/opt/jwtap/conf/nginx.conf

%files
%attr( - , jwtap, jwtap ) /opt/jwtap/
%config /opt/jwtap/conf/nginx.conf
/usr/lib/systemd/system/jwtap.service

%changelog
