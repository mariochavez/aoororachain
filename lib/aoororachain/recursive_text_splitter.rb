# frozen_string_literal: true

module Aoororachain
  class RecursiveTextSplitter
    def initialize(size: 1024, overlap: 200)
      @size = size
      @overlap = overlap
    end

    def split_documents(documents)
      original_documents = Array(documents)

      new_documents = []
      original_documents.each do |document|
        texts = split_text(document.content)
        texts.each do |text|
          new_documents << Document.new(text, document.metadata)
        end
      end

      new_documents
    end

    def split_text(text)
      split_recursive(text, 0, [])
    end

    private

    def split_recursive(text, start_index, chunks)
      # Base case: If the remaining word count is less than the chunk size, return the chunks
      if start_index + @size > text.length
        chunks << text[start_index..]
        return chunks
      end

      # Calculate the end index of the current chunk
      end_index = start_index + @size
      end_index += @overlap if start_index != 0

      # Add the current chunk to the array
      chunk = text[start_index...end_index]

      # Correct start and end indexes
      start_index_corrected = (start_index == 0) ? start_index : detect_first_whitespace_or_line_return_position(chunk)
      end_index_corrected = detect_last_whitespace_or_line_return_position(chunk)

      if start_index_corrected == end_index_corrected
        end_index_corrected = end_index
        chunks << chunk
      else
        chunks << chunk[start_index_corrected..end_index_corrected]&.strip
      end

      # Calculate the next start index with overlap
      next_start_index = end_index - @overlap - (@size - end_index_corrected)

      # Recursively split the remaining words
      split_recursive(text, next_start_index, chunks)
    end

    def detect_first_whitespace_or_line_return_position(string)
      position = string.index(/\s|\n/)
      position.nil? ? 0 : position
    end

    def detect_last_whitespace_or_line_return_position(string)
      position = string.rindex(/\s|\n/)
      position.nil? ? -1 : position
    end
  end
end
