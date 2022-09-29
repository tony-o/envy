unit module Envy::Util::Ls;
use Envy::Config;
use Envy::Util::Log;

sub enabled(--> List) is export {
  my $nv = (%*ENV<RAKUDOLIB>//'').match(/'Envy#' $<s>=<-[,]>+/);
  if $nv !~~ Match {
    if (%*ENV<RAKUDOLIB>//'').contains(/'Envy#'/) && config<path>.IO.child('enabled').f {
      my $ds = config<path>.IO.child('enabled').IO.slurp;
      return () if $ds.trim eq '';
      return $ds.split("\n").grep(*.trim ne '').List;
    }
    return ();
  }
  $nv<s>.Str.split(':').List;
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
