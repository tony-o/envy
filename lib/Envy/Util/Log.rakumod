unit module Envy::Util::Log;

our $LL = 2;

sub set-ll-from-args(*@as --> List) is export {
  my %set-ll = (@as
    .grep(-> $a {$a ~~ '--silent'|'--info'|'--debug' || $a ~~ m{^'--loglevel'}})
    .map({ $_.substr(2).split('=')[0] => $_ })
  );
  pf('Only one argument of --silent|--info|--debug|--loglevel may be specified, saw: %s', %set-ll.keys.join(', '))
    if %set-ll.keys.elems > 1;

  $LL = %set-ll<loglevel>.split('=', 2)[1] or pf('Expected --loglevel=<Int>, got %s', %set-ll<loglevel>)
    if %set-ll<loglevel>;
  $LL = 1 if %set-ll<info>;
  $LL = 0 if %set-ll<debug>;
  $LL = 5 if %set-ll<silent>;

  #TODO
  @as.grep(-> $a {$a !~~ '--silent'|'--info'|'--debug' && $a !~~ m{^'--loglevel'}}).List;
}

sub s(Str:D $p, Str:D $s is copy, :$pipe = $*OUT --> Nil) {
  my $pc = $p.chars;
  $s = "\n$s".split("\n").map({ ' ' x ($p.chars + 1) ~ $_ }).join("\n").trim;
  $pipe.say: "$p $s";
}

sub d(Str:D $s --> Nil) is export {
  s('[DBG]:', $s, :pipe($*ERR)) if $LL <= 0;
}
sub df(*@as --> Nil)    is export {
  s('[DBG]:', sprintf(|@as), :pipe($*ERR)) if $LL <= 0;
}
sub l(Str:D $s --> Nil) is export {
  s('[LOG]:', $s, :pipe($*ERR)) if $LL <= 1;
}
sub lf(*@as --> Nil)    is export {
  s('[LOG]:', sprintf(|@as), :pipe($*ERR)) if $LL <= 1;
}
sub w(Str:D $s --> Nil) is export {
  s('[WRN]:', $s, :pipe($*ERR)) if $LL <= 2;
}
sub wf(*@as --> Nil) is export {
  s('[WRN]:', sprintf(|@as), :pipe($*ERR)) if $LL <= 2;
}
sub e(*@as --> Nil) is export {
  s('[ERR]:', sprintf(|@as), :pipe($*ERR)) if $LL <= 3;
}
sub ef(*@as --> Nil) is export {
  s('[ERR]:', sprintf(|@as), :pipe($*ERR)) if $LL <= 3;
}
sub p(Str:D $s --> Nil) is export {
  s('[PNC]:', $s, :pipe($*ERR)) if $LL <= 4;
  exit 1;
}
sub pf(*@as --> Nil) is export {
  s('[PNC]:', sprintf(|@as), :pipe($*ERR)) if $LL <= 4;
  exit 1;
}
sub message(Str:D $s --> Nil) is export {
  s('==>', $s) if $LL <= 4;
}
sub messagef(*@as --> Nil) is export {
  s('==>', sprintf |@as) if $LL <= 4;
}
sub problem(Str:D $s --> Nil) is export {
  s('!!>', $s, :pipe($*ERR)) if $LL <= 4;
}
sub problemf(*@as --> Nil) is export {
  s('!!>', sprintf(|@as), :pipe($*ERR)) if $LL <= 4;
}
