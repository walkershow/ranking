#!/usr/bin/perl
# @Author: coldplay
# @Date:   2016-01-13 09:06:43
# @Last Modified by:   coldplay
# @Last Modified time: 2016-01-13 10:54:18

#!/usr/bin/perl
use strict;
use Tie::File;

sub init_ulimit
{
	my @lines;
	my $filename = shift;
	if (! -r -w $filename )
	{
		print "no read or write permission on $filename\n";
		return;
	}
	tie @lines,'Tie::File', $filename or die "hihi";

	my $last_index = $#lines;
	print $last_index;
	# print @lines[$last_index-1];
	if ( ! @lines[$last_index] =~ /ulimit -n 65536/ )
	{
		push @lines,"ulimit -n 65536";
	}
	else
	{
		print "ulimit -n 65536 is lie on last line\n";
	}
	untie @lines;
}

sub init_network_config
{
	my @lines;
	my $filename = shift;
	if (! -r -w $filename )
	{
		print "no read or write permission on $filename\n";
		return;
	}
	print $filename;
	tie @lines,'Tie::File', $filename or die;
	my $last_index = $#lines;
	print $last_index;
	# print @lines[$last_index-1];
	my $tip="=====optimise configures=====";
	my $append_flag = 1;
	for (@lines)
	{
		# print $_."\n";
		if (/$tip/)
		{
			print "hihi";
			$append_flag = 0;
			last;
		}
	}
	my $text;
	print $append_flag;
	if ($append_flag)
	{
		$text="#表示开启SYN Cookies。当出现SYN等待队列溢出时，启用cookies来处理，可防范少量SYN攻击，默认为0，表示关闭；\n".
			"net.ipv4.tcp_syncookies = 1\n".
			"#表示开启重用。允许将TIME-WAIT sockets重新用于新的TCP连接，默认为0，表示关闭；\n".
			"net.ipv4.tcp_tw_reuse = 1\n".
			"#修改系統默认的 TIMEOUT 时间\n".
			"net.ipv4.tcp_fin_timeout = 30n\n".
			"#表示当keepalive起用的时候，TCP发送keepalive消息的频度。缺省是2小时，改为20分钟。\n".
			"net.ipv4.tcp_keepalive_time = 1200\n".
			"#表示用于向外连接的端口范围。缺省情况下很小：32768到61000，改为10000到65000。（注意：这里不要将最低值设的太低，否则可能会占用掉正常的端口！）\n".
			"net.ipv4.ip_local_port_range = 10000 65000\n".
			"#表示SYN队列的长度，默认为1024，加大队列长度为8192，可以容纳更多等待连接的网络连接数。\n".
			"net.ipv4.tcp_max_syn_backlog = 8192\n".
			"#表示系统同时保持TIME_WAIT的最大数量，如果超过这个数字，TIME_WAIT将立刻被清除并打印警告信息。默认为180000，改为5000。\n".
			"net.ipv4.tcp_max_tw_buckets = 5000\n";
		push @lines,$tip;
		push @lines,$text;

	}

	untie @lines;
}

init_ulimit("/root/pp.bak");
init_network_config("root/pn.bak");

