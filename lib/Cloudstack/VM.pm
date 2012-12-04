package Cloudstack::VM;
use strict;
use warnings;
use Mouse;
use Cloudstack::General;

extends 'Cloudstack::General';

has [qw/vmid accountid accountname domainid/] => (is => "rw", isa => "Str");

sub set_command{
	my $self = shift;

	$self->logger->info("Running " . (caller(0))[3]);
	
	if($self->vmid){
		$self->command("command=listVirtualMachines&id=" . $self->vmid);
	}
	elsif($self->accountid){
		$self->command("command=listVirtualMachines&account=" . $self->accountname . "&domainid=" . $self->domainid);
	}
	
	$self->logger->debug($self->command);
}

sub getstatus{
	my $self = shift;
	
	my ($zoneid, $cfgpath, $warning, $crit) = @_;
	
	$self->logger->info("Running " . (caller(0))[3]);
	
	if($self->vmid){
		$self->logger->debug("Processing vmid : " . $self->vmid);
		
	}
	elsif($self->accountid){
		use Cloudstack::Account;
		
		$self->logger->debug("Processing accountid : " . $self->accountid);
		
		my $account = Cloudstack::Account->new(logger => $self->logger, cfgpath => $self->cfgpath);
		$account->getxml($self->accountid);
		
		$self->accountname($account->getaccountname());
		$self->domainid($account->getdomainid());
	}
	
	#set all params
	
	$self->set_command();
	
	#$self->cfgpath("$cfgpath") if defined $cfgpath;
	my $conf = $self->getGlobalConfig();
	
	$self->set_connection($conf);
	my $xml = $self->get_result();
	
	$self->print_nagios($xml);
}

sub print_nagios{
	my ($self, $xml) = @_;
	
	$self->logger->info("Running " . (caller(0))[3]);
	
	$xml = XML::LibXML->load_xml(string => $xml);
	my $root = '/listvirtualmachinesresponse/virtualmachine/state';
	if($self->vmid){
		$self->logger->info("Checking vm state");
		
		my $state = '/listvirtualmachinesresponse/virtualmachine/state';
		$state = $xml->findnodes($state)->string_value;
		
		$self->logger->debug("state : $state");
		
		if($state =~ /\bRunning\b/){
			print "OK : vmid " . $self->vmid . " is Running\n";
			exit 0;
		}else{
			print "CRITICAL : vmid " . $self->vmid . " is " . $state . "\n";
			exit 2;
		}
	}
	elsif($self->accountid){
		my $root = '/listvirtualmachinesresponse/virtualmachine';
		my @vms = $xml->findnodes($root);
		my @status;
		
		for(@vms){
			my $state = $_->findnodes("state")->string_value;
			my $vmname = $_->findnodes("name")->string_value;
			push @status, "CRITICAL : vmname $vmname status is $state\n" unless $state =~ /\bRunning\b/;
		}
		
		if(@status){
			print "CRITICAL: one/more vm is not running !\n";
			print @status;
			exit 2;
		}else{
			print "OK : All vm running\n";
			exit 0;
		}
	}
}

1;