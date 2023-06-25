# frozen_string_literal: true

module Aoororachain
  module Embeddings
    class LocalPythonEmbedding
      MODEL_INSTRUCTOR_L = "hkunlp/instructor-large"
      MODEL_INSTRUCTOR_XL = "hkunlp/instructor-xl"
      MODEL_ALL_MPNET = "sentence-transformers/all-mpnet-base-v2"

      def initialize(options = {})
        @model = options.delete(:model) || MODEL_ALL_MPNET
        @device = options.delete(:device) || "cpu"

        Aoororachain::Util.log_info("Using", data: {model: @model, device: @device})
        Aoororachain::Util.log_info("This embedding calls Python code using system call. First time initialization might take long due to Python dependencies installation.")

        install_python_dependencies
      end

      def embed_documents(documents, include_metadata: false)
        texts = documents.map { |document| "#{document.content} #{include_metadata ? document.metadata.to_json : ""}.strip" }

        embeddings = embed_texts(texts)
        embeddings || []
      end

      def embed_texts(texts)
        return if texts.empty?

        Aoororachain::Util.log_info("First time usage might take long time due to models download.")
        texts_file_path = save_texts_to_file(texts)

        embeddings_file_path = embed_texts_python(texts_file_path)

        embeddings = load_embeddings(embeddings_file_path) if !embeddings_file_path.nil?
        embeddings || []
      end

      def embed_query(text)
        return [] if text.nil? || text.strip == ""

        Aoororachain::Util.log_info("First time usage might take long time due to models download.")
        [embed_text_python(text)]
      end

      def to_s
        "#{self.class} : #{@model} : #{@device}"
      end

      private

      def run_system(command)
        _, stdout, stderr, wait_thr = Open3.popen3(command)
        stdout_data = stdout.gets(nil)
        stdout.close
        stderr_data = stderr.gets(nil)
        stderr.close
        exit_code = wait_thr.value

        [stdout_data, stderr_data, exit_code]
      end

      def load_embeddings(file_path)
        embeddings = JSON.parse(File.read(file_path))
        delete_file(file_path)

        embeddings
      end

      def parse_output(data)
        delimiter = "========"
        parsed_text = data.split(delimiter).last.strip

        return nil if parsed_text.nil?
        JSON.parse(parsed_text)
      end

      def embed_text_python(text)
        command = <<~PYTHON
          python - << EOF
          from InstructorEmbedding import INSTRUCTOR
          from langchain.embeddings import HuggingFaceInstructEmbeddings

          instructor_embeddings = HuggingFaceInstructEmbeddings(model_name="#{@model}",
                                                                model_kwargs={"device": "#{@device}"})

          embeddings = instructor_embeddings.embed_query("#{text}")
          print("========")
          print(embeddings)
        PYTHON

        stdout_data, stderr_data, exit_code = run_system(command)

        if exit_code != 0
          Aoororachain::Util.log_error("Failed to embed documents: #{stderr_data}")
          return nil
        end

        Aoororachain::Util.log_debug("Text embedded")
        parse_output(stdout_data)
      end

      def embed_texts_python(texts_file_path)
        embeddings_file_path = "#{texts_file_path}.emb"

        command = <<~PYTHON
          python - << EOF
          import json
          from InstructorEmbedding import INSTRUCTOR
          from langchain.embeddings import HuggingFaceInstructEmbeddings

          instructor_embeddings = HuggingFaceInstructEmbeddings(model_name="#{@model}",
                                                                model_kwargs={"device": "#{@device}"})

          with open("#{texts_file_path}") as f:
              file_content = f.read()

          documents = json.loads(file_content)

          embeddings = instructor_embeddings.embed_documents(list(documents))

          with open("#{embeddings_file_path}", "w", encoding="utf-8") as file:
              json.dump(embeddings, file, ensure_ascii=False, indent=4)
          EOF
        PYTHON

        _, stderr_data, exit_code = run_system(command)

        if exit_code != 0
          Aoororachain::Util.log_error("Failed to embed documents: #{stderr_data}")
          return nil
        end

        Aoororachain::Util.log_debug("Documents embedded")
        embeddings_file_path
      end

      def delete_file(file_path)
        File.delete(file_path)
      rescue => ex
        Aoororachain::Util.log_error("Failed delete file #{file_path}", data: {exception: ex.to_s})
      end

      def save_texts_to_file(texts)
        temp_file = Tempfile.new("Aoororachain.embeddings")
        temp_file.write(texts.to_json)
        temp_file.close

        file_path = temp_file.path
        Aoororachain::Util.log_debug("Texts saved to #{file_path}.")

        file_path
      end

      def install_python_dependencies
        stdout_data, stderr_data, exit_code = run_system("pip -q install langchain sentence_transformers InstructorEmbedding")

        if exit_code != 0
          Aoororachain.log_error("Failed to install Python dependencies: #{stderr_data}")
          return false
        end

        Aoororachain::Util.log_debug("Python installed dependencies: #{stdout_data}")
        true
      end
    end
  end
end
