#!/usr/bin/env perl
use App::Cmd;
use strict;
use warnings;
use lib '/Users/heince/Project/nagios-cloudstack/lib';

use Cloudstack;
Cloudstack->run;
