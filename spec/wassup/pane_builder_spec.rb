RSpec.describe Wassup::PaneBuilder do
  let(:builder) { Wassup::PaneBuilder.new }

  describe "#initialize" do
    it "sets default values" do
      expect(builder.height).to eq(1)
      expect(builder.top).to eq(0)
      expect(builder.left).to eq(0)
      expect(builder.highlight).to eq(false)
      expect(builder.interval).to eq(300)
      expect(builder.selection_blocks).to eq({})
      expect(builder.selection_blocks_description).to eq({})
    end
  end

  describe "#content" do
    it "sets the content block" do
      block = proc { "test" }
      builder.content(&block)
      expect(builder.content_block).to eq(block)
    end
  end

  describe "#selection" do
    it "adds a selection block with default enter key" do
      block = proc { "test" }
      builder.selection(10, "Test selection", &block)
      expect(builder.selection_blocks[10]).to eq(block)
      expect(builder.selection_blocks_description["enter"]).to eq("Test selection")
    end

    it "adds a selection block with custom key" do
      block = proc { "test" }
      builder.selection("x", "Custom selection", &block)
      expect(builder.selection_blocks["x"]).to eq(block)
      expect(builder.selection_blocks_description["x"]).to eq("Custom selection")
    end

    it "handles enter key specially" do
      block = proc { "test" }
      builder.selection("enter", "Enter selection", &block)
      expect(builder.selection_blocks[10]).to eq(block)
      expect(builder.selection_blocks_description["enter"]).to eq("Enter selection")
    end
  end

  describe "ContentBuilder" do
    let(:contents) { [] }
    let(:content_builder) { Wassup::PaneBuilder::ContentBuilder.new(contents) }

    describe "#add_row" do
      it "creates a new content page when contents is empty" do
        content_builder.add_row("test row")
        expect(content_builder.contents.size).to eq(1)
        expect(content_builder.contents.first.data.first.display).to eq("test row")
      end

      it "adds to existing content when no page specified" do
        content_builder.add_row("first row")
        content_builder.add_row("second row")
        expect(content_builder.contents.size).to eq(1)
        expect(content_builder.contents.first.data.size).to eq(2)
      end

      it "creates a new page when page is specified" do
        content_builder.add_row("first row")
        content_builder.add_row("second row", page: "Page 2")
        expect(content_builder.contents.size).to eq(2)
        expect(content_builder.contents.last.title).to eq("Page 2")
      end

      it "adds to existing page when page already exists" do
        content_builder.add_row("first row", page: "Test Page")
        content_builder.add_row("second row", page: "Test Page")
        expect(content_builder.contents.size).to eq(1)
        expect(content_builder.contents.first.data.size).to eq(2)
        expect(content_builder.contents.first.title).to eq("Test Page")
      end
    end

    describe "#clear=" do
      it "sets the need_to_clear flag" do
        content_builder.clear = false
        expect(content_builder.instance_variable_get(:@need_to_clear)).to eq(false)
      end
    end
  end
end

RSpec.describe Wassup::AlertLevel do
  it "defines alert level constants" do
    expect(Wassup::AlertLevel::HIGH).to eq("high")
    expect(Wassup::AlertLevel::MEDIUM).to eq("medium")
    expect(Wassup::AlertLevel::LOW).to eq("low")
  end
end