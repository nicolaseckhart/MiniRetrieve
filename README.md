# MiniRetrieve - N. Eckhart
Ruby implementation of the MiniRetrieve lab in Information Engineering 1 @ ZHAW. Contains english stopword removal
and token stemming.

## Install

```bash
gem install bundler
bundle install
```

## Run

The main class `retrieve.rb` contains some config variables like the result output file that can be configured.

```bash
ruby cli_runner.rb {collection_file} {query_file}

# trec files for collection and queries are included:
ruby cli_runner.rb irg_collection.trec irg_queries.trec
```