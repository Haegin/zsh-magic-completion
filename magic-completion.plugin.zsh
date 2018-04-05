#
# Set up completion
#
# Copyright © 1994–2017 martin f. krafft <madduck@madduck.net>
# Released under the terms of the Artistic Licence 2.0
#
# Source repository: http://git.madduck.net/v/etc/zsh.git
#

### INITIALISATION

zstyle :compinstall filename "$ZDOTDIR/zshrc/80-completion"

autoload -Uz compinit
compinit -d $ZVARDIR/comp-$HOSTS

# load fancy completion list and menu handler
zmodload zsh/complist

# avoid old-style completion (compctl)
zstyle ':completion:*' use-compctl false

# cache results
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path $ZVARDIR/compcache-${HOST}

### OPTIONS

# show the list of completions right away when there's an ambiguous prefix
# note that there's also the 'list' zstyle, which could override this
setopt auto_list
setopt no_list_ambiguous

# use menu after the second completion request
# cf. also the 'menu' zstyle, which eclipses this
setopt auto_menu

# these mess with the aforementioned behaviour, make sure they're off
setopt no_menu_complete no_bash_auto_list

# make the completion list smaller by printing the matches in columns with
# different widths.
setopt list_packed

# do not recognise exact matches even if they're ambiguous
# (we don't want this because /var/log/sys<tab> should also
# offer /var/log/syslog…)
setopt no_rec_exact

# move cursor to end of word being completed
setopt always_to_end

# be magic about adding/removing final characters on tab completion
setopt auto_param_keys auto_param_slash auto_remove_slash

# allow completion to happen in the middle of a word
setopt complete_in_word

### COMPLETERS

# set the list of completers
zstyle ':completion:*' completer \
  _expand_alias _expand \
  _complete _prefix:-complete \
  _approximate _prefix:-approximate \
  _match _ignored
zstyle ':completion:*:prefix-complete:*' completer _complete
zstyle ':completion:*:prefix-approximate:*' completer _approximate

# configure the _expand completer
bindkey '^i' complete-word
zstyle ':completion::expand:*' tag-order 'expansions all-expansions original'

# do approximated completion, allowing 1 error per three characters
zstyle ':completion:*:approximate:' max-errors 'reply=( $((($#PREFIX+$#SUFFIX)/3 )) numeric )'

### TRIM OUTPUT OF IGNORED PATTERNS

# functions which start with _ are internal and ignored
zstyle ':completion:*:*:-command-:*' tag-order 'functions:-non-comp'
zstyle ':completion:*:functions-non-comp' ignored-patterns '_*'

# ignore working and backup copies, and compiled objects
zstyle ':completion:*:argument-rest:' file-patterns '
  *(-/):directories:directories
  (*.(ba#k|old)|*~):backup-files:"backup files"
  *.(l#[oa]|py[co]|zwc):compiled-files:"compiled files"
  *.te#mp:temp-files:"temp files"
  .*.sw?:vim-swap-files:"vim swap files"
  %p:globbed-files *:all-files
  '
zstyle ':completion:*:argument-rest:(all|globbed)-files' ignored-patterns \
  '((*.(ba#k|old)|*~)|*.(l#[oa]|py[co]|zwc)|*.te#mp|.*.sw?|*(-/))'
#TODO directories not ignored in files output:
####  fishbowl:/tmp/cdt.6kIDed% cat <tab>
####  directories
####  foobar/
####  backup files
####  foo.bk                     foo.old
####  compiled files
####  foo.a    foo.la   foo.lo   foo.o    foo.pyc  foo.zwc
####  temp files
####  foo.tmp
####  files
####  foobar/      foo.c        foo.txt

#zstyle ':completion:*:argument*' tag-order "
#  globbed-files files all-files
#  directories
#  backup-files
#  compiled-files
#  temp-files
#  vim-swap-files
#  "
zstyle ':completion:*:argument*' group-order \
  vim-swap-files \
  globbed-files files all-files \
  directories \
  backup-files \
  compiled-files \
  temp-files \
#end
#TODO no effect on ordering yet

zstyle ':completion:*:argument*' group-order vim-swap-files directories \
  globbed-files files all-files backup-files compiled-files temp-files

resource() { source $ZDOTDIR/zshrc/80-completion; zle -M "resourced"; }
zle -N resource
bindkey '\er' resource

# do not offer files already specified on the line
zstyle ':completion:*:rm' ignore-line yes

# do not offer current directory as completion in ../
zstyle ':completion:*' ignore-parents parent pwd

# http://xana.scru.org/2005/08/20#ignorelatexjunk
zstyle -e ':completion:*:*:vim#' ignored-patterns \
  'texfiles=$(echo ${PREFIX}*.tex); [[ -n "$texfiles" ]] &&
  reply=(*.(aux|dvi|log|p(s|df)|bbl|toc|lo[tf]|latexmain)) || reply=()'

### LOOK & FEEL

# Take advantage of $LS_COLORS for completion as well.
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# List directories first/in a separate group
zstyle ':completion:*' list-dirs-first yes

# Use a less ambiguous list separator
zstyle ':completion:*' list-separator '::'

# allow cursor-key navigation through completion set
zstyle ':completion:*' menu select

# always offer the original string as a completion choice
zstyle ':completion:*:match:*' original true

# squash multiple slashes to one, which is the unix-style
zstyle ':completion:*' squeeze-slashes true

# Formatting of completion menu/list
zstyle ':completion:*' verbose yes
zstyle ':completion:*' auto-description 'missing description: %d'
zstyle ':completion:*:descriptions' format '%B%d%b'
zstyle ':completion:*:messages' format '%d'
zstyle ':completion:*:warnings' format 'no matches for: %d'
zstyle ':completion:*:corrections' format "%B%d $fg[red](errors: %e)$reset_color%b"
#zstyle ':completion:*:matches' group 'yes'
zstyle ':completion:*' group-name ''

# Handle command-line options a bit differently
zstyle ':completion:*:options' auto-description '%d'
zstyle ':completion:*:options' description 'yes'

### KEYBINDINGS

# ^x^h :: provide context help, in addition to ^x h
bindkey '^x^h' _complete_help

### SPECIFIC COMMAND/CONTEXT HANDLING

# commands that take commands as arguments
compdef _precommand gdb
compdef _precommand nohup
compdef _precommand strace

# a couple commands don't yet have -option completion but
# they're generic GNU tools, so…
typeset -la gnu_generic_tools
gnu_generic_tools=(mv)
local c
for c ($gnu_generic_tools) compdef _gnu_generic $c

# custom path when expanding in the sudo context
zstyle ':completion:*:sudo:*' command-path /usr/local/sbin \
                                           /usr/local/bin  \
                                           /usr/sbin       \
                                           /usr/bin        \
                                           /sbin           \
                                           /bin            \
                                           /usr/X11R6/bin

# Completion of processes: show all user processes
zstyle ':completion:*:processes' command 'PS="ps -au$USER -o pid,tty,time,pcpu,cmd"; eval $PS | grep -v "$PS"'

# Integrate directory stack with cd -<tab> completion
zstyle ':completion:*:*:cd:*:directory-stack' menu yes select

# Offer .. as a special-dir to completions
zstyle -e ':completion:*' special-dirs '[[ $PREFIX = (../)#(|.|..) ]] && reply=(..)'
#TODO does not yet work

# complete manual by their section
zstyle ':completion:*:manuals' separate-sections true
zstyle ':completion:*:manuals.*' insert-sections false

# debbug #527301
zstyle ':completion::complete:xmms2:*:values' list-grouped false
zstyle ':completion::complete:xmms2:*:values' sort false

# vim:ft=zsh
