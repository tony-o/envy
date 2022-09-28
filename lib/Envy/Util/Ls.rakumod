unit module Envy::Util::Ls;
use Envy::Config;
use Envy::Util::Log;

sub ls() is export {
  my $home = config<lib>.IO;
  my @ds;
  for dir($home) -> $d {
    df('checking %s for ./name', $d.absolute);
    if $d.child('name').IO.f {
      @ds.push: $d.child('name').IO.slurp.trim;
    } else {
      @ds.push: $d.basename;
    }
  }
  @ds.sort;
}
