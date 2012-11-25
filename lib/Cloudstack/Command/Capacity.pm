package Cloudstack::Command::Capacity;
use Cloudstack -command;
use Log::Log4perl qw/:easy/;

my $logger;

sub opt_spec{
	return(
		["zone|z=s", "zone id"],
		["cfgfile|f=s", "config file location"],
		["warning|w=s", "warning percent"],
		["critical|c=s", "critical percent"],
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
	
	$logger->info("Validating \$opt->{warning}");
	usage() unless defined $opt->{warning} and $opt->{warning} < $opt->{critical};	
	
	$logger->info("Validating \$opt->{critical}");
	usage() unless defined $opt->{critical} and $opt->{critical} < 100 and $opt->{critical} > $opt->{warning};
	
}

sub usage{
	$logger->info("Running " . (caller(0))[3]);
	my $help = <<EOF;
Default configuration path is /etc/nagios-cloudstack.conf
Available options :

Example:
$0 capacity -z [zone id] -w [warning percentage] -c [critical percentage]
$0 capacity -f /opt/x/nagios-cloudstack.conf -z [zone name] -w 70 -c 80	
EOF
	print $help;
	exit 1;
}

sub execute{
	my ($self, $opt, $args) = @_;
	
	if($opt->{zone}){
		use Cloudstack::Capacity;
		
		my $obj = Cloudstack::Capacity->new(logger => $logger);
		$logger->info("running " . (caller(0))[3]);
		$logger->debug("passing zone id = $opt->{zone}");
		$logger->debug("passing warning percentage = $opt->{warning}");
		$logger->debug("passing critical percentage = $opt->{critical}");
		if($opt->{cfgfile}){
			$logger->debug("passing config path = $opt->{cfgfile}");
			$obj->getstatus($opt->{zone}, $opt->{cfgfile}, $opt->{warning}, $opt->{critical});
		}else{
			$logger->debug("passing config path = undef");
			$obj->getstatus($opt->{zone}, undef, , $opt->{warning}, $opt->{critical});
		}
		
	}else{
		$logger->debug('zone id not specified');
		die "please specify zone id\n";
	}
}
1;

=pod

=head 1 Capacity

Cloudstack::Command::Capacity - Capacity Command Options

=cut