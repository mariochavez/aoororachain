# frozen_string_literal: true

module Aoororachain
  # The Configuration class allows you to configure Aoororachain
  # It can be initialized directly calling #new method.
  #
  # Examples
  #
  #   configuration = Aoororachain::Configuration.new
  #   configurarion.logger = Logger.new($stdout)
  #
  # Or via a setup block.
  #
  # Examples
  #
  #   Aoororachain::Configuration.setup do |config|
  #     config.logger = Logger.new($stdout)
  #   end
  class Configuration
    # Sets the logger for the Aoororachain service client.
    #
    # Examples
    #
    #   config.logger = Logger.new(STDOUT)
    #
    # Returns the Logger instance.
    attr_accessor :logger
    # Sets the logger's log level for the Aoororachain service client.
    #
    # Examples
    #
    #   config.log_level = Aoororachain::LEVEL_INFO
    #
    # Returns the log level constant
    attr_accessor :log_level

    def self.setup
      new.tap do |instance|
        yield(instance) if block_given?
      end
    end

    def initialize
      @log_level = Aoororachain::LEVEL_INFO
    end
  end
end
