unit class Envy does CompUnit::Repository;

use Envy::Config;
use Envy::Util::CRC32;
use Envy::Util::Ls;

has $!prefix;
has %!loaded;
has CompUnit::Repository::Installation $!cur handles <need upgrade-repository install uninstall files candidates resolve resource loaded distribution installed precomp-store precomp-repository provides-warning can-install>;

submethod TWEAK(:$prefix is copy, :$next-repo --> Nil) {
  my $use-null = False;
  $prefix.=trim;
  if $prefix eq '' {
    $prefix = enabled().grep(*.trim ne '').join(':');
  }
  if $prefix eq '' {
    $use-null = True;
    $prefix = $*TMPDIR.absolute;
  }
  
  $!prefix  = $prefix;

  my @repos     = $prefix.split(':').reverse;
  my $lnr      := $next-repo;
  my %available = ( ls().map(* => 1) );
  for @repos -> $dir {
    my $d = $dir eq '.' ?? crc32_hex($*CWD.absolute) !! $dir;
    $*ERR.say("Envy repo '{$dir}' does not exist or hasn't been initialized, please initialize it with `envy init {$dir}`"), exit 1
      if %available{$d}:!exists && !$use-null;
    $lnr := CompUnit::Repository::Installation.new(
      prefix     => $use-null ?? $dir !! config<lib>.IO.child($dir),
      next-repo  => $lnr,
    );
  }

  $!cur = $lnr;

  CompUnit::RepositoryRegistry.register-name("Envy#{$!prefix}", self);
}

method name(--> Str:D)         { $!prefix }
method prefix(--> Str:D)       { $!prefix }
method short-id(--> Str:D)     { 'Envy' }
method id(--> Str:D)           { "Envy#{$!prefix}" }
method path-spec(--> Str:D)    { "Envy#{$!prefix}" }
