unit class Envy is CompUnit::Repository::Installation;

use Envy::Config;
use Envy::Util::CRC32;
use Envy::Util::Ls;
use Envy::Util::Log;

has $!prefix;
has %!loaded;
has CompUnit::Repository::Installation $!cur handles <need upgrade-repository install uninstall files candidates resolve resource loaded distribution installed precomp-store precomp-repository provides-warning can-install>;

submethod TWEAK(:$prefix is copy, :$next-repo --> Nil) {
  $prefix  = ($prefix//'').trim;
  $!prefix = $prefix;
  if $prefix eq '' {
    $!cur = $next-repo;
    return;
  }
  
  my @repos     = $prefix.split(':').reverse.grep(* ne $*CWD);
  my $lnr      := $next-repo;
  my %available = ( ls().map(* => 1) );
  for @repos -> $dir {
    my $d = $dir eq '.' ?? crc32_hex($*CWD.absolute) !! $dir;
    e("Envy repo '{$dir}' does not exist or hasn't been initialized, please initialize it with `envy init {$dir}`"), next
      if %available{$d}:!exists;
    $lnr := CompUnit::Repository::Installation.new(
      prefix     => config<lib>.IO.child($dir),
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
