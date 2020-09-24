require  "byebug"

class CorruptNodeError < StandardError; end

def load_node(page)
  node_type = page.unpack("C").first
  if node_type == Node::NODE_TYPE_INTERNAL
    node = Node.new(page)
  elsif node_type == Node::NODE_TYPE_LEAF
    node = LeafNode.new(page)
  else
    raise CorruptNodeError
  end
  node
end

class Node
  def initialize(page)
    @page = page
    @node_type, @is_root, @parent_pointer = page.unpack(COMMON_HEADER_FORMAT)
  end

  NODE_TYPE_INTERNAL = 0
  NODE_TYPE_LEAF = 1
  COMMON_HEADER_FORMAT = "CCL"
  COMMON_HEADER_SIZE = 1 + 1 + 4
end

class LeafNode < Node
  def initialize(page)
    @page = page
    @node_type, @is_root, @parent_pointer, @num_cells = page.unpack(LEAF_HEADER_FORMAT)
  end

  def leaf_node_cell(cell_num)
    raise LeafOverflowError.new if cell_num >= @num_cells

    raw_bytes = @page[LEAF_HEADER_SIZE + (cell_num * LEAF_NODE_CELL_SIZE), LEAF_NODE_CELL_SIZE]
    Leaf.new(raw_bytes, LEAF_BODY_FORMAT)
  end

  LEAF_HEADER_FORMAT = "#{COMMON_HEADER_FORMAT}L"
  LEAF_NUMS_SIZE = 4
  LEAF_HEADER_SIZE = COMMON_HEADER_SIZE + LEAF_NUMS_SIZE

  # TODO: IMPORT THESE
  ROW_SIZE = 72
  TABLE_FORMAT = "A#{ROW_SIZE}"
  PAGE_SIZE = 4096

  LEAF_BODY_FORMAT = "L#{TABLE_FORMAT}"
  LEAF_NODE_KEY_SIZE = 4
  LEAF_NODE_VALUE_OFFSET = LEAF_NODE_KEY_SIZE

  LEAF_NODE_VALUE_SIZE = ROW_SIZE
  LEAF_NODE_CELL_SIZE = LEAF_NODE_KEY_SIZE + LEAF_NODE_VALUE_SIZE
  LEAF_NODE_SPACE_FOR_CELLS = PAGE_SIZE - LEAF_HEADER_SIZE
  LEAF_NODE_MAX_CELLS = LEAF_NODE_SPACE_FOR_CELLS / LEAF_NODE_CELL_SIZE
end

class Leaf
  attr_reader :data
  attr_reader :node_key

  def initialize(bytes, format)
    @node_key, @data = bytes.unpack(format)
  end
end


