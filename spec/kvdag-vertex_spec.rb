require 'spec_helper'

describe KVDAG::Vertex do
  context 'immediate ancestry' do
    before :all do
      # v1 --> v2 --> v3
      #           \-> v4

      @dag = KVDAG.new
      @v1 = @dag.vertex

      @v2 = @dag.vertex
      @v1.edge @v2

      @v3 = @dag.vertex
      @v4 = @dag.vertex
      @v2.edge @v3
      @v2.edge @v4
    end

    it 'finds parents' do
      parents = @v2.parents
      expect(parents).not_to include @v1
      expect(parents).not_to include @v2
      expect(parents).to include @v3
      expect(parents).to include @v4
    end

    it 'finds children' do
      children = @v2.children
      expect(children).to include @v1
      expect(children).not_to include @v2
      expect(children).not_to include @v3
      expect(children).not_to include @v4
    end
  end

  context 'deep ancestry' do
    before :all do
      # v1 --> v2 --> v3
      #           \-> v4

      @dag = KVDAG.new
      @v1 = @dag.vertex

      @v2 = @dag.vertex
      @v1.edge @v2

      @v3 = @dag.vertex
      @v4 = @dag.vertex
      @v2.edge @v3
      @v2.edge @v4
    end

    it 'can find all ancestors' do
      ancestors = @v1.ancestors
      expect(ancestors).to include @v1
      expect(ancestors).to include @v2
      expect(ancestors).to include @v3
      expect(ancestors).to include @v4
    end

    it 'can find all descendants' do
      descendants = @v3.descendants
      expect(descendants).to include @v1
      expect(descendants).to include @v2
      expect(descendants).to include @v3
    end

    it 'does not claim that children are ancestors' do
      ancestors = @v2.ancestors
      expect(ancestors).not_to include @v1
      expect(ancestors).to include @v2
      expect(ancestors).to include @v3
      expect(ancestors).to include @v4
    end

    it 'does not claim that parents are descendants' do
      descendants = @v2.descendants
      expect(descendants).to include @v1
      expect(descendants).to include @v2
      expect(descendants).not_to include @v3
      expect(descendants).not_to include @v4
    end
  end

  context 'reachability' do
    before :all do
      # v1 --> v2 --> v3
      #           \-> v4

      @dag = KVDAG.new
      @v1 = @dag.vertex

      @v2 = @dag.vertex
      @v1.edge @v2

      @v3 = @dag.vertex
      @v4 = @dag.vertex
      @v2.edge @v3
      @v2.edge @v4
    end

    it 'can find reachability' do
      expect(@v2.reachable? @v2).to be true
      expect(@v2.reachable? @v3).to be true
      expect(@v2.reachable? @v4).to be true
    end

    it 'does not claim reachability to be reversed' do
      expect(@v2.reachable? @v1).to be false
    end

    it 'does not claim unrelated vertices are reachable' do
      expect(@v3.reachable? @v4).to be false
    end

    it 'can find reversed reachability' do
      expect(@v2.reachable_from? @v2).to be true
      expect(@v3.reachable_from? @v2).to be true
      expect(@v4.reachable_from? @v2).to be true
    end

    it 'does not claim reversed reachability to be reversed' do
      expect(@v1.reachable_from? @v2).to be false
    end

    it 'does not claim unrelated vertices are reverse reachable' do
      expect(@v3.reachable_from? @v4).to be false
    end
  end
end
