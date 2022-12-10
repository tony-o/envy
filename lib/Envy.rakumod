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
  $!prefix = $prefix.IO;
  if $prefix eq '' || $prefix.IO.absolute eq $*CWD.absolute {
    my @enabled = enabled();
    if @enabled {
      $!cur = Envy.new(
        prefix    => config<lib>.IO.child(@enabled.pop),
        next-repo => ($next-repo//Nil),
      );
      my $lnr := $!cur;
      @enabled.map(-> $repo {
        $lnr := Envy.new(
          prefix    => config<lib>.IO.child($repo),
          next-repo => $lnr,
        );
      });
    } else {
      $!cur = CompUnit::Repository::Installation.new(
        prefix    => $*TMPDIR.child('envy').child(('0' ... '9', 'A' ... 'Z', 'a' ... 'z').pick(15).join('')),
        next-repo => ($next-repo//Nil),
      );
      END {
        try {
          rmt($!cur.prefix);
        };
      };
    }
    return;
  }
  
  my $dir = config<lib>.IO.child($!prefix.basename);

  $!cur := CompUnit::Repository::Installation.new(
    prefix    => $dir,
    next-repo => ($next-repo//Nil),
  );

  CompUnit::RepositoryRegistry.register-name("Envy#{$!prefix.basename}", $!cur);
}

method name(--> Str:D)         { $!prefix.basename }
method prefix(--> IO::Path:D)  { $!prefix }
method short-id(--> Str:D)     { 'Envy' }
method id(--> Str:D)           { "Envy#{$!prefix.basename}" }
method path-spec(--> Str:D)    { "Envy#{$!prefix.basename}" }
