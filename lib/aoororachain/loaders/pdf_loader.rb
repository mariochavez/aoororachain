## frozen_string_literal: true

require "pdf/reader"

module Aoororachain
  module Loaders
    class PDFLoader
      def self.load(file, parser: nil)
        reader = PDF::Reader.new(file)
        documents = []

        base_metadata = {source: file, pages: reader.page_count}

        reader.pages.each do |page|
          metadata = base_metadata.dup
          metadata[:page] = page.number
          text = page.text

          if !parser.nil?
            text, additional_metadata = parser.parse(text)
            Aoororachain::Util.log_debug("Extracted metadata using parser #{parser.class}", {additional_metadata:})
            metadata.merge!(additional_metadata)
          end

          documents << Document.new(text, metadata)
        end

        Aoororachain::Util.log_debug("File loaded", {file:})
        documents
      end
    end
  end
end
