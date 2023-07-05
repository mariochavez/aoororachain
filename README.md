# Aoororachain

Aoororachain is Ruby chain tool to work with LLMs.

## Installation

Install the gem and add to the application’s Gemfile by executing:

```bash
$ bundle add aoororachain
```

If bundler is not being used to manage dependencies, install the gem by executing:

```bash
$ gem install aoororachain
```

## Requisites

Aoororachain was primarily created to work locally with private data and Open Source LLMs. If you are looking for a tool to integrate OpenAI or any other service, there are a handful of tools to do it in Ruby, Python, or Javascript in Github.

With this in mind, a few requisites are needed before you start working in a chain.

* Llama.cpp. First, you need to setup [llama.cpp](https://github.com/ggerganov/llama.cpp), an inference tool for the Llama model.
* LLM Server. [LLM Server](https://github.com/mariochavez/llm_server) is a Ruby server that exposes *llama.cpp* via an API interfase.
* Open Source LLM model. Refer to *llama.cpp* or *LLM Server* for options to download an Open Source model. Llama, Open Llama or Vicuna models are good models to start.
* Chroma DB. [Chroma DB]( [https://www.trychroma.com/](https://www.trychroma.com/) ) is an Open Source Vector database for document information retrieval.
* Python environment. Aoororachain uses Open Source embedding models. It uses by default any of `hkunlp/instructor-large`, `hkunlp/instructor-xl`, and `sentence-transformers/all-mpnet-base-v2`.

### Python environment and Open Source embedding models.

You can install a Python environment using [miniconda](https://docs.conda.io/en/latest/miniconda.html). Here are the instructions for using it and installing additional dependencies and the Embedding models.

```bash
# This assumes installing miniconda on MacOS with Homebrew. If you use a different OS, follow the instructions on miniconda website.
$ brew install miniconda
# Initialize miniconda with your shell. Restart your shell for this to take effect.
$ conda init zsh
# After the shell restarts, create an environment and set Python version.
$ conda create -n llm python=3.9
# Now activate your new environment
$ conda activate llm
# Install Embedding models dependencies
$ pip -q install langchain sentence_transformers InstructorEmbedding
```

The next step is to install the Embedding model or models you want to use. Here are the links to each model.

* [hkunlp/instructor-xl](https://huggingface.co/hkunlp/instructor-xl). 5Gb.
* [hkunlp/instructor-large](https://huggingface.co/hkunlp/instructor-large). 1.34Gb
* [sentence-transformers/all-mpnet-base-v2](https://huggingface.co/sentence-transformers/all-mpnet-base-v2). 438Mb

To install any models, execute the following code in a Python repl. Replace *MODEL* with the name of the model. _Be aware that this will download the model from Internet._

```python
from InstructorEmbedding import INSTRUCTOR
          from langchain.embeddings
import HuggingFaceInstructEmbeddings

instructor_embeddings = HuggingFaceInstructEmbeddings(model_name="MODEL")

instructor_embeddings.embed_documents(list("Hello Ruby!"))
```

You can skip this step, but Aoororachain will download the specified model on the first run.

## Usage

Aoororachain currently focused on QA Retrieval for your own documents. Hence, let's start with how to create embeddings for a set of documents.

### Document embeddings

Being able to QA your documents requires texts to be converted to numbers. These numbers are organized in vectors; they capture the word features and correlations in sentences. This is helpful when a question is asked and, through the vector, a program can find texts that are similar to the question asked.

The similar texts can then be sent to a Large Language Model (LLM) to make sense of them and produce a response in Natural Language Process (NLP).

Due to the context size limit of LLMs you can feed them a huge document for QA Retrieval, you need to chunk large texts into meaningful blocks. This process is part of the embedding creation process.

The process looks like the following: 

1. Load documents—in this example, Ruby 3.2 documentation from 9,747 text files.

This is an example of one of the 9,747 text files:

```ruby
Object Array
Method collect
Method type instance_method
Call sequence ["array.map {|element| ... } -> new_array\narray.map -> new_enumerator"]
Source code 3.2:ruby-3.2.0/array.c:3825

Calls the block, if given, with each element of self; returns a new Array whose elements are the return values from the block:

a = [:foo, 'bar', 2]
a1 = a.map {|element| element.class }
a1 # => [Symbol, String, Integer]

Returns a new Enumerator if no block given:
a = [:foo, 'bar', 2]
a1 = a.map
a1 # => #

Array#collect is an alias for Array#map.
Examples static VALUE
rb_ary_collect(VALUE ary)
{
long i;
VALUE collect;

RETURN_SIZED_ENUMERATOR(ary, 0, 0, ary_enum_length);
collect = rb_ary_new2(RARRAY_LEN(ary));
for (i = 0; i < RARRAY_LEN(ary); i++) {
  rb_ary_push(collect, rb_yield(RARRAY_AREF(ary, i)));
}
return collect;
}
```

2. Chunk texts into meaningful blocks.
3. Create embeddings for texts.
4. Store embeddings in a vector database.

Aoororachain uses the Chroma vector database to store and query embeddings.

Here is an example for loading and creating the embeddings. 

```ruby
require "aoororachain"

# Setup logger.
Aoororachain.logger = Logger.new($stdout)
Aoororachain.log_level = Aoororachain::LEVEL_DEBUG

chroma_host = "http://localhost:8000"
collection_name = "ruby-documentation"

# You can define a custom Parser to clean data and maybe extract metadata.
# Here is the code of RubyDocParser that does exactly that.
class RubyDocParser
  def self.parse(text)
    name_match = text.match(/Name (\w+)/)
    constant_match = text.match(/Constant (\w+)/)
    
    object_match = text.match(/Object (\w+)/)
    method_match = text.match(/Method ([\w\[\]\+\=\-\*\%\/]+)/)
    
    metadata = {}
    metadata[:name] = name_match[1] if name_match
    metadata[:constant] = constant_match[1] if constant_match
    metadata[:object] = object_match[1] if object_match
    metadata[:method] = method_match[1] if method_match
    metadata[:lang] = :ruby
    metadata[:version] = "3.2"
    
    text.gsub!(/\s+/, " ").strip!
    [text, metadata]
  end
end

# A DirectoryLoader points to a path and sets the glob for the files you want to load. 
# A loader is also specified. FileLoader just opens and reads the file content. 
# The RubyDocParser is set as well. This is optional in case you data is very nice and needs no pre-processing.
directory_loader = Aoororachain::Loaders::DirectoryLoader.new(path: "./ruby-docs", glob: "**/*.txt", loader: Aoororachain::Loaders::FileLoader, parser: RubyDocParser)
files = directory_loader.load

# With your data clean and ready, now it is time to chunk it. The chunk size depends of the context size of the LLMs that you want to use.
# 512 is a good number to start, don't go lower than that. An overlap can also be specified.
text_splitter = Aoororachain::RecursiveTextSplitter.new(size: 512, overlap: 0)

texts = []
files.each do |file|
  texts.concat(text_splitter.split_documents(file))
end

# The final step is to create and store the embeddings.
# First, select an embedding model
model = Aoororachain::Embeddings::LocalPythonEmbedding::MODEL_INSTRUCTOR_L
# Create an instance of the embedder. device is optional. Possible options are:
# - cuda. If you have an external GPU
# - mps. If you have an Apple Sillicon chip (M1 to M2).
# - cpu or empty. It will use the CPU by default.
embedder = Aoororachain::Embeddings::LocalPythonEmbedding.new(model:, device: "mps")
# Configure your Vector database.
vector_database = Aoororachain::VectorStores::Chroma.new(embedder: embedder, options: {host: chroma_host})

# Embbed your files. This can take a few minutes up to hours, depending on the size of your documents and the model used.
vector_database.from_documents(texts, index: collection_name)
```

With embedding loaded in the database, you can use a tool like Chroma UI -**not yet released** - to query documents.
![chroma-ui](https://github.com/mariochavez/aoororachain/assets/59967/d65dea13-c6ef-452a-9774-8cf3b47c048f)

But it is more useful to query with Aoororachain.

```ruby
# Define a retriever for the Vector database.
retriever = Aoororachain::VectorStores::Retriever.new(vector_database)

# Query documents, results by default is 3.
documents = retriever.search("how can I use the Data class?", results: 4)

# Print retrieved documents and their similarity distance from the question.
puts documents.map(&:document).join(" ")
puts documents.map(&:distance)
```

### Query LLM with context.

With embeddings ready, it is time to create a _chain_ to perform QA Retrieval using the embedded documents as context.

```ruby
require "aoororachain"

# Setup logger.
Aoororachain.logger = Logger.new($stdout)
Aoororachain.log_level = Aoororachain::LEVEL_DEBUG

llm_host = "http://localhost:9292"
chroma_host = "http://localhost:8000"
collection_name = "ruby-documentation"

model = Aoororachain::Embeddings::LocalPythonEmbedding::MODEL_INSTRUCTOR_L
embedder = Aoororachain::Embeddings::LocalPythonEmbedding.new(model:, device: "mps")
vector_database = Aoororachain::VectorStores::Chroma.new(embedder: embedder, options: {host: chroma_host, log_level: Chroma::LEVEL_DEBUG})
vector_database.from_index(collection_name)

retriever = Aoororachain::VectorStores::Retriever.new(vector_database)

# Configure the LLM Server
llm = Aoororachain::Llms::LlamaServer.new(llm_host)

# Create the chain to connect the Vector database retriever with the LLM.
chain = Aoororachain::Chains::RetrievalQA.new(llm, retriever)

# Create a template for the LLM. Aoororachain does not include any templates because these are model specific. The following template is for the Vicuna model.
template = "A conversation between a human and an AI assistant. The assistant responds to a question using the context. Context: ===%{context}===. Question: %{prompt}"

response = chain.complete(prompt: "given the following array [[1,3], [2,4]], how can I get a flatten and sorted array?", prompt_template: template)
```

_response_ is a Hash with two keys: _response_ and _sources_.

```ruby
pp response
{:response=>
  "User: Assistant: Assistant: To flatten the nested arrays in an array and sort it, you can use Ruby's built-in `sort` method along with the `flatten` method. Here is an example of how to do this for the given array [[1, 3], [2, 4]]:\n" +
  "```ruby\n" +
  "array = [[1, 3], [2, 4]]\n" +
  "sorted_and_flattened_array = array.sort { |a, b| a[0] <=> b[0] }.flat_map(&:to_a)\n" +
  "# Output: [1, 2, 3, 4]\n" +
  "```\n",
 :sources=>
  [{"source"=>"./ruby-docs/hash-flatten.txt", "object"=>"Hash", "method"=>"flatten", "lang"=>"ruby", "version"=>"3.2"},
   {"source"=>"./ruby-docs/array-flatten.txt", "object"=>"Array", "method"=>"flatten", "lang"=>"ruby", "version"=>"3.2"},
   {"source"=>"./ruby-docs/array-flatten.txt", "object"=>"Array", "method"=>"flatten", "lang"=>"ruby", "version"=>"3.2"},
   {"source"=>"./ruby-docs/array-flatten2.txt", "object"=>"Array", "method"=>"flatten", "lang"=>"ruby", "version"=>"3.2"}]}
```

Where _response_ is tge generated response from the LLM and _sources_ is the list of text chunks that were sent to the LLM as context.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/mariochavez/aoororachain. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/mariochavez/aoororachain/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://github.com/mariochavez/aoororachain/blob/main/LICENSE.txt).

## Code of Conduct

Everyone interacting in the Aoororachain project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/mariochavez/aoororachain/blob/main/CODE_OF_CONDUCT.md).
