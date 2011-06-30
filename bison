#! /usr/bin/perl

# Read in ITFC-compressed file and further compress using,
# Binary Indicator Symbol Order Notation.
# Binary indicator symbols ^ and | occur most commonly in ITFC-compressed files.
# Also, " and @ are very common

# 94 to power of 3: 830 584
# 94 to power of 4: 78 074 896
# 2 to power of 26: 67 108 864, max. block 26-binary, 26 '1's == 67 108 863

open(ITFCFILE, "<$ARGV[0]") or die "File access error: $!\n";
open(BISONOP, ">$ARGV[1]") or die "File access error: $!\n";

my %index, %base;
my @nums = (33..126);         # Use ascii chars 33 - 126
my $count = 0;
foreach (@nums) {             # Map decimals 0-94 to corresponding
    $base{$count} = chr $_;   # ascii charcters in 33-126 range,
    $count++;                      
}
my @inputArr, @caretPipe, @mainSeq, $charCount;
while (<ITFCFILE>) {
    my @lineChars = &formCharsArray($_);   # Input line of chars
    foreach (@lineChars) {        
        $charCount++;
        @inputArr[$charCount] = $_; 
    }    
}
print scalar (@inputArr);
@caretPipe = &extractSymbols("^",  "|", @inputArr);
print @mainSeq, "\n";
print scalar (@mainSeq);
@tempo = @mainSeq[2..(scalar (@mainSeq) - 1)];
print scalar (@tempo);
&makeBlocks(@caretPipe);
@quotesAt = &extractSymbols("\"",  "@", @mainSeq);
print @mainSeq, "\n";
&makeBlocks(@quotesAt);
print BISONOP @mainSeq;

########################## SUBROUTINES ##############################

sub extractSymbols {
    my $symbol1 = $_[0];
    my $symbol0 = $_[1];
    my @targetSeq = @_[2..(scalar (@_) - 1)];
    undef @mainSeq;
    print scalar (@_);
    print scalar (@targetSeq);
    my @symbolOrder;
    my $mainSeqCount = 0;
    my $count = 0;
    foreach (@targetSeq) {    
        if ( (ord $_ == ord $symbol1) || (ord $_ == ord $symbol0) ) {
            if (ord $_ == ord $symbol1) {
                @symbolOrder[$count] = "1";
                $count++;
            }
            if (ord $_ == ord $symbol0) {
                @symbolOrder[$count] = "0";
                $count++;
            }
        } else {
              @mainSeq[$mainSeqCount] = $_;
              $mainSeqCount++;
        }
    }
    print "INDCOUNT";
    print scalar (@symbolOrder), "\n";
    print scalar (@mainSeq), "\n";
    return @symbolOrder;
}

sub makeBlocks {  # Break bin seq into blocks of 26, last block gen. smaller
    my @array = @_; # Pass in target array    
    my $bisonToken, $block;
    my $indCount = scalar (@array);    
    my $numBlocks = int $indCount/26;
    if ($indCount%26 != 0) { $numBlocks++ };
    print BISONOP $numBlocks;
    print BISONOP " ";
    my $blockNum = 1;
    foreach (1..$numBlocks) {            
        if ( ($blockNum == $numBlocks) && ($indCount%26 != 0) ) { 
            foreach (1..($indCount%26)) {
                $block .= @array[ (($blockNum -1)*26 + $_ -1) ];
            }            
        } else {   # not last block
            foreach (0..25) {
                $block .= @array[ (($blockNum -1)*26 + $_) ];                
            }                           
        }# end else
        $bisonToken = &genBinary($block);
        if (length ($bisonToken) < 4) {$bisonToken = &padToken($bisonToken)};
        print BISONOP $bisonToken;
        $outputCount++;
        $blockNum++;
        $block = "";
    }# end foreach
    print BISONOP "\n";
    print $indCount, "\n";
    print $indCount%26, "\n";
    print $numBlocks, "\n";
} 

sub padToken {
    my $token = $_[0];
    while (length ($token) < 4) {
        $token = "0" . $token
    }
    return $token;
}

sub genBinary {
    my $binaryString = "0b";
    my $binaryInput = $_[0];
    $binaryString .= $binaryInput;
    print $binaryString, "\n";
    my $deci = oct( $binaryString );
    print $deci, "\n";
    my $cpToken = &genToken($deci);
    print length ($cpToken), "\n";
    print $cpToken, "\n";
    return $cpToken;
}

sub formCharsArray {
    my $len = length $_[0];
    my @array;
    foreach (0..($len-1)) {
        $charString = substr($_[0], $_, 1);
        push @array, $charString;
    }
    return @array;
}

sub genToken {
    my $dec = $_[0];
    my @valueArray; 
    my $token;
    if ($dec < 94) {
        $token = &oneChar($dec);
    }
    if ($dec > 93) {
        $token = &twoChar($dec);        # Token is double ascii char,
    }
    if ($dec > 8835) {
        $token = &threeChar($dec);      # Token is triple ascii char 
    }
    if ($dec > 830583) {
        $token = &fourChar($dec);       # Token is quadruple ascii char 
    }                                   # Allows index up to size 78 million
    return $token;
}
sub oneChar {
    my $tok;
    if ($_[0] < 94) {
        $tok = $base{$_[0]};
    }
    return $tok;
}
sub twoChar {
    my $tok;
    if ($_[0] > 93) {
        my $p = int ($_[0]/94);
        my $s = int ($_[0]%94);
        $tok = $base{$p};
        $tok .= &oneChar($s);
    }
    return $tok;
}
sub threeChar {
    my $tok;
    if ($_[0] > 8835) {
        my $p = int ($_[0]/8836);
        my $s = int ($_[0]%8836);
        $tok = $base{$p};               
        if ($s <94) { 
            $tok .= "!";
            $tok .= &oneChar($s); 
        } else { $tok .= &twoChar($s) };
    }
    return $tok;
}
sub fourChar {
    my $tok;
    if ($_[0] > 830583) {
        my $p = int ($_[0]/830584);
        my $s = int ($_[0]%830584);
        $tok = $base{$p};
        if  ($s <94) {
            $tok .= "!!";
            $tok .= &one($s);
        } else {             
            if ($s <8836) { 
                $tok .= "!";
                $tok .= &twoChar($s); 
            } else { $tok .= &threeChar($s) };
        }
    }
    return $tok;
}

