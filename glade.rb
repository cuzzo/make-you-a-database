#! /usr/bin/env ruby

class InsertError < StandardError; end
class FetchError < StandardError; end
class SqlSyntaxError < StandardError; end
class SelectError < StandardError; end
class PageOverflowError < StandardError; end

class Pager
  attr_reader :file
  attr_reader :file_length

  def initialize(file_path)
    mode = File.exists?(file_path) ? "r+" : "w+"
    @file = File.open(file_path, mode)
    @file_length = @file.size
    @pages = PAGE_COUNT.times.map { |_| nil }
  end

  def fetch(record_idx, record_size)
    page_num, page_offset = page_idx(record_idx, record_size)
    page = get_page(page_num)
    page.slice(page_offset * record_size, record_size)
  end

  def write(record_idx, record_size, record_bytes)
    page_num, page_offset = page_idx(record_idx, record_size)
    page = get_page(page_num)
    page[page_offset * record_size, record_size] = record_bytes
  end

  def close()
    # Write all data in the pages to disk
    @pages.each_with_index do |page, idx|
      next if page.nil?
      @file.seek(idx * PAGE_SIZE, IO::SEEK_SET)
      bytes_written = @file.write(page)
    end
    @file.close()
  end

  private

  # Get the page, and page_idx for a record idx
  def page_idx(idx, record_size)
    rows_per_page = PAGE_SIZE / record_size # Inteeger division

    page = idx / rows_per_page
    page_idx = idx % rows_per_page

    [page, page_idx]
  end

  def get_page(idx)
    raise PageOverflowError.new("Cannot insert more records.") if idx >= PAGE_COUNT

    if @pages[idx].nil? # Cache miss
      num_saved_pages = @file_length / PAGE_SIZE

      # partial page can be saved at end of file...
      if @file_length % PAGE_SIZE
        num_saved_pages += 1
      end

      # if page exists, read it...
      if idx <= num_saved_pages
        @file.seek(idx * PAGE_SIZE, IO::SEEK_SET)
        page = @file.read(PAGE_SIZE)
      end

      # TODO: This could overwrite data if there's an error.
      page ||= [0].pack("C") * PAGE_SIZE

      @pages[idx] = page
    end

    @pages[idx]
  end

  PAGE_SIZE = 4096 # Standard OS-level page size
  PAGE_COUNT = 1000
end

class Table
  attr_reader :pager

  def initialize(db_name)
    @pager = Pager.new(db_name)
    @count = @pager.file_length / RECORD_SIZE
  end

  def <<(obj)
    idx = count
    @pager.write(idx, RECORD_SIZE, serialize(obj))
    @count += 1
    idx
  end

  def [](idx)
    deserialize(@pager.fetch(idx, RECORD_SIZE))
  end

  def count()
    @count
  end

  def close()
    @pager.close()
  end

  private

  FORMAT = "DA64" # D[ecimal] A[rray]64
  RECORD_SIZE = 8 + 64 # Decimal (8, bytes) + A64 (Array, 64 bytes)


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
    $table.close()
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


$table = Table.new("prod.db")
if $PROGRAM_NAME == __FILE__
  while true do
    print_prompt()
    input = read_input()
    resp = parse(input)
    puts(resp)
  end
end
