#!/usr/bin/perl
use strict;
use warnings;


my %m_ops = (
'nop' =>	'000000',
'lui' =>	'000100',
'b'	 => 	'010011',
'j' =>		'011010',
'jal' =>	'011011',
'jalr' =>	'011100',
'jr' =>		'011101',
'strcnt' =>	'100000',
'stpcnt' =>	'100001',
'ldcc' =>	'100010',
'ldic' =>	'100011',
'tx' =>		'110000',
'halt' =>	'110001'
);
my %r_ops = (
'add' =>	'000001',
'sub' =>	'000011',
'mov' =>	'000101',
'sll' =>	'000110',
'sra' =>	'000111',
'srl' =>	'001000',
'and' =>	'001001',
'not' =>	'001011',
'or' =>		'001100',
'xor' =>	'001110',
'addb' =>	'010100',
'subb' => 	'010110',
'addbi' =>	'010101',
'subbi' =>	'010111'
);
my %i_ops = (
'addi' =>	'000010',
'andi' =>	'001010',
'ori' =>	'001101',
'xori' =>	'001111',
'lw' =>		'010001',
'sw' =>		'010010',
'beq' =>	'010100',
'bgt' =>	'010101',
'bge' =>	'010110',
'ble' =>	'010111',
'blt' =>	'011000',
'bne' =>	'011001'
);

#variables
my %symbol_table = ();
my %data_table = ();
my $instrcount = 0;
my $datacount = 0;
my $data_section = 0;
my @temp_array = @ARGV;		#save input arg in temp array

#process input args as <input file names><instruction out file name><data out filename>
my $argc = scalar @ARGV;
die "Usage: assemble.pl <input file names><instruction out file name><data out filename>" if $argc < 3;
my $instr_filename = $ARGV[$argc-2];
my $data_filename = $ARGV[$argc-1];
splice @temp_array, $argc-2, 2;		#extract last two filenames
@ARGV = @temp_array;

#constants
use constant ADDR_PER_INSTR => 1;	#number of address count per instruction
use constant ADDR_PER_DATA => 1;	#number of address count per data

#open data out file
open(my $fh_data, '>', $data_filename) or die "Could not open file '$instr_filename' $!";

### first pass ###
while(<>){		# opens and reads input arguments as files line by line
	$_ =~ s/#.*//; 			# replace comments
	$_ =~ s/^\s+|\s+$//g; 	#trim space
	
	if($data_section == 1) {	#in DATA section
		if($_ =~ m/^$/){		#match with start and end adjacent i.e. blank, do nothing
		}
		elsif($_ =~ m/\w+:/){	#match label
			my @tokins = split(/:/, $_); # split by : 
			my $temp = $tokins[1]; $temp =~ s/^\s+|\s+$//g;
			my $type = $temp;
			$type =~ s/\s.*//;	#remove anything after first space
			my $value = $temp;
			$value =~ s/\.\S*\s//;	#remove things before first space
			$data_table{ $tokins[0] } = $datacount;	#add label to data table
			if ($type eq '.word'){
				my @values = split(",", $value);
				foreach my $val (@values){
					$val =~ s/^\s+|\s+$//g; 	#trim
					$val = if_hex2dec($val);	#if hex convert to dec
					my $line = sprintf("%x", $val);
					die "ERROR: value too large" if (length($line) > 8);
					$line = ('0' x (8 - length $line)).$line;
					print $fh_data '@'.sprintf('%03x',$datacount).' '.$line."\n";
					$datacount+= ADDR_PER_DATA;
				}
			}
			elsif ($type eq '.ascii'){
				my $line = ""; #line to be written to data out file
				$value =~ s/\"//g;	#replace quotes
				use integer; #use integer division
				#number of memory locations to be used (8 bytes/ 2 bytes per char)
				my $num_locs = (length $value)/4 + ((length $value)%4 != 0);
				my @values = split("", $value);
				for(my $i = 0; $i < $num_locs; $i++ ){
					for(my $j = 0; $j < 4; $j++){
						if(length $value <= (4*$i + $j)) {
							$line .= '00';
						}
						else {
							$line .= sprintf("%x", (ord($values[4*$i + $j])));
						}
					}
					print $fh_data '@'.sprintf('%03x',$datacount).' '.$line."\n";
					$line = "";
					$datacount+= ADDR_PER_DATA;
				}
			}
			elsif ($type eq '.space'){	#allocate space in data mem
				for(my $i = 0; $i < $value; $i++ ){
					print $fh_data '@'.sprintf('%03x',$datacount).' '.('0' x 8)."\n";
					$datacount+= ADDR_PER_DATA;
				}
			}
			else {
				die "ERROR: invalid type";
			}
		}
		elsif($_ =~ m/^\..*/ ) {	#match directive
			if ($_ eq '.text'){
				$data_section = 0; #change to text/code section
			}
		}
		else {
			die "ERROR: invalid data label/directive";
		}
		next;		#equivalent to continue statement (skip rest of loop)
	}
	### .text section  ###
	my $instr = "";
	if($_ =~ m/^$/){		#match with start and end adjacent i.e. blank, do nothing
	}
	else {
		$_ =~ s/\t/ /g;		#replace tab with space
		if(index($_, " ") != -1) {		#instruction has space
			$instr = substr($_, 0, index($_, " "));
		}
		else {
			$instr = $_;
		}
	}
	if($_ =~ m/\w+:/){		#match to any labels in the format (could be on same line as instruction) - LABEL:
		my @tokins = split(/:/, $_); # split by : (instruction could be on same line as label)
		$symbol_table{ $tokins[0] } = $instrcount;
		if((scalar @tokins > 1) && $tokins[1] =~ m/.+\s.+/) {		#if it has intruction on same line increase the instrction count
			$instrcount += ADDR_PER_INSTR;
		}
	}
	elsif($_ =~ m/^\..*/ ) {	#match with any directive (must be on its own line) in the format -  .text
		if ($_ eq '.data') {
			$data_section = 1; #change to data section
		}
		else {
			die "ERROR: invalid directive";
		}
	}
	elsif($_ =~ m/.+/) {	#leftover must be instruction (must have space in middle)
		$instrcount += ADDR_PER_INSTR ;
		$instrcount += ADDR_PER_INSTR if ($instr eq 'la') ;  #pseudo instruction == 2 instructions
	}
}
close $fh_data;
print "pass one complete\n";

#debug: print symbol table
foreach my $key ( keys %symbol_table) {
    print( "$key is at instr addr: $symbol_table{$key}\n" );
}
foreach my $key ( keys %data_table) {
    print( "$key is at data addr: $data_table{$key}\n" );
}
 printf("number of instructions %d\n", $instrcount/ADDR_PER_INSTR);

### second pass ###
#get file handle
open(my $fh, '>', $instr_filename) or die "Could not open file '$instr_filename' $!";
$instrcount = 0;		#reset instruction count
@ARGV = @temp_array;	#restore argv to temp array
my $line = "";			#line to contain instruction
while(<>){				# opens and reads input arguments as files line by line
	$_ =~ s/#.*//; 		# replace comments
	$_ =~ s/^\s+|\s+$//g;	#trim line
	if($_ =~ m/^\..*/ ) {	#match with any directive (on its own line) in the format -  .text
		if ($_ eq '.data') {
			$data_section = 1; #change to data section
		}
		elsif ($_ eq '.text'){
			$data_section = 0; #change to code section
			next;	#continue: skip this directive
		}
		else {
			die "ERROR: invalid directive";
		}
	}
	if($data_section == 1) {
		next;	#continue: skip instruction assembly if in data section
	}
	else {
		$_ =~ s/\w+://; 	# replace labels
	}
	
	if($_ =~ m/^$/){	#match with start and end adjacent i.e. blank, do nothing
	}
	elsif($_ =~ m/.+/){	#is an instruction
		my $instr = "";
		my $rest = "";
		$_ =~ s/\t/ /g;		#replace tab with space
		if(index($_, " ") != -1) {		#instruction has space
			$instr = substr($_, 0, index($_, " "));
			$rest = substr($_, index($_, " "));
		}
		else {
			$instr = $_;
		}
		$instr =~ s/^\s+|\s+$//g;	#trim instr
		$instr = lc $instr;			#opcodes to lowercase
		$rest =~ s/^\s+|\s+$//g;	#trim rest
		#print ("\'$rest\'\n");		#debug print
		# M-format instructions (+ some instr w/ 0 or 1 reg values)
		if(exists($m_ops{$instr})) {
			my @ops = split(',', $rest);
			$line = $m_ops{$instr};
			my $rs = "";
			if($instr eq 'j' || $instr eq 'jal') {
				$line .= dec2bin($symbol_table{$rest}, 26);
			}
			elsif($instr eq 'jalr' || $instr eq 'jr') {
				$rs = $ops[0]; $rs = to_reg($rs);
				$line .= dec2bin($rs,5).('0' x 21);
			}
			elsif($instr eq 'ldcc' || $instr eq 'ldic') {
				$rs = $ops[0]; $rs = to_reg($rs); check_zero($rs);
				$line .= ('0' x 5).dec2bin($rs,5).('0' x 16);
			}
			elsif($instr eq 'b') {
				my $imm = $ops[0]; $imm =~ s/^\s+|\s+$//g;	
				$line .= ('0' x 10).dec2bin(($symbol_table{$imm}-($instrcount+ADDR_PER_INSTR)), 16);
			}
			elsif($instr eq 'lui'){
				$rs = $ops[0]; $rs = to_reg($rs); check_zero($rs);
				my $imm = $ops[1]; $imm =~ s/^\s+|\s+$//g;
				$imm = if_hex2dec($imm);
				$line .= ('0' x 5).dec2bin($rs,5).dec2bin($imm, 16);
			}
			else {
				$line .= '0' x 26;
			}
		}
		# R-format instructions (+ some instr w/ 2 or 3 reg values)
		elsif(exists($r_ops{$instr})) {
			$line = $r_ops{$instr};
			my @ops = split(',', $rest);
			my $rd = $ops[0]; $rd = to_reg($rd); check_zero($rd);
			my $rs = $ops[1]; $rs = to_reg($rs);
			my $rt = "";
			if($instr eq 'mov' || $instr eq 'not'){
				$line .= dec2bin($rs,5).dec2bin($rd,5).('0' x 16);
			}
			elsif($instr eq 'sll' || $instr eq 'sra' || $instr eq 'srl') {
				my $imm5 = $ops[2]; $imm5 =~ s/^\s+|\s+$//g;
				$imm5 = if_hex2dec($imm5); 
				$line .= dec2bin($rs,5).('0' x 5).dec2bin($rd,5).dec2bin($imm5, 5).('0' x 6);
			}
			elsif($instr eq 'addbi' || $instr eq 'subbi') {
				my $imm8 = $ops[2]; $imm8 =~ s/^\s+|\s+$//g;
				$imm8 = if_hex2dec($imm8);
				$line .= dec2bin($rs,5).dec2bin($rd,5).('0' x 8).dec2bin($imm8, 8);
			}
			else {
				$rt = $ops[2]; $rt = to_reg($rt);
				$line .= dec2bin($rs,5).dec2bin($rt,5).dec2bin($rd,5).('0' x 11);
			}
		}
		# I-format instructions (instr w/ 2 reg values w/ imm16)
		elsif(exists($i_ops{$instr})) {
			$line = $i_ops{$instr};
			my @ops = split(',', $rest);
			my $rs = $ops[0]; $rs = to_reg($rs);
			my $rt = $ops[1]; $rt = to_reg($rt);
			my $imm = "";	
			if(substr($instr, 0, 1) eq 'b') {		#first letter is b (is a branch instr)
				$imm = $ops[2]; $imm =~ s/^\s+|\s+$//g;
				$line .= dec2bin($rs,5).dec2bin($rt,5).dec2bin(($symbol_table{$imm}-($instrcount+ADDR_PER_INSTR)), 16);
			}
			elsif($instr eq 'lw' || $instr eq 'sw') {
				check_zero($rs) if ($instr eq 'lw');	#only check if r0 if lw
				$rt = $ops[1]; $rt =~ s/.*\(|\)//g; 	#take what is inside parenthesis
				$imm = $ops[1]; $imm =~ s/\(.*\)//g;	#take what is outside of parenthesis
				$imm =~ s/^\s+|\s+$//g;			#trim
				$imm = 0 if $imm eq "";			#set equal to 0 if no immediate value
				if($rt !~ /\$/) {		#format: lw rs, imm(Label)
					die "ERROR: invalid data label" if (!exists($data_table{$rt}));					
					$imm = $data_table{$rt} + $imm;
					$rt = 0;
					$line .= dec2bin($rt,5).dec2bin($rs,5).dec2bin($imm, 16);			
				}
				else {				#format: lw rs, imm(rt)
					$rt = to_reg($rt);
					$line .= dec2bin($rt,5).dec2bin($rs,5).dec2bin($imm, 16);
				}
			}
			else {
				check_zero($rs);
				$imm = $ops[2]; $imm =~ s/^\s+|\s+$//g;
				$imm = if_hex2dec($imm); 
				$line .= dec2bin($rt,5).dec2bin($rs,5).dec2bin($imm, 16);
			}
		}
		#pseudo instruction: la (load address)
		elsif ($instr eq 'la') {
			my @ops = split(',', $rest);
			my $rs = $ops[0]; $rs = to_reg($rs); check_zero($rs);
			my $imm = $ops[1]; $imm =~ s/^\s+|\s+$//g;
			die "ERROR: invalid data label" if (!exists($data_table{$imm})); #check if label is valid	
			my $addr = dec2bin($data_table{$imm}, 32);
			$line = '000100'.('0' x 5).dec2bin($rs, 5).substr($addr, 0, 16);	#lui rs, addr (upper 16)
			my $line2 = '000010'.dec2bin($rs, 5).dec2bin($rs, 5).substr($addr, 8, 16);	#ori rs, rs, addr (lower 16)
			print $fh '@'.sprintf('%03x',$instrcount).' '.bin2hex($line)." //pseudo lui \$r$rs, $imm (upper 16)\n";
			$instrcount += ADDR_PER_INSTR;
			print $fh '@'.sprintf('%03x',$instrcount).' '.bin2hex($line2)." //pseudo ori \$r$rs, \$r$rs, $imm (lower 16)\n";
			$instrcount += ADDR_PER_INSTR;
			next;	#continue (because special case print)
		}
		else {
			die ("ERROR: non-existent op-code");	#quit on error
		}
		#print $fh $line."\n";
		print $fh '@'.sprintf('%03x',$instrcount).' '.bin2hex($line).' //'.$_."\n";
		$instrcount += ADDR_PER_INSTR;
	}
}
close $fh;
print "pass two complete\n";

#turns decimal input to binary, with length given in bits (used for imm and reg values)
sub dec2bin {	#call with dec2bin(<decimal>, <length>)
	 my ($decimal, $length) = @_;
	 my $temp = sprintf ("%b", $decimal);
	 if($decimal < 0) {
		$temp = substr($temp, 64-$length, $length);		#get length long from end
		die "ERROR: negative overflow: ($temp) for ($length bits)" if (substr($temp,0,1) == 0);
	 }
	 else {
		die "ERROR: positive overflow: ($decimal) for ($length bits)" if ($length < length ($temp));
		$temp = ('0' x ($length - length ($temp))).$temp;
	 }
	 return $temp;
}

#binary to hex
sub bin2hex {
	my ($bin_str) = @_;
	my $hex_str = "";
	while($bin_str ne "") {
		my $temp = substr($bin_str, 0, 4);
		$bin_str = (length $bin_str > 4) ? substr($bin_str, 4) : "";
		$hex_str .= sprintf('%x', oct("0b$temp"));
	}
	return $hex_str;
}
#trim registers, check for special
sub to_reg {
	my ($reg) = @_;
	$reg =~ s/^\s+|\s+$//g; #trim spaces
	$reg =~ s/\$|r//g; #trim '$r'
	$reg = 29 if $reg eq 'sp'; #special registers
	return $reg;
}
#if it is a hex immediate then convert to decimal
sub if_hex2dec {
	my ($decimal) = @_;
	if($decimal =~ m/^0x/) {
		return hex($decimal);
	}
	else { return $decimal; }
}
#die if using zero register as destination
sub check_zero {
	my ($reg) = @_;
	die "ERROR: use of \$r0 as destination register" if ($reg == 0);
}