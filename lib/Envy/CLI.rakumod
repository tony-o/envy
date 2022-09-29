use Envy::Config;
use Envy::Util::CRC32;
use Envy::Util::Log;
use Envy::Util::Ls;

{ @*ARGS = set-ll-from-args(|@*ARGS); };

multi MAIN('help', Str:D $command = '') is export {
  if $command eq '' {
    say(qq:to/END/);
      Envy - A Raku Environment Manager

      USAGE
        
        envy [flags] command [args]

      COMMANDS
        
        version                 Displays the currently running version of Envy
        ls                      Lists all of the repositories controlled by Envy
        config                  Shows the current config formatted as JSON
        help <command>?         Displays help for the given command if available
        init <name>             Initializes a new virtual environment with id Envy#<name>
        enable [<name> ...]     Enables all of the repositories listed, this command
                                takes a comprehensive list of what you'd like enabled

      FLAGS

        --silent            Produces no output
        --debug             A lot of output that is useful while debugging
        --info              More output than --silent but less than --debug, sometimes

      CONFIGURATION

        config path = {config<config-path>}
        repo store  = {config<lib>}
        shim file   = {config<shim>}
    END
  } else {
    problemf('no help available for %s', $command);
    exit 1;
  }
}

multi MAIN('version') is export {
  say $?DISTRIBUTION.meta<ver>;
}

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
  my %enabled = ( enabled().map(* => 1) );
  ls().map({ message(%enabled{$_} ?? "+ $_" !! "- $_") });
}

multi MAIN('config') is export {
  say(to-json(config.hash));
}

sub show-shim(&c = &message) {
  my $bashrc = (".bashrc", ".bash_profile").first({try "$*HOME/$_".IO.f}) // '.bashrc';
  c(qq:to/END/);
RAKUDOLIB does not contain any Envy# entries in this environment

  for bash:
    echo 'source {config<shim>}' >> ~/{$bashrc}
    source ~/{$bashrc} 

  for zsh:
    echo 'source {config<shim>}' >> ~/.zshenv
    source ~/.zshenv
END
}

multi MAIN('enable', *@names ($, *@)) is export {
  if ! (%*ENV<RAKUDOLIB> // '').contains('Envy#') {
    show-shim(&w);
  }

  @names.push(|enabled());
  @names.=unique.sort;
 
  my %m = ( ls().map(* => 1) );
  my @ps = @names.grep({ %m{$_}:!exists });
  problemf('Repositories \'%s\' not initialized, please use `envy init \'%s\'` to initialize them',
           @ps.join('\', \''),
           @ps.join('\' \'')),
  exit 1
    if @ps.elems > 0;

  config<enabled>.IO.spurt: @names.join("\n");
  messagef('Enabled repositories: %s', @names.join(', '));
}

multi MAIN('disable', *@names ($, *@)) is export {
  if ! (%*ENV<RAKUDOLIB> // '').contains('Envy#') {
    show-shim(&w);
  }

  my @enabled = (enabled() (^) @names).keys.List;
  config<enabled>.IO.spurt: @enabled.join("\n");
  messagef('Disabled repositories: %s', @names.join(', '));
}
