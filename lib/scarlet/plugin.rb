require 'active_support/concern'
require 'active_support/core_ext/module/delegation'
require 'scarlet/listeners'
require 'scarlet/logger'
require 'scarlet/helpers/base_helper'

class Scarlet
  module Helpers
    extend ActiveSupport::Concern

    class_methods do
      def helpers
        @helpers ||= Module.new
      end

      def helper(*args, &block)
        args.each do |mod|
          helpers.module_eval { include mod }
        end

        helpers.module_eval(&block) if block_given?
      end
    end
  end

  class Context
    include Scarlet::Loggable
    attr_accessor :event

    def initialize event, *objs
      @event = event
      @objs = objs
    end

    def exec(&block)
      catch(:abort) { instance_exec(@event, &block) }
    rescue StandardError => ex
      logger.error ex.inspect
      logger.error ex.backtrace.join("\n")
    end

    def method_missing method, *args, &block
      @objs.each do |obj|
        next if !obj.respond_to? method
        return obj.__send__ method, *args, &block
      end
      super
    end
  end

  module Plugin
    extend ActiveSupport::Concern
    include Scarlet::Helpers
    include Scarlet::Loggable

    included do
      # ~
      helper Scarlet::BaseHelper
    end

    def emit(event)
      event.server.plugins.each do |plug|
        plug.handle event
      end
    end

    # Passes the event on to any event listeners that are listening for this command.
    # All events get passed to the +:all+ listener.
    # @param [Event] event The event that was recieved.
    def handle(event)
      self.class.__listeners__.each_listener(event.command) do |block|
        self.class.context.new(event.dup, self).exec(&block)
      end
    end

    class_methods do
      def context
        @_cxt ||= Class.new(Scarlet::Context).include(helpers)
      end

      def __listeners__
        @_listeners ||= Listeners.new
      end

      delegate :on, to: :__listeners__
    end
  end

  # Plugin namespace
  module Plugins; end
end
