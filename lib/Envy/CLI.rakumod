use Envy::Config;
use Envy::Util::CRC32;
use Envy::Util::Log;
use Envy::Util::Ls;
use Envy::Util::Dir;

{ @*ARGS = set-ll-from-args(|@*ARGS); };

multi MAIN('help', Str:D $command = '') is export {
  if $command eq '' {
    say(qq:to/END/);
      Envy - A Raku Environment Manager

      STATUS

        {"{%*ENV<RAKULIB>}:{%*ENV<RAKUDOLIB>}" ~~ m{(^||':')'Envy#'(':'||$)} ?? 'Enabled' !! 'Disabled'}

      USAGE
        
        envy [flags] command [args]

      COMMANDS
        
        version                 Displays the currently running version of Envy
        ls                      Lists all of the repositories controlled by Envy
        config                  Shows the current config formatted as JSON
        help <command>?         Displays help for the given command if available
        init [<name> ...]       Initializes a new virtual environment with id Envy#<name>
        enable [<name> ...]     Adds the names to the enabled repository list
        disable [<name> ...]    Removes the names from the enabled repository list
        destroy [<name> ...]    Destroys the the repository and purges the records

      FLAGS

        --silent            Produces no output
        --debug             A lot of output that is useful while debugging
        --info              More output than --silent but less than --debug, sometimes

      CONFIGURATION

        config path = {config<config-path>}
        repo store  = {config<lib>}
        shim file   = {config<shim>}
    END
  } elsif $command eq 'init' {
    say(qq:to/END/);
      Envy - A Raku Environment Manager

      envy [-e|--enable] init [<names> ...]

      This command will initialize repos with the names provided.  The `-e` or `--enable` flag
      will automatically enable the repos after initializing.  Ex.

      \$ envy -e init aaa bbb ccc
      ==> created aaa
          to install to this repo with zef use:
            zef install --to='Envy#aaa' <your modules>
      ==> created bbb
          to install to this repo with zef use:
            zef install --to='Envy#bbb' <your modules>
      ==> created ccc
          to install to this repo with zef use:
            zef install --to='Envy#ccc' <your modules>
      ==> Enabled repositories: aaa, bbb, ccc 
    END
  } elsif $command eq 'destroy' {
    say(qq:to/END/);
      Envy - A Raku Environment Manager
      
      destroy [<name> ...]

      Destroys the repository. This will automatically disable the repository if it's
      presently enabled and will remove the repository. Use this if you'd like to
      remove the repository from the system.  To reset a repository you'd use this
      command followed by an init.
    END
  } elsif $command ~~ 'enable'|'disable' {
    say(qq:to/END/);
      Envy - A Raku Environment Manager

      enable [<name> ...]     Adds the names to the enabled repository list
      disable [<name> ...]    Removes the names from the enabled repository list

      These commands enable or disable the repositories for the system.  This action
      is not localized to a session or terminal window and will affect any raku
      processes that are started with the `Env#` repository enabled after this command.
    END
  } elsif $command eq 'help' {
    say(qq:to/END/);
      __/\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\__/\\\\\\\\\\_____/\\\\\\__/\\\\\\________/\\\\\\__/\\\\\\________/\\\\\\_
       _\\/\\\\\\///////////__\\/\\\\\\\\\\\\___\\/\\\\\\_\\/\\\\\\_______\\/\\\\\\_\\///\\\\\\____/\\\\\\/__
        _\\/\\\\\\_____________\\/\\\\\\/\\\\\\__\\/\\\\\\_\\//\\\\\\______/\\\\\\____\\///\\\\\\/\\\\\\/____
         _\\/\\\\\\\\\\\\\\\\\\\\\\_____\\/\\\\\\//\\\\\\_\\/\\\\\\__\\//\\\\\\____/\\\\\\_______\\///\\\\\\/______
          _\\/\\\\\\///////______\\/\\\\\\\\//\\\\\\\\/\\\\\\___\\//\\\\\\__/\\\\\\__________\\/\\\\\\_______
           _\\/\\\\\\_____________\\/\\\\\\_\\//\\\\\\/\\\\\\____\\//\\\\\\/\\\\\\___________\\/\\\\\\_______
            _\\/\\\\\\_____________\\/\\\\\\__\\//\\\\\\\\\\\\_____\\//\\\\\\\\\\____________\\/\\\\\\_______
             _\\/\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\_\\/\\\\\\___\\//\\\\\\\\\\______\\//\\\\\\_____________\\/\\\\\\_______
              _\\///////////////__\\///_____\\/////________\\///______________\\///________
    END
  } else {
    problemf('no help available for %s', $command);
    exit 1;
  }
}

multi MAIN('version') is export {
  say $?DISTRIBUTION.meta<ver>;
}

multi MAIN('destroy', *@names is copy) is export {
  CATCH { default { pf('a problem occurred: %s', $_,); } }
  my @four04 = (@names (-) ls()).keys;

  problemf('%s repo does not exist, refusing to proceed', @four04.join(', ')),
  exit 1
    if @four04.elems > 0;

  MAIN('disable', |@names);
  for @names -> $n {
    rmd(config<lib>.IO.child($n).IO);
  };
  messagef('Destroyed repositories: %s', @names.join(', '));
}

multi MAIN('init', Bool:D :e(:$enable) = False, *@names is copy) is export {
  CATCH { default { pf('a problem occurred: %s', $_,); } }
  my %exists = ( ls().map(* => 1) );

  my @errs = @names.grep({%exists{$_}:exists});

  problemf('%s repo%s already exist%s, refusing to proceed',
           @errs.join(', '),
           @errs.elems == 1 ?? '' !! 's',
           @errs.elems == 1 ?? 's' !! ''),
  exit 1
    if @errs.elems > 0;

  my $base = config<path>.IO;
  for @names -> $name {
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

    messagef("created %s\nto install to this repo with zef use:\n  zef install --to='Envy#%s' <your modules>", $name, $name);

    unless $dir.child('name').IO.f {
      df('creating %s', $dir.child('name').IO.absolute);
      $dir.child('name').IO.spurt($name);
    }
  }
  MAIN('enable', |@names) if $enable;
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

  my @enabled = (enabled() (^) @names).keys.sort.List;
  config<enabled>.IO.spurt: @enabled.join("\n");
  messagef('Disabled repositories: %s', @names.join(', '));
}
