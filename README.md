# nietaki's dotfiles

It's meant to be used with [homeshick](https://github.com/andsens/homeshick).
I'm automating it with [puter](https://github.com/nietaki/puter)

## TODO
- [x] move quickfix (copen) to lua
- [x] migrate overseer config to autoloaded files?
- [ ] try to optimize the opencode invocations
- [x] https://github.com/stevearc/overseer.nvim/blob/master/doc/recipes.md#asynchronous-make-similar-to-vim-dispatch
- [x] custom overseer component for killing old tasks
- [x] ~~raise an overseer issue on default/optional prompts~~
- [ ] ~test strategy working with overseer (see vimscript/git_stuff.vim for how it used to work)~
- [x] neotest https://github.com/stevearc/overseer.nvim/blob/master/doc/third_party.md#neotest
- [x] move (neo?) test mappings to lua
- [x] fix the TreeSitter issue when doing `K` in a lua config file

## what this thing does
- configure shell settings and environment with bash/zsh
- setup vim/neovim editor with plugins and linters
- configure tmux and terminal multiplexer
- define git user and alias configuration
- customize window manager with i3 and i3status
- manage tool versions with mise
- setup SSH client configuration
- style editor and language server settings
- configure AWS credentials and CLI settings
- install and configure custom fonts
