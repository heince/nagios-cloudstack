package Cloudstack::Capacity;
use strict;
use warnings;
use Mouse;
use Cloudstack::General;

extends 'Cloudstack::General';

has [qw/zoneid/] => (is => "rw", isa => "Str");
has [qw/capacity_warning capacity_crit/] => (is => 'rw', isa => "Int");

sub set_command{
	my $self = shift;

	$self->logger->info("Running " . (caller(0))[3]);
	$self->command("command=listZones&showcapacities=true&id=" . $self->zoneid);
	$self->logger->debug($self->command);
}

sub getstatus{
	my $self = shift;
	
	my ($zoneid, $cfgpath, $warning, $crit) = @_;
	
	$self->logger->info("Running " . (caller(0))[3]);
	$self->logger->debug("zone id = $zoneid");
	$self->logger->debug("config path = $cfgpath") if defined $cfgpath;
	
	#set all params
	$self->zoneid($zoneid);
	$self->capacity_warning($warning);
	$self->capacity_crit($crit);
	$self->set_command();
	
	$self->cfgpath("$cfgpath") if defined $cfgpath;
	my $conf = $self->getGlobalConfig();
	
	$self->set_connection($conf);
	my $xml = $self->get_result();
	
	$self->print_nagios($xml);
}

sub print_nagios{
	my ($self, $xml) = @_;
	
	$self->logger->info("Running " . (caller(0))[3]);
	
	$xml = XML::LibXML->load_xml(string => $xml);
	my $root = '/listzonesresponse/zone/capacity';
	
	my @capacity = $xml->findnodes($root);
	my @status;
	for(@capacity){
		my $type = $_->findnodes("type")->string_value;
		my $percent = $_->findnodes("percentused")->string_value;
		
		$type = $self->get_type($type);
		$self->logger->debug("type = $type\t");
		$self->logger->debug("percentused = $percent");		

		if($percent < $self->capacity_warning){
			push @status, "OK: $type used = $percent%\n";
		}
		elsif(($percent > $self->capacity_warning) and ($percent < $self->capacity_crit)){
			push @status, "WARNING: $type used = $percent%\n";
		}
		elsif($percent > $self->capacity_crit){
			push @status, "CRITICAL: $type used = $percent%\n";
		}
	}
	
	if(grep {/^CRITICAL/} @status){
		print "CRITICAL !!\n";
		print @status;
		exit 2;
	}
	elsif(grep {/^WARNING/} @status){
		print "WARNING ! \n";
		print @status;
		exit 1;
	}elsif(grep {/^OK/} @status){
		print "OK \n";
		print @status;
		exit 0;
	}
}

sub get_type{
	my ($self, $type) = @_;
	
	$self->logger->info("Running " . (caller(0))[3]);
	
	my $result;
	
	if($type == 0){
		$result = 'Memory';
	}
	elsif($type == 1){
		$result = 'CPU';
	}
	elsif($type == 2){
		$result = 'Storage';
	}
	elsif($type == 3){
		$result = 'Storage Allocated';
	}
	elsif($type == 4){
		$result = 'Virtual Network Public IP';
	}
	elsif($type == 5){
		$result = 'Private IP';
	}
	elsif($type == 6){
		$result = 'Secondary Storage';
	}
	elsif($type == 7){
		$result = 'VLAN';
	}
	elsif($type == 8){
		$result = 'Direct Attached Public IP';
	}
	elsif($type == 9){
		$result = 'Local Storage';
	}else{
		$result = 'Unknown';
	}
	
	return $result;
}

1;