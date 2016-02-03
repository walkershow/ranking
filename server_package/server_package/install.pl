#!/usr/bin/perl
# @Author: coldplay
# @Date:   2016-01-13 11:12:47
# @Last Modified by:   coldplay
# @Last Modified time: 2016-01-13 16:45:00

#!/usr/bin/perl
use Cwd;
use strict;
our $cur_pwd = getcwd;
print cur_pwd;
sub install_drizzle
{
	print "install drizzle ...\n";
	my $gz_name = "drizzle7-2011.07.21.tar.gz";
	if(! -e $gz_name)
	{
		print "$gz_name not existn";
		return 1;
	}
	my $ret = system("tar xzvf $gz_name>>/dev/null");
	print $ret;
	if ($ret==0) {$ret = chdir('drizzle7-2011.07.21');}
	if ($ret==1) {$ret = system('./configure --without-server>>/dev/null');}
	if ($ret==0) {$ret = system('make libdrizzle-1.0>>/dev/null');}
	if ($ret==0)
	{
		$ret = `make install-libdrizzle-1.0`;
		print "========================\n";
		# print $ret;
		if ($ret =~ /Libraries have been installed in:/)
		{
			print "drizzle install ok\n";
			chdir(cur_pwd);
			return 0;
		}
		print "========================\n";
		return 1;

	}
	chdir(cur_pwd);
}

sub install_openresty_pre()
{
	print "install openresty pre ...\n";
	my $readline_devel_install = `yum -y install readline-devel`;
	if ($readline_devel_install =~/Error|Errno/)
	{
		print "install readline-devel failed";
		return 1;
	}
	my $pcre_devel_install = `yum -y install  pcre-devel `;
	if ($pcre_devel_install =~/Error|Errno/)
	{
		print "install pcre-devel failed";
		return 1;
	}
	my $openssl_devel_install = `yum -y install openssl-devel `;
	if ($openssl_devel_install =~/Error|Errno/)
	{
		print "install openssl-devel failed";
		return 1;
	}
	my $gcc_install = `yum -y install gcc`;
	if ($gcc_install =~/Error|Errno/)
	{
		print "install gcc failed";
		return 1;
	}
	return 0;

}

sub install_openresty()
{
	print "install openresty ...\n";
	my $gz_name = <'ngx_openresty-*.tar.gz'>;
	print $gz_name;
	if(! -e $gz_name)
	{
		print "$gz_name not exist";
		return 1;
	}
	my $ret = system("tar xzvf $gz_name>>/dev/null");
	# print $ret."\n";
	my @ngx_dirname=<'ngx_openresty-*'>;
	my $dir;
	for (@ngx_dirname)
	{
		if (-d)
		{
			$dir=$_;
			last;
		}
	}
	print $dir."\n";
	if ($ret==0) {$ret = chdir($dir);}
	print $ret."\n";
	if ($ret==1) {$ret = system('./configure --prefix=/opt/openresty --with-pcre-jit --with-ipv6 --with-http_iconv_module --with-http_drizzle_module >>/dev/null');}
    if ($ret==0) {$ret = system('make>>/dev/null');}
	if ($ret==0) {$ret = system('make install>>/dev/null');}
	print $ret."\n";
	if ($ret==0)
	{
		$ret = system('tar xvf work.tar');
		if(!$ret)
		{
			$ret = system('rm -rf /opt/openresty/work');
			$ret = system('mv ./work /opt/openresty/');
		}
	}
	if($ret==0) {	print "install openresty ok!\n";}
	else {print "install openresty failed!\n"	}
	chdir(cur_pwd);
}


if(install_openresty_pre())
{
	exit(1);
}
if (install_drizzle())
{
	exit(1);
}
install_openresty()

