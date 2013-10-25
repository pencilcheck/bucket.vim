require 'bucket/binding_window'
require 'bucket/prompt'
require 'bucket/tracer'
require 'bucket/vim'

module Bucket
  class Bucket
    def initialize
      @prompt = Prompt.new
      @tracer = Tracer.new
    end

    def show_binding_window
      # window that shows global and local variables of binding at
      # particular line with prompt used to query the binding
      @filename = ::VIM::evaluate('a:filename').strip
      @filename = ::VIM::evaluate("fnamemodify(bufname('%'), ':p')").strip if @filename.empty?
      @filename = File.expand_path(@filename, VIM::pwd) unless @filename.start_with?('/')
      @tracer.trace(@filename)
      show
    rescue Errno::ENOENT
      @binding_window.print_no_binding
    end

    def leave
      @binding_window.leave
    end

    def unload
      @binding_window.unload
    end

    private
    
    def list_variables
      @variables = @tracer.list_variables
      @binding_window.variables = @variables
    end

    def show
      @current_window = $curwin
      @current_buffer = $curbuf
      @binding_window = BindingWindow.new \
        :prompt => @prompt
      list_variables
    end

    def hide

    end
  end
end
