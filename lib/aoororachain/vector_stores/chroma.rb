# frozen_string_literal: true

require "chroma-db"

module Aoororachain
  module VectorStores
    class Chroma
      DEFAULT_RESULTS = 3

      def initialize(embedder:, options: {})
        ::Chroma.connect_host = options.delete(:host)
        ::Chroma.logger = options.delete(:logger) || Aoororachain.logger
        ::Chroma.log_level = options.delete(:log_level) || Aoororachain.log_level

        @embedder = embedder
      end

      def from_documents(documents, index:, include_metadata: false)
        @store = ::Chroma::Resources::Collection.get_or_create(index, {embedder: @embedder.to_s})

        documents_embeddings = embed_documents(documents, include_metadata:)

        documents_embeddings.each do |batch|
          Aoororachain::Util.log_debug("Storing embeddings")
          @store.add(batch)
        end

        true
      end

      def from_index(index)
        @store = ::Chroma::Resources::Collection.get_or_create(index, {embedder: @embedder.to_s})

        true
      end

      def add(documents, include_metadata: false)
        documents_embeddings = embed_documents(documents, include_metadata:)

        documents_embeddings.each do |batch|
          Aoororachain::Util.log_debug("Storing embeddings")
          @store.add(batch)
        end

        true
      end

      def as_retriever(search_type: :similarity, results: DEFAULT_RESULTS)
        Aoororachain::VectorStores::Retriever.new(self, search_type:, similarity:, results:)
      end

      def similarity_search_by_vector(query, results: DEFAULT_RESULTS, filter: {})
        query(query_texts: query, results:, where: filter, include: %w[metadatas documents])
      end

      def similarity_search_with_score(query, results: DEFAULT_RESULTS, filter: {})
        query(query_texts: query, results:, where: filter)
      end
      alias_method :similarity_search, :similarity_search_with_score

      private

      def query(query_texts: "", results: DEFAULT_RESULTS, where: {}, include: %w[metadatas documents distances])
        embeddings = @embedder.embed_query(query_texts)
        Aoororachain::Util.log_debug("Query embeddings #{query_texts}", data: {embeddings:, results:, where:, include:})

        @store.query(query_embeddings: embeddings, results:, where:, include:)
      end

      def embed_documents(documents, include_metadata: false)
        documents_embeddings = @embedder.embed_documents(documents, include_metadata:)

        batch_size = 3_000
        index = 0

        documents.each_slice(batch_size).map do |batch|
          batch.map do |document|
            element = ::Chroma::Resources::Embedding.new(id: SecureRandom.uuid, embedding: documents_embeddings[index], metadata: document.metadata, document: document.content)
            index += 1
            element
          end
        end
      end
    end
  end
end
