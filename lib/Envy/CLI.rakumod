use Envy::Config;
use Envy::Util::CRC32;
use Envy::Util::Log;
use Envy::Util::Ls;

{ @*ARGS = set-ll-from-args(|@*ARGS); };

multi MAIN('init', Str() $name is copy) is export {
  CATCH { default { pf('a problem occurred: %s', $_,); } }
  my $base = config<path>.IO;
  unless $base.d {
    df('creating envy home: %s', $base.absolute);
    mkdir $base.absolute;
  }
  if $name eq '.' {
    $name = crc32_hex($*CWD.absolute);
  }
  my $lib = config<lib>.IO;
  unless $lib.d  {
    df('creating envy lib: %s', $lib.absolute);
    mkdir $lib.absolute;
  }
  my $dir = $lib.child("$name").IO;
  if $dir.d {
    lf("envy library already exists @ %s", $dir.absolute);
  } else {
    lf("creating library directory @ %s", $dir.absolute);
    mkdir $dir.absolute;
  }

  lf("to hardcode this repo into your environment add the following to your environment:\n  RAKUDOLIB='Envy#%s'",
     $name);
  lf("to install to this repo with zef use:\n  zef install --to='Envy#%s' <your modules>",
     $name);

  unless $dir.child('name').IO.f {
    df('creating %s', $dir.child('name').IO.absolute);
    $dir.child('name').IO.spurt($name);
  }
}

multi MAIN('ls') is export {
  CATCH { default { pf('a problem occurred: %s', $_,); } }
  ls().map(&message);
}

multi MAIN('config') is export {
  say(to-json(config.hash));
}

multi MAIN('enable', Bool :s(:$safe) = True, *@names ($, *@)) is export {
  w(qq:to/E/) unless (%*ENV<RAKUDOLIB>//'').index('Envy#');
RAKUDOLIB does not contain any Envy# entries in this environment

  for bash:
    echo 'source {config<shim>}' >> ~/{(".bashrc", ".bash_profile").first({try "$*HOME/$_".IO.f}) // ".bashrc"}

  for zsh:
    echo 'source {config<shim>}' >> ~/.zshenv
E
 
  my %m = ( ls().map(* => 1) );
  config<shim>.IO.spurt: @names.map({
    problemf('%s not found', $_) unless %m{$_};
    'export RAKUDOLIB="Envy#'~$_~', $RAKUDOLIB"'
  }).join("\n");
}
