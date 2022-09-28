unit class Envy does CompUnit::Repository;

use Envy::Config;
use Envy::Util::CRC32;

has $!prefix;
has %!loaded;
has CompUnit::Repository::Installation $!cur handles <need upgrade-repository install uninstall files candidates resolve resource loaded distribution installed precomp-store precomp-repository provides-warning can-install>;

submethod TWEAK(:$prefix, :$next-repo --> Nil) {
  $!prefix = $prefix eq '.' ?? crc32_hex($*CWD.absolute) !! $prefix;
  $!cur = CompUnit::Repository::Installation.new(
    prefix => config<lib>.IO.child($!prefix),
    :$next-repo,
  );

  CompUnit::RepositoryRegistry.register-name("Envy#{$!prefix}", self);
}

method name(--> Str:D)         { $!prefix }
method prefix(--> Str:D)       { $!prefix }
method short-id(--> Str:D)     { 'Envy' }
method id(--> Str:D)           { "Envy#{$!prefix}" }
method path-spec(--> Str:D)    { "Envy#{$!prefix}" }
