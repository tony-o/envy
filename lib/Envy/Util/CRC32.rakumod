unit module CRC32;
  
my @table = (0..255).map(-> $a is copy {
  (0..7).map({ $a +^= 0x1db710640 if $a +& 1;
               $a +>= 1; });
  $a;
});


sub crc32_hex(Str:D $str, $crc is copy = 0xffffffff --> Str:D) is export {
  for $str.encode -> $b {
    $crc = ($crc +> 8) +^ @table[($crc +& 0xff) +^ $b];
  }

  sprintf '%08X', ($crc +^ 0xffffffff);
}
