unit module Envy::Config;
use Envy::Util::Log;

sub from-json($text) is export { ::("Rakudo::Internals::JSON").from-json($text) }
sub to-json($obj)    is export { ::("Rakudo::Internals::JSON").to-json($obj)    }

state $guess = (%*ENV<XDG_CONFIG_HOME>, "$*HOME/.config", "$*HOME").first({try $_.IO.d});
state $path = $guess.IO.child('/envy/config.json');
state $config = $path.IO.f
             ?? from-json($path.IO.slurp)
             !! { lib         => $guess.IO.child("envy/lib").IO.absolute,
                  config-path => $path.IO.absolute,
                  shim        => $guess.IO.child("envy/shim").IO.absolute,
                  path        => $guess.IO.child("envy").IO.absolute, };

df("config path: %s\njson: %s", $path, $config);

unless $config<path>.IO.d {
  df("making directory: %s", $config<path>);
  mkdir $config<path>.IO.absolute;
}

unless $path.IO.f {
  df("creating config: %s", $path);
  $path.IO.spurt: to-json($config);
}

unless $config<lib>.IO.d {
  df("making directory: %s", $config<lib>);
  mkdir $config<lib>.IO.absolute;
}

unless $config<shim>.IO.f {
  df("creating shim: %s", $config<shim>);
  $config<shim>.IO.spurt: 'export RAKUDOLIB=\'"Envy#."\'' ~ "\n";
}

sub config(--> Hash:D) is export { $config };
sub update-config(--> Nil) is export {
  $config<config-path>.IO.spurt: to-json($config);
}
