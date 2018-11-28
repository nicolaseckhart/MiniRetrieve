require 'nokogiri'
require 'stemmify'

class Document
  attr_accessor :id, :tokens

  def initialize(document_xml, stop_words)
    self.id = document_xml.xpath('recordId').text
    self.tokens = sanitize_and_tokenize(document_xml.xpath('text').text, stop_words)
  end

  private

  def sanitize_and_tokenize(content, stop_words)
    content.gsub!(/[^a-zA-Z0-9:]/i, ' ').split(' ').map do |t|
      token = t.stem
      stop_words.include?(token) ? nil : token
    end.compact
  end
end