require 'nokogiri'
require 'open-uri'

module SynonymParser
  SYNONYM_SERVICE = 'http://wordnetweb.princeton.edu/perl/webwn?c=1&sub=Change&o2=&o0=&o8=1&o1=1&o7=&o5=&o9=&o6=&o3=&o4=&i=-1&h=00000000&s='

  def fetch_synonyms(term, count)
    doc = Nokogiri::HTML(open("#{SYNONYM_SERVICE}#{term}"))

    synonyms = {
      nouns: [],
      verbs: [],
      adjectives: []
    }

    doc.xpath('//li').each do |syn|
      parsed_term = syn.text.gsub('S:', '')

      if parsed_term.include?('n')
        words = sanitize_and_split(parsed_term.gsub('(n)', ''))
        synonyms[:nouns] += filter_double_words(words)
      end

      if parsed_term.include?('v')
        words = sanitize_and_split(parsed_term.gsub('(v)', ''))
        synonyms[:verbs] += filter_double_words(words)
      end

      if parsed_term.include?('adj')
        words = sanitize_and_split(parsed_term.gsub('(adj)', ''))
        synonyms[:adjectives] += filter_double_words(words)
      end
    end

    limit(synonyms, count)
  end

  private

  def sanitize_and_split(term)
    term.gsub(/[^a-zA-Z,\s]/i, '').split(',')
  end

  def filter_double_words(words)
    words.map do |w|
      word = w.lstrip.rstrip
      word.include?(' ') ? nil : word
    end.compact
  end

  def limit(synonyms, count)
    {
        nouns: synonyms[:nouns].first(count),
        verbs: synonyms[:verbs].first(count),
        adjectives: synonyms[:adjectives].first(count),
        all: (synonyms[:nouns] + synonyms[:verbs] + synonyms[:adjectives])
    }
  end
end
