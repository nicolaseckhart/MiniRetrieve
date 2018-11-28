require_relative 'retrieve'

class CliRunner
  attr_accessor :collection_file, :query_file

  def initialize(collection_file, query_file)
    check_file(:collection, collection_file)
    check_file(:query, query_file)

    self.collection_file = collection_file
    self.query_file = query_file
  end

  def check_file(name, file)
    exit_runner("#{name} file not found...", 1) if file == nil || !File.exists?(file)
    exit_runner("#{name} file isn't a .trec file...", 2) unless File.extname(file) == '.trec'
  end

  def exit_runner(message, status)
    puts message
    exit(status)
  end

  def run_mini_retrieve
    run_mini_retrieve = Retrieve.new(collection_file, query_file)
    run_mini_retrieve.run
  end
end

cli_runner = CliRunner.new(ARGV[0], ARGV[1])
cli_runner.run_mini_retrieve