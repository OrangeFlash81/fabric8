# frozen_string_literal: true

require 'fabric8/output'
require 'fabric8/tool'
require 'fabric8/tool_dsl_context'
require 'fabric8/option_set'
require 'fabric8/fabric8file'

module Fabric8
  # The command-line interface for Fabric8.
  class Cli
    attr_accessor :tasks

    # Parses the arguments to create a new Cli instance.
    def initialize(args)
      # Get the tool name, and check it's actually a tool
      tool_name = args.shift
      if tool_name.nil?
        # Load the Fabric8file
        @tasks = Fabric8file.new.tasks
        return
      elsif tool_name.start_with?('-') 
        raise ArgumentError, 'Must specify a tool'
      end

      # Load the tool
      tool = Tool.new(tool_name)
    
      # Parse options
      options = []

      current_option = nil
      args.each do |arg|
        # If this is an option, create and push it, setting it as the current
        # option
        if arg.start_with?('--')
          option_name = arg.sub('--', '')

          current_option = Option.new(option_name, nil)
          options << current_option

          next
        # If this is a shorthand option, reject it
        elsif arg.start_with?('-')
          raise ArgumentError, "Shorthand options not supported (#{arg})"
        end

        # This must be an argument; if the current option isn't nil, then add 
        # it as the current option's value
        if current_option.nil?
          raise ArgumentError,
            "Unexpected argument '#{arg}' - are you missing quotes?"
        end

        current_option.value = arg
        current_option = nil # Only one value is allowed per option
      end

      # Add this as the only task
      @tasks = [Task.new(tool, options)]
    end

    # Runs the 'build' task of the given task.
    def run_build(task)
      tool = task.tool
      Output.out :info, "--- Begin #{tool.name} ---"

      option_set = OptionSet.new(task.options, tool)

      ToolDslContext.new(tool, option_set).build_handler.()
      Output.out :info, "---  End #{tool.name}  ---"
    end
  end
end