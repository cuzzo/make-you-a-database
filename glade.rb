#! /usr/bin/env ruby

class InsertError < StandardError; end
class FetchError < StandardError; end
class SqlSyntaxError < StandardError; end
class SelectError < StandardError; end
class PageOverflowError < StandardError; end

class Table
  attr_reader :data

  def initialize()
    @data = PAGE_COUNT.times.map { |_| [] }
    @count = 0
  end

  def <<(obj)
    idx = count
    page, page_idx = page_idx(idx)
    raise PageOverflowError.new("Cannot insert more records.") if page >= PAGE_COUNT

    record = serialize(obj)
    @data[page][page_idx] = record
    @count += 1

    idx
  end

  def [](idx)
    page, page_idx = page_idx(idx)
    raise PageOverflowError.new("Index is to high for select.") if page >= PAGE_COUNT
    deserialize(@data[page][page_idx])
  end

  def count()
    @count
  end

  private

  FORMAT = "DA64" # D[ecimal] A[rray]64
  RECORD_SIZE = 8 + 64 # Decimal (8, bytes) + A64 (Array, 64 bytes)
  PAGE_SIZE = 4096 # Standard OS-level page size
  ROWS_PER_PAGE = PAGE_SIZE / RECORD_SIZE # Inteeger division
  PAGE_COUNT = 1000

  # Get the page, and page_idx for a record idx
  def page_idx(idx)
    page = idx / ROWS_PER_PAGE
    page_idx = idx % ROWS_PER_PAGE
    [page, page_idx]
  end

  # Strings are 64 bytes
  def serialize(record)
    balance = Float(record[0])
    email = record[1][1...-1] # remove quotes
    [balance, email].pack(FORMAT)
  end

  def deserialize(bytes)
    bytes.unpack(FORMAT)
  end
end

def print_prompt()
  print("db > ")
end

def read_input()
  gets.chomp.downcase
end

def parse_meta_command(cmd)
  case cmd
  when "exit"
    exit
  else
    raise SqlSyntaxError.new("Unsupported metacommand: '#{cmd}'.")
  end
end

# serialize record to bytes.
### figure out byte size / format by schema
### standard OS page size = 4096 bytes (4kb)
# store bytes in array.
def execute_insert(record)
  $table << record
end

# move to position in memory.
# read size_of_record bytes.
# deserialize bytes to record.
def execute_select(id)
  $table[Integer(id)]
rescue
  raise StandardError.new(:SelectError)
end

def parse_statement(statement)
  tokens = statement.split(/\s+/)
  case tokens.first.downcase.to_sym
  when :select
    execute_select(tokens[1])
  when :insert
    execute_insert(tokens[1..-1])
  else
    raise SqlSyntaxError.new("Unspported statement: '#{statement}'.")
  end
end

def handle_error(e, str)
  $stderr.puts(e)
end

def parse(str)
  if str[0] == "."
    parse_meta_command(str[1..-1])
  else
    parse_statement(str)
  end
rescue => e
  handle_error(e, str)
end


$table = Table.new
if $PROGRAM_NAME == __FILE__
  while true do
    print_prompt()
    input = read_input()
    resp = parse(input)
    puts(resp)
  end
end
