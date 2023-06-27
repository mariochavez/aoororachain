# frozen_string_literal: true

require "uri"
require "json"
require "logger"
require "forwardable"
require "open3"
require "tempfile"

require_relative "aoororachain/version"
require_relative "aoororachain/util"
require_relative "aoororachain/configuration"
require_relative "aoororachain/document"
require_relative "aoororachain/loaders/directory_loader"
require_relative "aoororachain/loaders/file_loader"
require_relative "aoororachain/loaders/pdf_loader"
require_relative "aoororachain/recursive_text_splitter"
require_relative "aoororachain/embeddings/local_python_embedding"
require_relative "aoororachain/vector_stores/chroma"
require_relative "aoororachain/vector_stores/retriever"
require_relative "aoororachain/llms/llama_server"
require_relative "aoororachain/chains/retrieval_qa"

module Aoororachain
  # map to the same values as the standard library's logger
  LEVEL_DEBUG = Logger::DEBUG
  LEVEL_ERROR = Logger::ERROR
  LEVEL_INFO = Logger::INFO

  @config = Aoororachain::Configuration.setup

  class << self
    extend Forwardable

    attr_reader :config

    # User configuration options
    def_delegators :@config, :log_level, :log_level=
    def_delegators :@config, :logger, :logger=
  end

  Aoororachain.log_level = ENV["AOORORACHAIN_LOG"].to_i unless ENV["AOORORACHAIN_LOG"].nil?
end
