# frozen_string_literal: true

module Aoororachain
  module Loaders
    class DirectoryLoader
      def initialize(path:, glob:, loader:, parser: nil)
        @path = path
        @glob = glob
        @loader = loader
        @parser = parser
      end

      def load
        Dir.glob("#{@path}/#{@glob}").map { |file| @loader.load(file, parser: @parser) }
      end
    end
  end
end
