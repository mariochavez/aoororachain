# frozen_string_literal: true

module Aoororachain
  module Loaders
    class FileLoader
      def self.load(file, parser: nil)
        text = File.read(file)
        metadata = {source: file}

        if !parser.nil?
          text, additional_metadata = parser.parse(text)
          Aoororachain::Util.log_debug("Extracted metadata using parser #{parser.class}", {additional_metadata:})
          metadata.merge!(additional_metadata)
        end

        Aoororachain::Util.log_debug("File loaded", {file:})
        [Document.new(text, metadata)]
      end
    end
  end
end
