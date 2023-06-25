# frozen_string_literal: true

module Aoororachain
  module Chains
    class RetrievalQA
      def initialize(llm, retriever, type: :stuff)
        @llm = llm
        @retriever = retriever
        @type = type
      end

      def complete(prompt:)
        context = @retriever.search(prompt)

        system_prompt = "Una conversación entre un humano y un asistente de inteligencia artificial. El asistente response usando el contexto la pregunta. Si no sabes la respuesta, simplemente di que no sabes, no trates de inventar una."
        context_prompt = "Contexto: #{context.map(&:document).join(" ").tr("\n", " ")}"
        question_prompt = "Pregunta: #{prompt}"

        stuff_prompt = [system_prompt, context_prompt, question_prompt]
        success, response = @llm.complete(prompt: stuff_prompt.join(". "))

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
