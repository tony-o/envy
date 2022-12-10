unit module Envy::Util::Ls;
use Envy::Config;
use Envy::Util::Log;

sub enabled(--> List) is export {
  my %repos = dir(config<lib>.IO).map({ $_.basename => $_.IO.d });
  config<enabled>.IO.slurp.split($?NL).grep({ %repos{$_} || False }).List;
}

sub ls(--> List) is export {
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
  @ds.sort.List;
}
