# envy

A nice utility for managing your dist environments. With this utility you can enable and disable certain module repositories without affecting the system wide repositories.  Each repo is self contained and can easily be reset/updated without affecting the system's modules.

## installation

```
$ zef install Envy
```

## usage

If you want to fill up your terminal with message, all of these commands will also take `--debug`, `--info`, `--silent`, `--loglevel=<Int>` flags.  `--silent` is only effective in commands where output is not required, `config` and `version` below both ignore this flag.

### zef install ...

To install modules to your named repo, you should use:

```
$ zef install --to='Envy#<name>' [<modules> ...]
```

The `to=` flag will let `zef` know which repository you'd like the module installed with.

### [-e|--enable = False] init [\<names> ...]

Allows you to initialize multiple repos for general use and the `-e` flag provides a shortcut for enabling all of the provided repos.

### ls

Displays the repos that are managed by `envy`.  A `+<name>` indicates the repo is enabled and a `-` prefix indicates a disabled repo.  Typical output:

```
~ envy ls
==> + a1
==> + a2
==> + a3
==> + b1
==> - dev
==> - my-project
==> - test
```

### enable [\<names> ...]

Enables the given repos system wide.

### disable [\<names> ...]

Disables the given repos system wide.

### destroy [\<names> ...]

Disables and then removes that repository from the file system.

### config

Displays the given config without any other marks so it can be piped to a formatter if desired.

### version

Displays the currently running version of envy.

### help [\<command>]

Command is optional, displays help for the given command or for envy in general.

## troubleshooting

By default no named repos are initialized or used. When you use Envy this way, it uses the `$*TMPDIR` as a repository.  This is effectively a no-op unless you go through the hassle of initializing and installing modules to that directory.
