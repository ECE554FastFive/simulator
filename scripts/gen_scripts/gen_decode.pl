#!/usr/bin/perl 

############################################
####Author: Yao#############################
############################################
use strict;
use warnings;
use Getopt::Long;

my ($infile, $outfile, $opcode_size, $help);
&parse_options();

open(FILE, $infile) || die "cannot open file $infile!\n";
my @csv_all = <FILE>;
my @csv_matrix;

my $wire_width = $opcode_size - 1;
close(FILE);
##first convert the csv content to a two dimensional array
##each line is an instruction
##with different control bits as columns
my $idx;
for($idx = 0; $idx < $#csv_all + 1; $idx++) {
    chomp($csv_all[$idx]);
    $csv_all[$idx] =~ s/\r$//; ##remove the carrage return at the end of csv file
    my @temp2 = split (',', $csv_all[$idx]);
    push(@csv_matrix, \@temp2); 
}
###write verilog file#####
&write_decoder(\@csv_matrix);
exit 0;

######################end of the main function###############################
sub write_decoder {
    my @csv_matrix = @{$_[0]};
    my ($ports, $params, $case);
    $ports = &write_ports(\@csv_matrix);
    $params = &write_params(\@csv_matrix);
    $case = &write_case(\@csv_matrix);
    open(OUT, ">$outfile") || die "cannot open file $outfile!\n";
    print OUT "////////////////////////////////////////////////////////\n";
    print OUT "////Author: \n";
    print OUT "////Date: \n";
    print OUT "////////////////////////////////////////////////////////\n";
    print OUT "module decoder(\n";
    print OUT $ports;
    print OUT " );";
    print OUT "\n";
    print OUT $params;
    print OUT "\n";
    print OUT "wire [${wire_width}:0] ctrl_codes = ${$csv_matrix[0]}[1]\;\n";
    print OUT "\n";
    print OUT "always \@\(ctrl_codes\) begin\n";
    print OUT "\n";
    print OUT "    case\(ctrl_codes\)\n";
    print OUT $case;
    print OUT "    endcase\n";
    print OUT "end\n\n";
    print OUT "endmodule\n";
    close(OUT);
}
sub write_ports {
    my @csv_cp = @{$_[0]};
    my $ports = "";
    my $i;
    $ports .= "    input [${wire_width}:0] ${$csv_cp[0]}[1],\n";
    for($i = 2; $i < $#{$csv_cp[0]} + 1; $i++) {
        $ports .= "    output reg ${$csv_cp[0]}[$i],\n";
    }
    $ports =~ s/,$//;
    return $ports;    
}

sub write_params {
    my @csv_cp = @{$_[0]};
    my $params = "";
    my $i;
    for ($i = 1; $i < $#csv_cp + 1; $i++) {
        $params .= "localparam ${$csv_cp[$i]}[0] = ${opcode_size}\'b${$csv_cp[$i]}[1]\;\n";
    }
    return $params;
}

sub write_case {
    my @csv_cp = @{$_[0]};
    my $case = "";
    my ($i, $j);
    for ($i = 1; $i < $#csv_cp + 1; $i++) {
        $case .= "        ${$csv_cp[$i]}[0]\: begin\n";

        for ($j = 2; $j < $#{$csv_cp[$i]} + 1; $j++) {
            $case .= " " x 12;
            $case .= "${$csv_cp[0]}[$j] \= ${$csv_cp[$i]}[$j]\;\n ";
        }
        $case .= "        end\n";
    }
    $case .= "        default\: begin\n";
    for ($j = 2; $j < $#{$csv_cp[0]} + 1; $j++) {
        $case .= " " x 12;
        $case .= "${$csv_cp[0]}[$j] \= 0\;\n ";
    }
    $case .= "        end\n";
    return $case;
}

sub parse_options {
    $infile = "instr.csv";
    $opcode_size = 6;
    $outfile = "decoder.v";
    GetOptions('infile=s' => \$infile,
               'outfile=s' => \$outfile,
               'opcode_size=s' => \$opcode_size,
               'help' => \$help);
    if (defined $help) {
        print "Usage: ./gen_decode --infile=<input file name> --outfile=<output file name> --opcode_size=<opcode_size>\n";
        print "default value: infile=instr.csv outfile=decoder.v size=6\n";
        exit;                  
    }
}
