package Cloudstack::General;
use strict;
use warnings;
use Mouse;
use XML::LibXML;
use Config::General;

has 'cfgpath' => (is => "rw", default => '/etc/nagios-cloudstack.conf');
has [qw/ia iasite site apikey secretkey command flag logger timeout/] => (is => "rw");


sub getGlobalConfig{
	my $self = shift;
	
	$self->logger->info("Running " . (caller(0))[3]);
	
	#check if config file exist
	unless(-f $self->cfgpath){
		print "CRITICAL : config file not found\n";
		exit 2;
	}
	
	my $conf = new Config::General(
				-ConfigFile => $self->cfgpath
			);

	my %config = $conf->getall();
	return \%config;
}

sub set_connection{
	my $self = shift;
	
	my ($conf) = @_;
	
	my $url = $$conf{default_url};
	my $ssl = $$conf{ssl_verify_hostname};
	$self->set_perlssl($ssl);
	
	$self->iasite($$conf{$url}) and $self->ia(1) if $url eq 'url_noauth';
	$self->site($$conf{url_auth});
	$self->apikey($$conf{apikey});
	$self->secretkey($$conf{secretkey});
	$self->timeout($$conf{timeout} || 10);
}

sub set_perlssl{
	my $self = shift;
	
	$self->logger->info("Running " . (caller(0))[3]);
	
	my $value = shift;
	if($value =~ /\btrue\b/i){
		$ENV{'PERL_LWP_SSL_VERIFY_HOSTNAME'} = 1;
	}
	elsif($value =~ /\bfalse\b/i){
		$ENV{'PERL_LWP_SSL_VERIFY_HOSTNAME'} = 0;
	}else{
		$ENV{'PERL_LWP_SSL_VERIFY_HOSTNAME'} = 1;
	}
	
	$self->logger->debug("PERL_LWP_SSL_VERIFY_HOSTNAME = " . $ENV{'PERL_LWP_SSL_VERIFY_HOSTNAME'});
}

#return API result
sub get_result{
	use WWW::Mechanize;
	use Encode;
	
	my $self = shift;
	
	$self->logger->info("Running " . (caller(0))[3]);
	$self->logger->debug("ia = " . $self->ia) if defined $self->ia;
	$self->logger->debug("iasite = " . $self->iasite) if defined $self->iasite;
	$self->logger->debug("site = " . $self->site) if defined $self->site;
	$self->logger->debug("apikey = " . $self->apikey) if defined $self->apikey;
	$self->logger->debug("secretkey = " . $self->secretkey) if defined $self->secretkey;
	$self->logger->debug("command = " . $self->command) if defined $self->command;
	$self->logger->debug("timeout = " . $self->timeout) if defined $self->timeout;
	
	my ($field,$value);
	my $my_filename = basename($0, '');
	
	my $url;
	$self->flag(2);
	
	unless($self->ia){
		use URI::Encode;
		use Digest::SHA qw(hmac_sha1);
		use File::Basename qw(basename);
		use MIME::Base64;
	
		my $uri = URI::Encode->new();

		### Generate URL ###
		#step1
		
		my $output;
		
		my $query = $self->command . "&apiKey=". $self->apikey;
		my @list = split(/&/,$query);
		foreach (@list){
			if(/(.+)\=(.+)/){
				$field = $1;
				$value = $uri->encode($2, 1); # encode_reserved option is set to 1
				$_ = $field."=".$value;
			}
		}
		
		#step2
		foreach (@list){
			$_ = lc($_);
		}
		
		$output = join("&",sort @list);
		
		#step3
		my $digest = hmac_sha1($output, $self->secretkey);
		my $base64_encoded = encode_base64($digest);chomp($base64_encoded);
		my $url_encoded = $uri->encode($base64_encoded, 1); # encode_reserved option is set to 1
		$url = $self->site."apikey=".$self->apikey."&" . $self->command . "&signature=".$url_encoded;
	}else{
		$url = $self->iasite . $self->command;
	}
	
	if($self->flag == 1 || $self->flag ==3){
		return $url;
		if($self->flag == 1){
			exit;
		}
	}
	
	### get URL ###
	$self->logger->debug("Getting response from the $url\n");
	my $mech = WWW::Mechanize->new(autocheck => 1, timeout => $self->timeout);
	my $temp;
	eval {  
		$temp = $mech->get($url); 
	};
	
	if($@){
		my $resp = $mech->response();
		
		unless($resp->is_success){
			print "CRITICAL : " . $resp->status_line . "\n";
			exit 2;
		}

		my $xml = XML::LibXML->load_xml(string => $resp->decoded_content);
		my $errcode = "Error code: " . $xml->findnodes("/*/errorcode")->string_value() . "\n" if $xml;
		my $errtxt = "Error text: " . $xml->findnodes("/*/errortext")->string_value() . "\n" if $xml;

		print "CRITICAL : $errtxt\n";
		exit 2;
	}
	
	my $xml = encode('cp932',$mech->content);
	$self->logger->debug($xml);
	return $xml;
}


1;
