class CorruptNodeError < StandardError; end
class LeafOverflowError < StandardError; end

class Node
  def initialize(page, node_type, is_root, parent_pointer)
    @page = page
    @node_type = node_type
    @is_root = is_root
    @parent_pointer = parent_pointer
  end

  def self.load(page)
    node_type = page.unpack("C").first
    case node_type
    when NODE_TYPE_INTERNAL
      klass = Node
    when NODE_TYPE_LEAF
      klass = LeafNode
    else
      raise CorruptNodeError
    end
    klass.from(page)
  end

  def self.from(page)
    new(page, *page.unpack(COMMON_HEADER_FORMAT))
  end

  NODE_TYPE_INTERNAL = 0
  NODE_TYPE_LEAF = 1
  COMMON_HEADER_FORMAT = "CCL"
  COMMON_HEADER_SIZE = 1 + 1 + 4
end

class LeafNode < Node
  def initialize(page, node_type, is_root, parent_node, num_cells)
    super(page, node_type, is_root, parent_node)
    @num_cells = num_cells
  end

  def self.from(page)
    new(page, *page.unpack(LEAF_HEADER_FORMAT))
  end

  def get_cell(cell_num)
    raise LeafOverflowError.new if cell_num >= @num_cells

    cell_bytes = @page[cell_offset(cell_num), LEAF_NODE_CELL_SIZE]
    LeafCell.new(cell_bytes, LEAF_CELL_FORMAT)
  end

  def add_cell(raw_bytes)
    raise LeafOverflowError.new if @num_cells >= LEAF_NODE_MAX_CELLS

    idx = @num_cells
    cell_bytes = [idx, raw_bytes].pack(LEAF_CELL_FORMAT)
    @page[cell_offset(idx), LEAF_NODE_CELL_SIZE] = cell_bytes
    @num_cells += 1

    idx
  end

  def cell_offset(cell_num)
    LEAF_HEADER_SIZE + (cell_num * LEAF_NODE_CELL_SIZE)
  end

  LEAF_HEADER_FORMAT = "#{COMMON_HEADER_FORMAT}L"
  LEAF_NUMS_SIZE = 4
  LEAF_HEADER_SIZE = COMMON_HEADER_SIZE + LEAF_NUMS_SIZE

  # TODO: IMPORT THESE
  ROW_SIZE = 72
  TABLE_FORMAT = "A#{ROW_SIZE}"
  PAGE_SIZE = 4096

  LEAF_CELL_FORMAT = "L#{TABLE_FORMAT}"
  LEAF_NODE_KEY_SIZE = 4
  LEAF_NODE_VALUE_OFFSET = LEAF_NODE_KEY_SIZE

  LEAF_NODE_VALUE_SIZE = ROW_SIZE
  LEAF_NODE_CELL_SIZE = LEAF_NODE_KEY_SIZE + LEAF_NODE_VALUE_SIZE
  LEAF_NODE_SPACE_FOR_CELLS = PAGE_SIZE - LEAF_HEADER_SIZE
  LEAF_NODE_MAX_CELLS = LEAF_NODE_SPACE_FOR_CELLS / LEAF_NODE_CELL_SIZE
end

class LeafCell
  attr_reader :data
  attr_reader :node_key

  def initialize(bytes, format)
    @node_key, @data = bytes.unpack(format)
  end
end

