package Cloudstack::Command::VM;
use Cloudstack -command;
use Log::Log4perl qw/:easy/;

my $logger;

sub opt_spec{
	return(
		["id|i=s", "vm id"],
		["cfgfile|f=s", "config file location"],
		["account|a=s", "account id"],
		["help|h", "print out help"],
		["debug|d", "debug mode"]
	);
}

sub validate_args{
	my ($self, $opt, $args) = @_;

	if(defined $opt->{debug}){
		Log::Log4perl->easy_init($DEBUG);	
	}else{
		Log::Log4perl->easy_init($ERROR);
	}

	$logger = Log::Log4perl->get_logger();
	
	$logger->info("Running " . (caller(0))[3]);

	usage() if $opt->{help};
	
}

sub usage{
	$logger->info("Running " . (caller(0))[3]);
	my $help = <<EOF;
Default configuration path is /etc/nagios-cloudstack.conf
Available options :

Example:
$0 vm -i [vmid]
$0 vm -a [accountid]
$0 vm -f /opt/x/nagios-cloudstack.conf -a [accountid]	
EOF
	print $help;
	exit 1;
}

sub execute{
	my ($self, $opt, $args) = @_;
	
	if($opt->{id}){
		use Cloudstack::VM;
		
		my $obj;
		$logger->info("running " . (caller(0))[3]);
		$logger->debug("passing vm id = $opt->{id}");
		if($opt->{cfgfile}){
			$logger->debug("passing config path = $opt->{cfgfile}");
			$obj = Cloudstack::VM->new(vmid => $opt->{id},logger => $logger, cfgpath => $opt->{cfgfile});
		}else{
			$logger->debug("passing config path = undef");
			$obj = Cloudstack::VM->new(vmid => $opt->{id},logger => $logger);
		}
		$obj->getstatus();
		
	}elsif($opt->{account}){
		use Cloudstack::VM;
		
		my $obj = Cloudstack::VM->new(logger => $logger);
		$logger->info("running " . (caller(0))[3]);
		$logger->debug("passing account id = $opt->{account}");
		if($opt->{cfgfile}){
			$logger->debug("passing config path = $opt->{cfgfile}");
			$obj = Cloudstack::VM->new(accountid => $opt->{account},logger => $logger, cfgpath => $opt->{cfgfile});
		}else{
			$logger->debug("passing config path = undef");
			$obj = Cloudstack::VM->new(accountid => $opt->{account},logger => $logger);
		}
		$obj->getstatus();
	}
	else{
		$logger->debug('vm / account id not specified');
		die usage();
	}
}
1;

=pod

=head 1 VM

Cloudstack::Command::VM - VM Command Options

=cut