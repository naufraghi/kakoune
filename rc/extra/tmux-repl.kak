# http://tmux.github.io/
# ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾

hook global KakBegin .* %{
    %sh{
        VERSION_TMUX=$(tmux -V)
        VERSION_TMUX=$(expr "${VERSION_TMUX}" : 'tmux \([0-9]*\).*')

        if [ -n "$TMUX" ]; then
            if [ "${VERSION_TMUX}" -gt 1 ]; then
                echo "
                    alias global repl tmux-repl-horizontal
                    alias global send-text _tmux-send-text
                "
            else
                echo "
                    alias global repl _tmux-repl-disabled
                    alias global send-text _tmux-repl-disabled
                "
            fi
        fi
    }
}

def -hidden -params 1..2 tmux-repl-impl %{
    %sh{
        if [ -z "$TMUX" ]; then
            echo "echo -color Error This command is only available in a tmux session"
            exit
        fi
        tmux_args="$1"
        shift
        tmux_cmd="$@"
        tmux $tmux_args $tmux_cmd
        tmux set-buffer -b kak_repl_window $(tmux display-message -p '#I')
        tmux set-buffer -b kak_repl_pane $(tmux display-message -p '#P')
    }
}

def tmux-repl-vertical -params 0..1 -command-completion -docstring "Create a new vertical pane in tmux for repl interaction" %{
    tmux-repl-impl 'split-window -v' %arg{@}
}

def tmux-repl-horizontal -params 0..1 -command-completion -docstring "Create a new horizontal pane in tmux for repl interaction" %{
    tmux-repl-impl 'split-window -h' %arg{@}
}

def tmux-repl-window -params 0..1 -command-completion -docstring "Create a new window in tmux for repl interaction" %{
    tmux-repl-impl 'new-window' %arg{@}
}

def -hidden _tmux-send-text -docstring "Send selected text to the repl pane in tmux" %{
    nop %sh{
        tmux set-buffer -b kak_selection "${kak_selection}"
        kak_orig_window=$(tmux display-message -p '#I')
        kak_orig_pane=$(tmux display-message -p '#P')
        tmux select-window -t:$(tmux show-buffer -b kak_repl_window)
        tmux select-pane -t:.$(tmux show-buffer -b kak_repl_pane)
        tmux paste-buffer -b kak_selection
        tmux select-window -t:${kak_orig_window}
        tmux select-pane -t:.${kak_orig_pane}
    }
}

def -hidden _tmux-repl-disabled %{ %sh{
    VERSION_TMUX=$(tmux -V)
    printf %s "echo -color Error %{The version of tmux is too old: got ${VERSION_TMUX}, expected >= 2.x}"
} }
