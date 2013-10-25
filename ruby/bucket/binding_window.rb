module Bucket
  class BindingWindow
    WINNR = "__Bucket__"
    @@buffer = nil

    def initialize options={}
      left = !!::VIM::evaluate('g:bucket_left')
      split_location = left ? "topleft vertical " : "botright vertical "
      split_width = ::VIM::evaluate('g:bucket_width')

      if @@buffer
        ::VIM::command "silent! #{split_location} #{@@buffer.number}sbuffer"
        raise "Can't re-open #{WINNR} buffer" unless $curbuf.number == @@buffer.number
      else
        split_command = "silent! #{split_location} #{split_width}split #{WINNR}"
        [
          split_command,
          'setlocal filetype=bucket',   # set custom filetype
          'setlocal noreadonly',
          'setlocal buftype=nofile',    # buffer is not related to any file
          'setlocal bufhidden=hide',  # hide buf when no longer displayed
          'setlocal noswapfile',        # don't create a swapfile
          'setlocal nobuflisted',       # don't show up in the buffer list
          'setlocal nomodifiable',      # prevent manual edits
          'setlocal nolist',            # don't use List mode (visible tabs etc)
          'setlocal nowrap',            # don't soft-wrap
          'setlocal nocursorline',      # don't highlight line cursor is on
          'setlocal nospell',           # spell-checking off
          'setlocal textwidth=0',       # don't hard-wrap (break long lines)
          'setlocal nonumber',          # don't show line numbers
          'setlocal nofoldenable',      # don't enable folding
          'setlocal foldcolumn=0',      # don't enable folding
          'setlocal foldmethod&',       # don't enable folding
          'setlocal foldexpr&'          # don't enable folding
        ].each { |command| ::VIM::command command }

        # don't show the color column
        ::VIM::command 'setlocal colorcolumn=0' if VIM::exists?('+colorcolumn')

        # don't show relative line numbers
        ::VIM::command 'setlocal norelativenumber' if VIM::exists?('+relativenumber')

        # sanity check: make sure the buffer really was created
        raise "Can't find #{WINNR} buffer" unless $curbuf.name.match /#{WINNR}\z/
        @@buffer = $curbuf
      end

      # TODO: syntax coloring

      # TODO: do it for part of options if needed
      # perform cleanup using an autocmd to ensure we don't get caught out
      # by some unexpected means of dismissing or leaving the Bucket window
      # (eg. <C-W q>, <C-W k> etc)
      #::VIM::command 'autocmd! * <buffer>'
      #::VIM::command 'autocmd BufLeave <buffer> silent! ruby $bucket.leave'
      #::VIM::command 'autocmd BufUnload <buffer> silent! ruby $bucket.unload'

      @window = $curwin
    end

    def close
      # Unlisted buffers like those provided by Netrw, NERDTree and Vim's help
      # don't actually appear in the buffer list; if they are the only such
      # buffers present when Command-T is invoked (for example, when invoked
      # immediately after starting Vim with a directory argument, like `vim .`)
      # then performing the normal clean-up will yield an "E90: Cannot unload
      # last buffer" error. We can work around that by doing a :quit first.
      if ::VIM::Buffer.count == 0
        ::VIM::command 'silent quit'
      end

      # Workaround for upstream bug in Vim 7.3 on some platforms
      #
      # On some platforms, $curbuf.number always returns 0. One workaround is
      # to build Vim with --disable-largefile, but as this is producing lots of
      # support requests, implement the following fallback to the buffer name
      # instead, at least until upstream gets fixed.
      #
      # For more details, see: https://wincent.com/issues/1617
      if $curbuf.number == 0
        # use bwipeout as bunload fails if passed the name of a hidden buffer
        ::VIM::command 'silent! bwipeout! GoToFile'
        @@buffer = nil
      else
        ::VIM::command "silent! bunload! #{@@buffer.number}"
      end
    end

    def leave
      close
      unload
    end

    def unload

    end

    def variables= variables
      @variables = variables
      print_variables
    end

    private

    def print_variables
      if @variables.nil? or @variables.empty?
        print_error 'NO LOCAL VARIABLES'
      else
        unlock
        @variables.each.with_index(1) do |name, value, lineno|
          @@buffer[lineno] = "#{name} is #{value}"
        end
        lock
      end
    end

    def print_error msg
      unlock
      @@buffer[1] = "-- #{msg} -- "
      lock
    end

    def lock
      ::VIM::command 'setlocal nomodifiable'
    end

    def unlock
      ::VIM::command 'setlocal modifiable'
    end
  end
end
