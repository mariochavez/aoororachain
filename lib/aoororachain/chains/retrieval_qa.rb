# frozen_string_literal: true

module Aoororachain
  module Chains
    class RetrievalQA
      def initialize(llm, retriever, type: :stuff)
        @llm = llm
        @retriever = retriever
        @type = type
      end

      def complete(prompt:, prompt_template:, additional_context: "")
        context = @retriever.search(prompt)

        mapped_context = context.map(&:document)
        mapped_context << additional_context if !additional_context.nil? || additional_context != ""

        stuff_prompt = prompt_template % {context: mapped_context.join(" ").tr("\n", " "), prompt:}

        success, response = @llm.complete(prompt: stuff_prompt)

        if success
          completion = {
            "sources" => context.map(&:metadata)
          }.merge(response)
        else
          completion = {
            "response" => "Sorry we had a problem with the LLM",
            "sources" => [],
            "model" => ""
          }
          Aoororachain::Util.log_error("Failed to complete", message: response)
        end

        completion
      end
    end
  end
end
