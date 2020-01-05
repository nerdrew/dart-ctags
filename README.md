# Vim compatible tags file for dart.  
> Now with full [Tagbar](https://github.com/majutsushi/tagbar) support!


## Example

### Install from repo
``` 
cd ~/dev/dart-ctags
pub global activate -s path .
```

### or Install from pub
```  
pub global activate dart_ctags
```

### Use
```
cd ~/dev/your-dart-project
pub global run dart_ctags:tags -o .git/tags
```

### Tagbar Config
```
let g:tagbar_type_dart = {
    \ 'ctagstype' : 'dart',
    \ 'kinds'     : [
        \ 'i:imports:1',
        \ 'C:consts',
        \ 'v:variables',
        \ 'F:functions',
        \ 'c:classes',
        \ 'r:constructors',
        \ 'f:fields',
        \ 'm:methods',
        \ 'M:static methods',
        \ 'o:operators',
        \ 'g:getters',
        \ 's:setters',
        \ 'a:abstract functions',
    \ ],
    \ 'sro' : '.',
    \ 'kind2scope' : {
        \ 'c' : 'class',
    \ },
    \ 'scope2kind' : {
        \ 'class' : 'c',
    \ },
    \ 'ctagsbin'  : 'pub',
    \ 'ctagsargs' : 'global run dart_ctags:tags -l'
\ }
```

## Help

```
pub global run dart_ctags:tags -h
Usage:
  pub global run dart_ctags:tags [OPTIONS] [FILES...]
  pub run tags.dart [OPTIONS] [FILES...]

-o, --output=<FILE>     Output file for tags (default: stdout)
    --follow-links      Follow symbolic links (default: false)
    --include-hidden    Include hidden directories (default: false)
-l, --line-numbers      Add line numbers to extension fields (default: false)
    --skip-sort         Skip sorting the output (default: false)
-h, --help              Show this help
```
