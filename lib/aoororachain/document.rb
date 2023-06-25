# frozen_string_literal: true

module Aoororachain
  class Document
    attr_reader :content, :metadata

    def initialize(content, metadata = {})
      @content = content
      @metadata = metadata
    end
  end
end
