# frozen_string_literal: true

require "test_helper"

class TestRecursiveTextSplitter < Minitest::Test
  def setup
    RubyVM::InstructionSequence.compile_option = {
      tailcall_optimization: true,
      trace_instruction: false
    }
  end

  def test_it_initializes
    subject = Aoororachain::RecursiveTextSplitter.new

    assert_instance_of Aoororachain::RecursiveTextSplitter, subject
  end

  def test_it_split_text_no_overlap
    subject = Aoororachain::RecursiveTextSplitter.new(size: 510, overlap: 0)

    documents = subject.split_text(corpus_text)

    chunks, partial = corpus_text.size.divmod(510)
    chunks += 1 if partial > 0

    assert_equal chunks, documents.size
  end

  def test_it_split_text_with_overlap
    subject = Aoororachain::RecursiveTextSplitter.new(size: 510, overlap: 15)

    documents = subject.split_text(corpus_text)

    chunks, partial = corpus_text.size.divmod(510)
    chunks += 1 if partial > 0

    assert_equal chunks, documents.size
  end

  def test_it_split_documents_no_overlap
    subject = Aoororachain::RecursiveTextSplitter.new(size: 510, overlap: 0)

    original_documents = [Aoororachain::Document.new(corpus_text), Aoororachain::Document.new(corpus_text_2)]
    documents = subject.split_documents(original_documents)

    chunks_text_1, partial_text_1 = corpus_text.size.divmod(510)
    chunks_text_1 += 1 if partial_text_1 > 0

    chunks_text_2, partial_text_2 = corpus_text_2.size.divmod(510)
    chunks_text_2 += 1 if partial_text_2 > 0

    assert_equal chunks_text_1 + chunks_text_2, documents.size
  end

  def test_it_split_documents_with_overlap
    subject = Aoororachain::RecursiveTextSplitter.new(size: 510, overlap: 15)

    original_documents = [Aoororachain::Document.new(corpus_text), Aoororachain::Document.new(corpus_text_2)]
    documents = subject.split_documents(original_documents)

    chunks_text_1, partial_text_1 = corpus_text.size.divmod(510)
    chunks_text_1 += 1 if partial_text_1 > 0

    chunks_text_2, partial_text_2 = corpus_text_2.size.divmod(510)
    chunks_text_2 += 1 if partial_text_2 > 0

    assert_equal chunks_text_1 + chunks_text_2, documents.size
  end

  private

  def corpus_text
    <<~TEXT
      An Array is an ordered, integer-indexed collection of objects, called elements. Any object (even another array) may be an array element, and an array can contain objects of different types.

      Array Indexes
      Array indexing starts at 0, as in C or Java.

      A positive index is an offset from the first element:

      Index 0 indicates the first element.
      Index 1 indicates the second element.

      A negative index is an offset, backwards, from the end of the array:

      Index -1 indicates the last element.
      Index -2 indicates the next-to-last element.

      A non-negative index is in range if and only if it is smaller than the size of the array. For a 3-element array:

      Indexes 0 through 2 are in range.
      Index 3 is out of range.
      A negative index is in range if and only if its absolute value is not larger than the size of the array. For a 3-element array:

      Indexes -1 through -3 are in range.
      Index -4 is out of range.
      Although the effective index into an array is always an integer, some methods (both within and outside of class Array) accept one or more non-integer arguments that are integer-convertible objects.
    TEXT
  end

  def corpus_text_2
    <<~TEXT
      A String object has an arbitrary sequence of bytes, typically representing text or binary data. A String object may be created using String::new or as literals.

      String objects differ from Symbol objects in that Symbol objects are designed to be used as identifiers, instead of text or data.

      You can create a String object explicitly with:

      A string literal.
      A string literal.
      You can convert certain objects to Strings with:

      Method String.
      Some String methods modify self. Typically, a method whose name ends with ! modifies self and returns self; often a similarly named method (without the !) returns a new string.

      In general, if there exist both bang and non-bang version of method, the bang! mutates and the non-bang! does not. However, a method without a bang can also mutate, such as String#replace.

      Substitution Methods
      These methods perform substitutions:

      String#sub: One substitution (or none); returns a new string.
      String#sub!: One substitution (or none); returns self.
      String#gsub: Zero or more substitutions; returns a new string.
      String#gsub!: Zero or more substitutions; returns self.
      Each of these methods takes:

      A first argument, pattern (string or regexp), that specifies the substring(s) to be replaced.
      Either of these:
      A second argument, replacement (string or hash), that determines the replacing string.
      A block that will determine the replacing string.
      The examples in this section mostly use methods String#sub and String#gsub; the principles illustrated apply to all four substitution methods.

      Argument pattern

      Argument pattern is commonly a regular expression:
    TEXT
  end
end
