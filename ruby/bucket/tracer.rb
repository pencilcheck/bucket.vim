#coding: utf-8

module Bucket
  class Tracer
    EVENTS = [:return, :call, :line, :raise]

    def initialize path=Dir.pwd, options={}
      @path = path
      @history = []
      @callbacks = EVENTS.map {|event| self.send("tp_#{event.to_s}")}
      #@project_path = closest(:git) || ::VIM::pwd
    end

    def trace(filename)
      @curfile = filename
      #cb = VIM::Buffer.current
      #cbfn = cb.name
      #lines = (1..cb.length).to_a.map {|count| cb[count]}.join("\n")
      context = nil
      lines = "#coding: utf-8\n" + File.read(filename)
      lineno = 1
      enable
      #eval(lines, context, filename, lineno)
      disable
    end

    def list_variables
      @curline = ::VIM::evaluate("line('.')").to_i
      @history.select do |event|
        event[:lineno] == @curline and event[:path].start_with?(@path)
      end.map do |event|
        event[:local_variables]
      end[0]
    end

    private

    def tp_line
      TracePoint.new(:line) do |tp|
        #p tp.inspect
        #p "local: #{tp.binding.eval('local_variables').map {|var| {"#{var}" => tp.binding.eval(var.to_s)}}}"
        @history << {
          event: tp.event,
          global_variables: tp.binding.eval('global_variables').reduce({}) {|memo, global| memo[global] = tp.binding.eval(global.to_s); memo},
          local_variables: tp.binding.eval('local_variables').reduce({}) {|memo, local| memo[local] = tp.binding.eval(local.to_s); memo},
          binding: tp.binding,
          path: tp.path,
          lineno: tp.lineno
        }
      end
    end

    def tp_return
      TracePoint.new(:return) do |tp|
        #p tp.inspect
        #p "local: #{tp.binding.eval('local_variables').map {|var| {"#{var}" => tp.binding.eval(var.to_s)}}}"
        #p "return value: #{tp.return_value}"
        @history << {
          event: tp.event,
          global_variables: tp.binding.eval('global_variables').reduce({}) {|memo, global| memo[global] = tp.binding.eval(global.to_s); memo},
          local_variables: tp.binding.eval('local_variables').reduce({}) {|memo, local| memo[local] = tp.binding.eval(local.to_s); memo},
          binding: tp.binding,
          path: tp.path,
          lineno: tp.lineno,
          return_value: tp.return_value
        }
      end
    end

    def tp_call
      TracePoint.new(:call) do |tp|
        #p tp.inspect
        #p "local: #{tp.binding.eval('local_variables').map {|var| {"#{var}" => tp.binding.eval(var.to_s)}}}"
        @history << {
          event: tp.event,
          global_variables: tp.binding.eval('global_variables').reduce({}) {|memo, global| memo[global] = tp.binding.eval(global.to_s); memo},
          local_variables: tp.binding.eval('local_variables').reduce({}) {|memo, local| memo[local] = tp.binding.eval(local.to_s); memo},
          binding: tp.binding,
          path: tp.path,
          lineno: tp.lineno,
          return_value: tp.return_value
        }
      end
    end

    def tp_raise
      TracePoint.new(:raise) do |tp|
        #p tp.inspect
        #p "local: #{tp.binding.eval('local_variables').map {|var| {"#{var}" => tp.binding.eval(var.to_s)}}}"
        #p "exception: #{tp.raised_exception}"
        @history << {
          event: tp.event,
          global_variables: tp.binding.eval('global_variables').reduce({}) {|memo, global| memo[global] = tp.binding.eval(global.to_s); memo},
          local_variables: tp.binding.eval('local_variables').reduce({}) {|memo, local| memo[local] = tp.binding.eval(local.to_s); memo},
          binding: tp.binding,
          path: tp.path,
          lineno: tp.lineno,
          raise_exception: tp.raised_exception
        }
      end
    end

    def closest(dotfoldername, limit=10)
      # find the closest dot folder name from current dir
      dir = Dir.pwd
      limit.times do |level|
        Dir.entries(dir).any? do |entry|
          return dir if entry == dotfoldername.to_s and File.directory?(File.join(dir, entry)) and entry != '.' and entry != '..'
        end
        dir = File.expand_path('..', dir)
      end
      
      false
    end

    def enable
      @callbacks.each {|cb| cb.enable}
    end

    def disable
      @callbacks.each {|cb| cb.disable}
    end
  end
end
