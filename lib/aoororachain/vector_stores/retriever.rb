# frozen_string_literal: true

module Aoororachain
  module VectorStores
    class Retriever
      attr_accessor :search_type, :results

      def initialize(vector_store, search_type: :similarity, results: 3)
        @vector_store = vector_store
        @search_type = search_type
        @results = results
      end

      def search(query, **options)
        results = options.delete(:results) || @results
        filter = options.delete(:filter) || {}

        if @search_type == :similarity
          @vector_store.similarity_search(query, results:, filter:)
        end
      end
    end
  end
end
