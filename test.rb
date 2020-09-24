require_relative "glade.rb"
require_relative "node.rb"
require "byebug"

describe "glade" do
  before(:each) do
    File.delete(db_name) if db_name != '/dev/null'  && File.exists?(db_name)
    $table = Table.new(db_name)
  end

  after(:each) do
    $table.close()
  end

  let(:db_name) { "/dev/null" }

  context "basic functionality" do
    it "inserts and retrieves a row" do
      result = parse_statement("INSERT 75.10 'yahn@google.com'")
      resp = parse_statement("SELECT #{result}")
      expect(resp[0]).to eq(75.10)
      expect(resp[1]).to eq("yahn@google.com")
    end

    it "inserts strings of fixed length" do
      long = "a" * 64 # String limit
      long_email = "#{long}@breaking.com"

      result = parse_statement("INSERT 0 '#{long_email}'")
      resp = parse_statement("SELECT #{result}")

      expect(resp[0]).to eq(0)
      expect(resp[1]).to eq(long)
    end
  end

  context "persistence" do
    let(:db_name) { "persist-tes.db" }

    it "persists rows" do
      result = parse_statement("INSERT 55 'persist@foreever.com'")

      $table.close()

      $table = Table.new(db_name)
      resp = parse_statement("SELECT #{result}")
      expect(resp[0]).to eq(55)
      expect(resp[1]).to eq("persist@foreever.com")
    end
  end


  it "inserts and retrieves multiple rows" do
    result1 = parse_statement("INSERT -15.25 'test@fakemail.com'")
    result2 = parse_statement("INSERT 100 'blah'")

    resp2 = parse_statement("SELECT #{result2}")
    resp1 = parse_statement("SELECT #{result1}")

    expect(resp2[0]).to eq(100)
    expect(resp2[1]).to eq("blah")

    expect(resp1[0]).to eq(-15.25)
    expect(resp1[1]).to eq("test@fakemail.com")
  end

  it "fails after limit is reached" do
    limit = 56 * 1000
    limit.times do |i|
      parse_statement("INSERT #{i} 'email-#{i}@gmail.com'")
    end

    expect {
      parse_statement("INSERT #{limit+1} 'over.the.limit@gmail.com'")
    }.to raise_error(
      an_instance_of(PageOverflowError)
        .and having_attributes(message: "Cannot insert more records.")
      )
  end
end

describe "B-tree" do
  let(:record_1) {
    [75.99, "test@big.com"]
  }

  let(:record_2) {
    [20.25, "test@small.com"]
  }

  let(:record_format) { "DA64" }

  it "desializes pages" do
    rows = [
      record_1.pack(record_format),
      record_2.pack(record_format)
    ]

    page = [
      Node::NODE_TYPE_LEAF, # node_type
      1, # is_root
      0, # parent
      rows.count, # num_cells
      0, # cell_key_1
      rows[0], # cell_data
      1, # cell_key_2
      rows[1] #  cell_data
    ].pack(LeafNode::LEAF_HEADER_FORMAT + (LeafNode::LEAF_CELL_FORMAT * rows.count))

    root = Node.load(page)
    cell = root.get_cell(1)
    record = cell.data.unpack(record_format)

    expect(record).to eq(record_2)

    leaf = root.get_cell(0)
    record = leaf.data.unpack(record_format)

    expect(record).to eq(record_1)
  end

  it "stores cells" do
    page = [
      Node::NODE_TYPE_LEAF,
      1,
      0,
      0
    ].pack(LeafNode::LEAF_HEADER_FORMAT)

    root = LeafNode.new(page, Node::NODE_TYPE_LEAF, 1, 0, 0)
    cell_idx = root.add_cell(record_1.pack(record_format))

    cell = root.get_cell(cell_idx)
    record = cell.data.unpack(record_format)

    expect(record).to eq(record_1)
  end
end
