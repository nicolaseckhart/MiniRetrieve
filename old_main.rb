# ================================================
# READ AND INDEX DOCUMENTS
# ================================================

files = Dir[ARGV[0] + '/*']
document_count = files.count

print "INDEXING DOCUMENTS:\t\t"
files.each do |file|
  file_tokens = []

  File.open(file, 'r') do |f|
    f.each_line do |line|
      words = line.gsub!(/[^a-zA-Z]/i, ' ').split(' ')
      file_tokens += words
    end
  end

  # build inverted and non-inverted index
  non_inverted_index[file] = FreqList.new
  file_tokens.each do |word|

    inverted_index[word] = FreqList.new unless inverted_index[word]
    inverted_index[word].append(file)
    inverted_index[word].increment_freq(file)

    non_inverted_index[file].append(word)
    non_inverted_index[file].increment_freq(word)
  end
end

puts " done\n"
print "CALCULATING IDF & DNORM:\t"

# ================================================
# CALCULATE IDF AND DNORM
# ================================================

non_inverted_index.keys.each do |file|
  d_norm[file] = 0.0

  non_inverted_index[file].list.keys.each do |word|
    idf[word] = Math.log((1 + files.count) / (1 + inverted_index[word].list.count))
    d_norm[file] += (non_inverted_index[file].list[word] * idf[word]) ** 2
  end

  d_norm[file] = Math.sqrt(d_norm[file])
end

puts " done\n"
print "INDEXING QUERIES:\t\t"

# ================================================
# READ AND INDEX QUERIES
# ================================================

files = Dir[ARGV[1] + '/*']
query_count = files.count

files.each do |file|
  query_tokens = []

  File.open(file, 'r') do |f|
    f.each_line do |line|
      words = line.gsub!(/[^a-zA-Z]/i, ' ').split(' ')
      query_tokens += words
    end
  end

  query_index[file] = FreqList.new
  query_tokens.each do |word|
    query_index[file].append(word)
    query_index[file].increment_freq(word)
  end
end

puts " done\n"
print "PROCESSING QUERIES:\t\t"

# ================================================
# PROCESS EACH QUERY
# ================================================

query_index.keys.each do |query|
  q_norm = 0
  accumulator = {}

  query_index[query].list.keys.each do |word|
    idf[word] = Math.log(1 + document_count) if idf[word].nil?

    b = query_index[query].list[word] * idf[word]
    q_norm += b ** 2

    unless inverted_index[word].nil?
      inverted_index[word].list.keys.each do |document|
        accumulator[document] = 0 if accumulator[document].nil?
        a = inverted_index[word].list[document] * idf[word]
        accumulator[document] += a * b
      end
    end
  end

  q_norm = Math.sqrt(q_norm)

  accumulator.keys.each do |document|
    accumulator[document] /= (d_norm[document] * q_norm)
  end

  results[query] = accumulator.sort_by {|_k, v| -v}.first(SAVED_RESULT_COUNT).to_h
end

puts " done\n"
print "WRITING RESULTS:\t\t"

# ================================================
# PRINT TOP 10 RESULTS FOR EACH QUERY
# ================================================

File.open(RESULTS_FILE, 'w') do |file|
  (1..query_count).each do |q|
    query = "queries/#{q}"
    results[query].keys.first(DISPLAYED_RESULTS_COUNT).each_with_index do |document, index|
      file.write [ q, 'Q0', index, document.gsub('documents/',''), results[query][document], SYS_NAME, "\n" ].join(' ')
    end
  end
end

puts ' done'