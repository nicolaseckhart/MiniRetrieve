require_relative 'document'
require_relative 'freq_list'
require 'nokogiri'

class Retrieve
  SYS_NAME                = 'EckhartMiniRetrieve'
  RESULTS_FILE            = 'irg_results.txt'
  SAVED_RESULT_COUNT      = 1000
  DISPLAYED_RESULTS_COUNT = 10

  attr_accessor :collection, :queries, :inverted_index, :non_inverted_index, :query_index, :idf, :d_norm, :results,
                :document_count, :query_count, :stop_words

  def initialize(collection_file, query_file)
    @collection = File.open(collection_file) { |f| Nokogiri::XML(f) }
    @queries = File.open(query_file) { |f| Nokogiri::XML(f) }

    @inverted_index      = {}
    @non_inverted_index  = {}
    @query_index         = {}
    @idf                 = {}
    @d_norm              = {}
    @results             = {}

    @document_count      = 0
    @query_count         = 0

    @stop_words = []
    File.open('stopwords.txt', 'r') do |f|
      f.each_line do |line|
        @stop_words << line.strip
      end
    end
  end

  def run
    time_block('COLLECTION INDEXING') { index_collection }
    time_block('QUERY INDEXING') { index_queries }
    time_block('CALCULATION OF IDF & DNORM') { calculate_idf_d_norm }
    time_block('QUERY PROCESSING') { process_queries }
    time_block('SAVING OF RESULTS') { save_results }
  end

  def index_collection
    documents = @collection.xpath('//DOC')
    @document_count = documents.count

    documents.each do |document_xml|
      document = Document.new(document_xml, @stop_words)

      # build inverted and non-inverted index
      @non_inverted_index[document.id] = FreqList.new
      document.tokens.each do |word|
        @inverted_index[word] = FreqList.new unless @inverted_index[word]
        @inverted_index[word].append(document.id)
        @inverted_index[word].increment_freq(document.id)

        @non_inverted_index[document.id].append(word)
        @non_inverted_index[document.id].increment_freq(word)
      end
    end
  end

  def index_queries
    documents = @queries.xpath('//DOC')
    @query_count = documents.count

    documents.each do |document_xml|
      document = Document.new(document_xml, @stop_words)

      @query_index[document.id] = FreqList.new
      document.tokens.each do |word|
        @query_index[document.id].append(word)
        @query_index[document.id].increment_freq(word)
      end
    end
  end

  def calculate_idf_d_norm
    @non_inverted_index.keys.each do |file|
      @d_norm[file] = 0.0

      @non_inverted_index[file].list.keys.each do |word|
        @idf[word] = Math.log((1 + @document_count) / (1 + @inverted_index[word].list.count))
        @d_norm[file] += (@non_inverted_index[file].list[word] * @idf[word]) ** 2
      end

      @d_norm[file] = Math.sqrt(@d_norm[file])
    end
  end

  def process_queries
    @query_index.keys.each do |query|
      q_norm = 0
      accumulator = {}

      @query_index[query].list.keys.each do |word|
        @idf[word] = Math.log(1 + @document_count) if @idf[word].nil?

        b = @query_index[query].list[word] * @idf[word]
        q_norm += b ** 2

        unless @inverted_index[word].nil?
          @inverted_index[word].list.keys.each do |document|
            accumulator[document] = 0 if accumulator[document].nil?
            a = @inverted_index[word].list[document] * @idf[word]
            accumulator[document] += a * b
          end
        end
      end

      q_norm = Math.sqrt(q_norm)

      accumulator.keys.each do |document|
        accumulator[document] /= (@d_norm[document] * q_norm)
      end

      @results[query] = accumulator.sort_by {|_k, v| -v}.first(SAVED_RESULT_COUNT).to_h
    end
  end

  def save_results
    File.open(RESULTS_FILE, 'w') do |file|
      @results.each do |query, result|
        result.keys.first(DISPLAYED_RESULTS_COUNT).each_with_index do |document, index|
          file.write [ query, 'Q0', document, index, result[document]*10, SYS_NAME, "\n" ].join(' ')
        end
      end
    end
  end

  def time_block(description)
    print "STARTING #{description}: "
    start = Time.now
    yield
    finish = Time.now
    puts "done [#{finish - start}s]"
  end
end