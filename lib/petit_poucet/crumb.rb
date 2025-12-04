# frozen_string_literal: true

module PetitPoucet
  class Crumb
    attr_reader :name, :path

    def initialize(name, path = nil, **options)
      @name = name

      if path.is_a?(Hash)
        options = path
        @path = nil
      else
        @path = path
      end

      @only_actions = options[:only] && Array(options[:only]).map(&:to_s)
      @except_actions = options[:except] && Array(options[:except]).map(&:to_s)
    end

    def resolve_name(context)
      case name
      when Proc then context.instance_exec(&name)
      when Symbol then context.public_send(name)
      else name.to_s
      end
    end

    def resolve_path(context)
      return nil if path.nil?

      case path
      when Proc then context.instance_exec(&path)
      when Symbol then context.public_send(path)
      else path.to_s
      end
    end

    def applies_to_action?(action_name)
      return false if @only_actions && !@only_actions.include?(action_name)
      return false if @except_actions&.include?(action_name)

      true
    end
  end
end
