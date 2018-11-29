require 'nokogiri'
require 'stemmify'
require_relative 'synonym_parser'

class Document
  attr_accessor :id, :tokens

  def initialize(document_xml, stop_words, type)
    self.id = document_xml.xpath('recordId').text
    self.tokens = remove_stop_words(sanitize_and_split(document_xml.xpath('text').text), stop_words)

    if type == :query
      self.extend(SynonymParser)
      synonym_tokens = []
      tokens.each do |token|
        synonyms = self.fetch_synonyms(token, 1)[:all]
        synonym_tokens += synonyms
      end
      self.tokens += synonym_tokens
    end

    self.tokens = stemmify(self.tokens)
  end

  private

  def sanitize_and_split(content)
    content.gsub!(/[^a-zA-Z0-9:]/i, ' ').split(' ').map do |t|
      t.length < 3 ? nil : t
    end.compact
  end

  def stemmify(content)
    content.map do |t|
      t.stem
    end
  end

  def remove_stop_words(content, stop_words)
    content.map do |t|
      stop_words.include?(t) ? nil : t
    end.compact
  end
end