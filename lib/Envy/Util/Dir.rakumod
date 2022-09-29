unit module Envy::Util::Dir;

sub rmd(IO::Path:D $d where *.e --> Nil) is export {
  return unless $d.d;
  for $d.dir -> $f {
    rmd($f) if $f.d;
    $f.unlink if $f.f;
  }
  $d.rmdir;
}
