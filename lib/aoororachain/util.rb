# frozen_string_literal: true

module Aoororachain
  module Util
    # Logs an error message with the given data using the provided Logger instance.
    #
    # message - A String message to be logged.
    # data - A Hash of additional data to be included in the log entry.
    #
    # Examples
    #
    #   Util.log_error("An error occurred", { user_id: 123, error_code: "404" })
    #
    # Returns nothing.
    def self.log_error(message, data = {})
      config = data.delete(:config) || Aoororachain.config
      logger = config.logger || Aoororachain.logger

      if (!logger.nil? || !config.log_level.nil?) && config.log_level <= Aoororachain::LEVEL_ERROR
        log_internal(message, data, level: Aoororachain::LEVEL_ERROR, logger: Aoororachain.logger)
      end
    end

    # Logs a debug message with the given data using the provided Logger instance.
    #
    # message - A String message to be logged.
    # data - A Hash of additional data to be included in the log entry.
    #
    # Examples
    #
    #   Util.log_debug("Debugging information", { user_id: 123, action: "update" })
    #
    # Returns nothing.
    def self.log_debug(message, data = {})
      config = data.delete(:config) || Aoororachain.config
      logger = config.logger || Aoororachain.logger

      if (!logger.nil? || !config.log_level.nil?) && config.log_level <= Aoororachain::LEVEL_DEBUG
        log_internal(message, data, level: Aoororachain::LEVEL_DEBUG, logger: Aoororachain.logger)
      end
    end

    # Logs an informational message with the given data using the provided Logger instance.
    #
    # message - A String message to be logged.
    # data - A Hash of additional data to be included in the log entry.
    #
    # Examples
    #
    #   Util.log_info("Processing request", { request_id: "abc123", route: "/users" })
    #
    # Returns nothing.
    def self.log_info(message, data = {})
      config = data.delete(:config) || Aoororachain.config
      logger = config.logger || Aoororachain.logger

      if (!logger.nil? || !config.log_level.nil?) && config.log_level <= Aoororachain::LEVEL_INFO
        log_internal(message, data, level: Aoororachain::LEVEL_INFO, logger: Aoororachain.logger)
      end
    end

    def self.log_internal(message, data = {}, level:, logger:)
      data_str = data.reject { |_k, v| v.nil? }.map { |(k, v)| "#{k}=#{v}" }.join(" ")

      logger&.log(level, "message=#{message} #{data_str}".strip)
    end
    private_class_method :log_internal
  end
end
