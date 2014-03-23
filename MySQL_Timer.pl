#!/usr/bin/perl
# MySQL_Timer
# By Chen.Zhidong
# njutczd+gmail.com

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
use strict;
use threads;
use DBI;
use Time::HiRes 'time';
use Getopt::Long;

my $version = "1.0";

my %opt = (
	"threads"=>0,
	"host"=>"localhost",
	"port"=>3306,
	"user"=>"",
	"pass"=>"",
	"database"=>"",
	"executeS"=>"",
	"execute"=>"",
);

GetOptions(\%opt,
	'threads=i',
	'host=s',
	'port=i',
	'user=s',
	'pass=s',
	'database=s',
	'executeS=s',
	'execute=s',
	'help',
) || die usage();

sub usage {
	print "\n".
		"   MySQL_Timer $version\n".
		"   A perl script to test the time usage of MySQL queries in a certain amount of concurrent.\n".
		"\n".
		"   Options:\n".
		"      --threads <threads>  Threads to use while doing test.\n".
		"      --host <hostname>    Connect to a remote host to perform tests (default: localhost)\n".
		"      --port <port>        Port to use for connection (default: 3306)\n".
		"      --user <username>    Username to use for authentication\n".
		"      --pass <password>    Password to use for authentication\n".
		"      --database <dbname>  Database to to the test\n".
		"      --executeS \"<sql>\" SQL string to do select work\n".
		"      --execute \"<sql>\"  SQL string to do insert|update|delete work\n".
		"      --help               Print help message\n".
		"\n".
		"   Example:\n".
		"      $0 --threads 30 --user root --pass 123 --database test --executeS \"select * from table limit 20\"\n".
		"      $0 --threads 30 --user root --pass 123 --database test --exeucte \"insert into table (a,b) values('a','b')\"\n".
		"\n";
	exit;
}

sub mysql_executeS {
	my $start=time;
	my $db=DBI->connect("DBI:mysql:database=$opt{'database'};host=$opt{'host'}",$opt{'user'},$opt{'pass'},{'RaiseError'=>1}) or die $db::errstr;
	my $select=$db->prepare($opt{'executeS'});
	$select->execute() or die $db::errstr;
	$select->fetchall_arrayref;
	$select->finish();
	printf("executeS($_[0]) lasts: %.5f seconds.\n",time-$start);
}

sub mysql_execute {
	my $start=time;
	my $db=DBI->connect("DBI:mysql:database=$opt{database};host=$opt{'host'}",$opt{'user'},$opt{'pass'},{'RaiseError'=>1}) || die $db::errstr;
	$db->do($opt{'execute'}) or die $db::errstr;
	printf("exeucte($_[0]) lasts: %.5f seconds.\n",time-$start);
}

if(defined $opt{'help'} && $opt{'help'} == 1) { usage(); }

if($opt{'threads'}==0 || $opt{'user'} eq "" || $opt{'pass'} eq "" || $opt{'database'} eq "" || ($opt{'executeS'} eq "" && $opt{'execute'} eq ""))
{
	usage();
}
else
{
	print "create $opt{'threads'} threads\nwaiting for result...\n";
	my @threads;
	if($opt{'executeS'} ne "")
	{
		for(my $i=1;$i<=$opt{'threads'};$i++)
		{
			push(@threads,threads->new(\&mysql_executeS,$i));
		}
	}
	elsif($opt{'execute'} ne "")
	{
		for(my $i=1;$i<=$opt{'threads'};$i++)
		{
			push(@threads,threads->new(\&mysql_execute,$i));
		}
	}
	else
	{
		usage();
	}
	foreach(@threads)
	{
		$_->join;
	}
	print "done.\n";
}
