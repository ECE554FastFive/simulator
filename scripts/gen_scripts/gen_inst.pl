#!/usr/bin/perl

use strict;
use warnings;

open(FILE, $ARGV[0]) || die "cannot open file $ARGV[0]!\n";
my @vlog_all = <FILE>;
close(FILE);

my (@inputs, @outputs, @inouts);
my $module_name;
&extract_port(\@vlog_all, \$module_name);
&gen_tb(\$module_name);
print "Testbench generated successfully!!!\n";

sub extract_port {
    my $vlog_line;
    my @vlog_all = @{$_[0]};
    foreach $vlog_line (@vlog_all) { ##first remove all the comments
        $vlog_line =~ s/\/\/(.*)//;
    }
    foreach $vlog_line (@vlog_all) {
        if ($vlog_line =~ /\s*module\s*(\w+)/) {    ##get module name
            ${$_[1]} = $1;
        }
        if ($vlog_line =~ s/\s*input\s+//) {
             $vlog_line =~ s/(\s*reg\s+|\s*wire\s+)//;
             $vlog_line =~ s/\s*\[\d*\:\d*\]\s*//;
             while($vlog_line =~ s/(\w+)\W*//) {
                 push(@inputs, $1);
             }
        }
        if ($vlog_line =~ s/\s*output\s+//) {
             $vlog_line =~ s/(\s*reg\s+|\s*wire\s+)//;    ## remove "reg" or "wire" in something like output reg out2;
             $vlog_line =~ s/\s*\[\d*\:\d*\]\s*//;        ## remove [10:0] in something like output [10:0] out1;
             while($vlog_line =~ s/(\w+)\W*//) {
                 push(@outputs, $1);
             }
        } 
        if ($vlog_line =~ s/\s*inout\s+//) {
             $vlog_line =~ s/(\s*reg\s*|\s*wire\s*)//;
             $vlog_line =~ s/\s*\[\d*\:\d*\]\s*//;
             while($vlog_line =~ s/(\w+)\W*//) {
                 push(@inouts, $1);
              }
        }  
    }
}

sub gen_tb {
    open(TB, ">${$_[0]}_tb.v");
    my $port;
    print TB "module ${$_[0]}_tb();\n";
    print TB "\n";
    foreach $port (@inputs) {
        print TB "reg $port;\n";
    }
    foreach $port (@outputs) {
        print TB "wire $port;\n";
    }
    foreach $port (@inouts) {
        print TB "wire $port;\n";    ##this need to add some additional definitions and assign statement, we won't use inouts so I just leave it here
    }
    print TB "\n";
    my $inst = "";
    $inst .= "${$_[0]} i_${$_[0]}\(\n";
    my $spaces = " " x length("${$_[0]} i_${$_[0]}\(");
    foreach $port (@inputs) {
        $inst .= "${spaces}.$port($port),\n";
    }   
    foreach $port (@outputs) {
        $inst .= "${spaces}.$port($port),\n";
    }   
    foreach $port (@inouts) {
        $inst .= "${spaces}.$port($port),\n";    ##this need to add some additional definitions and assign statement, we won't use inouts so I just leave it here
    }
    $inst =~ s/,\n$//;
    $inst .= ");\n";
    print TB $inst;
    print TB "\n";
    print TB "endmodule\n";
    close(TB);
}

