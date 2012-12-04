package Cloudstack::Account;
use strict;
use warnings;
use Mouse;
use Cloudstack::General;

extends 'Cloudstack::General';

has [qw/accountname domainid accountxml/] => (is => "rw");

sub set_command{
	my ($self, $id) = @_;

	$self->logger->info("Running " . (caller(0))[3]);
	
	$self->command("command=listAccounts&id=" . $id);

	$self->logger->debug($self->command);
}

sub getxml{
	my ($self, $id) = @_;
	
	$self->logger->info("Running " . (caller(0))[3]);
	#set all params
	
	$self->set_command($id);
	
	#$self->cfgpath("$cfgpath") if defined $cfgpath;
	my $conf = $self->getGlobalConfig();
	
	$self->set_connection($conf);
	my $xml = $self->get_result();
	$xml = XML::LibXML->load_xml(string => $xml);
	
	$self->accountxml($xml);
}

sub getaccountname{
	my $self = shift;
	
	return $self->accountxml->findnodes('/listaccountsresponse/account/name')->string_value;
}

sub getdomainid{
	my $self = shift;
	
	return $self->accountxml->findnodes('/listaccountsresponse/account/domainid')->string_value;
}

sub getstatus{
	my $self = shift;
	
	my ($zoneid, $cfgpath, $warning, $crit) = @_;
	
	$self->logger->info("Running " . (caller(0))[3]);
	$self->logger->debug("config path = $cfgpath") if defined $cfgpath;
	
	if($self->vmid){
		$self->logger->debug("Processing vmid : " . $self->vmid);
		
	}
	elsif($self->accountid){
		$self->logger->debug("Processing accountid : " . $self->accountid);
	}
	
	#set all params
	
	$self->set_command();
	
	#$self->cfgpath("$cfgpath") if defined $cfgpath;
	my $conf = $self->getGlobalConfig();
	
	$self->set_connection($conf);
	my $xml = $self->get_result();
	
	$self->print_nagios($xml);
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
	else{
		$result = 'Unknown';
	}
	
	return $result;
}

1;