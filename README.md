# Vim compatible tags file for dart.
> Now with native [Tagbar](https://github.com/majutsushi/tagbar) support!


## Example

### Install from pub
``` bash
$ pub global activate dart_ctags
```

### Install from Github
``` bash
$ git clone https://github.com/nerdrew/dart-ctags.git
$ cd dart-ctags
$ pub global activate -s path .
```

### Recommended Post-Installation

> The installation of the `dart_ctags` executable from pub is not a compiled
> binary.  These steps will overwrite the bash script placed by pub in the bin
> folder for dart_ctags with a natively compiled bin that is significantly
> faster.

##### Installed from pub

``` bash
$ cd $(find ~/.pub-cache/hosted -type d -name "dart_ctags*") && pub get
$ dart2native bin/tags.dart -o ~/.pub-cache/bin/dart_ctags
```

##### Installed from Github

``` bash
$ cd ~/git_repo_of_dart_ctags
$ dart2native bin/tags.dart -o ~/.pub-cache/bin/dart_ctags
```

### Use
``` bash
# make sure that pub-cache/bin is in your path
# export PATH="$PATH":"$HOME/.pub-cache/bin"

$ cd ~/dev/your-dart-project
$ dart_ctags -l -o .git/tags
```

## Help

``` bash
dart_ctags -h
Usage:
  dart_ctags [OPTIONS] [FILES...]
  pub global run dart_ctags:tags [OPTIONS] [FILES...]

-o, --output=<FILE>     Output file for tags (default: stdout)
    --follow-links      Follow symbolic links (default: false)
    --include-hidden    Include hidden directories (default: false)
-l, --line-numbers      Add line numbers to extension fields (default: false)
    --skip-sort         Skip sorting the output (default: false)
-h, --help              Show this help
```
