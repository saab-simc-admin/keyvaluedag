class KVDAG
  # A vertex in a KVDAG

  class Vertex
    include AttributeNode
    include Comparable
    attr_reader :dag
    attr_reader :edges

    # Create a new vertex in a KVDAG, optionally loaded
    # with key-values.
    #
    # N.B: KVDAG::Vertex.new should never be called directly,
    # always use KVDAG#vertex to create vertices.

    private :initialize
    def initialize(dag, attrs = {})
      @edges = Set.new
      @dag = dag
      @attrs = dag.hash_proxy_class.new(attrs)
      @child_cache = Set.new

      @dag.vertices << self
    end

    def inspect
      '#<%s @attr=%s @edges=%s>' % [self.class, @attrs.to_hash, @edges.to_a]
    end

    alias to_s inspect

    # :call-seq:
    #   vtx.parents                 -> all parents
    #   vtx.parents(filter)         -> parents matching +filter+
    #   vtx.parents {|cld| ... }    -> call block with each parent
    #
    # Returns the set of all direct parents, possibly filtered by #match?
    # expressions. If a block is given, call it with each parent.

    def parents(filter = {}, &block)
      result = Set.new(edges.map { |edge|
                         edge.to_vertex
                       }.select { |parent|
                         parent.match?(filter)
                       })

      if block_given?
        result.each(&block)
      else
        result
      end
    end

    # :call-seq:
    #   vtx.children                 -> all children
    #   vtx.children(filter)         -> children matching +filter+
    #   vtx.children {|cld| ... }    -> call block with each child
    #
    # Returns the set of all direct children, possibly filtered by #match?
    # expressions. If a block is given, call it with each child.

    def children(filter = {}, &block)
      result = @child_cache.select { |child|
                 child.match?(filter)
               }

      if block_given?
        result.each(&block)
      else
        result
      end
    end

    # Is +other+ vertex reachable via any of my #edges?
    #
    # A KVDAG::VertexError is raised if vertices belong
    # to different KVDAG.

    def reachable?(other)
      raise VertexError.new('Not in the same DAG') unless @dag.equal?(other.dag)

      equal?(other) || parents.any? { |parent| parent.reachable?(other) }
    end

    # Am I reachable from +other+ via any of its #edges?
    #
    # A KVDAG::VertexError is raised if vertices belong
    # to different KVDAG.

    def reachable_from?(other)
      other.reachable?(self)
    end

    # :call-seq:
    #   vtx.ancestors                 -> all ancestors
    #   vtx.ancestors(filter)         -> ancestors matching +filter+
    #   vtx.ancestors {|anc| ... }    -> call block with each ancestor
    #
    # Return the set of this object and all its parents, and their
    # parents, recursively, possibly filtered by #match?
    # expressions. If a block is given, call it with each ancestor.

    def ancestors(filter = {}, &block)
      result = Set.new
      result << self if match?(filter)

      parents.each { |p| result += p.ancestors(filter) }

      if block_given?
        result.each(&block)
      else
        result
      end
    end

    # :call-seq:
    #   vtx.descendants                 -> all descendants
    #   vtx.descendants(filter)         -> descendants matching +filter+
    #   vtx.descendants {|desc| ... }   -> call block with each descendant
    #
    # Return the set of this object and all its children, and their
    # children, recursively, possibly filtered by #match?
    # expressions. If a block is given, call it with each descendant.

    def descendants(filter = {}, &block)
      result = Set.new
      result << self if match?(filter)

      children.each { |c| result += c.descendants(filter) }

      if block_given?
        result.each(&block)
      else
        result
      end
    end

    # Comparable ordering for a DAG:
    #
    # Reachable vertices are lesser.
    # Unreachable vertices are equal.

    def <=>(other)
      return -1 if reachable?(other)
      return 1 if reachable_from?(other)
      return 0
    end

    # Create an edge towards an +other+ vertex, optionally
    # loaded with key-values.
    #
    # A KVDAG::VertexError is raised if vertices belong
    # to different KVDAG.
    #
    # A KVDAG::CyclicError is raised if the edge would
    # cause a cycle in the KVDAG.

    def edge(other, attrs = {})
      other = other.to_vertex unless other.is_a?(Vertex)
      raise VertexError.new('Not in the same DAG') if @dag != other.dag
      raise CyclicError.new('Would become cyclic') if other.reachable?(self)

      edge = Edge.new(@dag, other, attrs)
      @edges << edge
      other.add_child(self)
      edge
    end

    # Return the proxied key-value hash tree visible from this vertex
    # via its edges and all its ancestors.
    #
    # Calling #to_hash instead will return a regular hash tree, without
    # any special properties, e.g. for serializing as YAML or JSON.

    def to_hash_proxy
      result = @dag.hash_proxy_class.new
      edges.each do |edge|
        result.merge!(edge.to_hash_proxy)
      end
      result.merge!(@attrs)
    end

    protected

    # Cache the fact that the +other+ vertex has created an edge to
    # us.
    #
    # Do not call this except from #edge, which performs all required
    # sanity checks.

    def add_child(other)
      @child_cache << other
    end
  end
end
