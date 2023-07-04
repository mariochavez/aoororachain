# frozen_string_literal: true

module Aoororachain
  module Chains
    class RetrievalQA
      def initialize(llm, retriever, type: :stuff)
        @llm = llm
        @retriever = retriever
        @type = type
      end

      def complete(prompt:, prompt_template:)
        context = @retriever.search(prompt)

        stuff_prompt = prompt_template % {context: context.map(&:document).join(" ").tr("\n", " "), prompt:}

        success, response = @llm.complete(prompt: stuff_prompt)

        if success
          completion = {
            response: response,
            sources: context.map(&:metadata)
          }
        else
          completion = {
            response: "Sorry we had a problem with the LLM",
            sources: []
          }
          Aoororachain::Util.log_error("Failed to complete", message: response)
        end

        completion
      end
    end
  end
end
