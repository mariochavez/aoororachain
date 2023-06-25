# frozen_string_literal: true

require "llm_client"

module Aoororachain
  module Llms
    class LlamaServer
      def initialize(host)
        LlmClient.host = host
        LlmClient.logger = Aoororachain.logger
        LlmClient.log_level = Aoororachain.log_level
      end

      def complete(prompt:)
        result = LlmClient.completion(prompt)

        [result.success?, result.success? ? result.success.body["response"].gsub(/Usuario:.*Asistente:/, "") : result.failure.message]
      end
    end
  end
end
