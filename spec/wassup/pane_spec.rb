RSpec.describe Wassup::Pane do
  let(:mock_window) { instance_double(Curses::Window) }
  let(:mock_subwin) { instance_double(Curses::Window) }

  before do
    allow(Curses).to receive(:lines).and_return(24)
    allow(Curses).to receive(:cols).and_return(80)
    allow(Curses).to receive(:color_pair).and_return(1792)
    allow(Curses::Window).to receive(:new).and_return(mock_window)
    allow(mock_window).to receive(:subwin).and_return(mock_subwin)
    allow(mock_window).to receive(:refresh)
    allow(mock_window).to receive(:attrset)
    allow(mock_window).to receive(:box)
    allow(mock_window).to receive(:setpos)
    allow(mock_window).to receive(:addstr)
    allow(mock_subwin).to receive(:refresh)
    allow(mock_subwin).to receive(:nodelay=)
    allow(mock_subwin).to receive(:idlok)
    allow(mock_subwin).to receive(:scrollok)
    allow(mock_subwin).to receive(:maxy).and_return(20)
    allow(mock_subwin).to receive(:maxx).and_return(76)
    allow(mock_subwin).to receive(:attrset)
  end

  describe "#initialize" do
    it "creates a pane with default values" do
      pane = Wassup::Pane.new(0.5, 0.5, 0.25, 0.25, 
                              title: "Test Pane", 
                              interval: 30, 
                              show_refresh: true,
                              content_block: proc {}, 
                              selection_blocks: {}, 
                              selection_blocks_description: {})
      
      expect(pane.title).to eq("Test Pane")
      expect(pane.focused).to eq(false)
      expect(pane.highlight).to eq(true)
      expect(pane.virtual_scroll).to eq(true)
      expect(pane.top).to eq(0)
      expect(pane.contents).to eq([])
      expect(pane.selected_view_index).to eq(0)
    end

    it "handles debug mode" do
      pane = Wassup::Pane.new(0.5, 0.5, 0.25, 0.25, 
                              title: "Test Pane", 
                              interval: 30, 
                              show_refresh: true,
                              content_block: proc {}, 
                              selection_blocks: {}, 
                              selection_blocks_description: {},
                              debug: true)
      
      expect(pane.win).to be_nil
    end
  end

  describe Wassup::Pane::Content do
    let(:content) { Wassup::Pane::Content.new("Test Content") }

    describe "#initialize" do
      it "sets title and initializes empty data array" do
        expect(content.title).to eq("Test Content")
        expect(content.data).to be_empty
        expect(content.alert_level).to be_nil
      end
    end

    describe "#add_row" do
      it "adds a row with display text" do
        content.add_row("Test display")
        expect(content.data.size).to eq(1)
        expect(content.data.first.display).to eq("Test display")
        expect(content.data.first.object).to eq("Test display")
      end

      it "adds a row with separate display and object" do
        object = { id: 1, name: "Test" }
        content.add_row("Display Text", object)
        expect(content.data.first.display).to eq("Display Text")
        expect(content.data.first.object).to eq(object)
      end
    end
  end

  describe Wassup::Pane::Content::Row do
    let(:row) { Wassup::Pane::Content::Row.new("Display", "Object") }

    it "stores display and object" do
      expect(row.display).to eq("Display")
      expect(row.object).to eq("Object")
    end

    it "defaults object to display when object is nil" do
      row = Wassup::Pane::Content::Row.new("Display", nil)
      expect(row.object).to eq("Display")
    end
  end

  describe "#needs_refresh?" do
    let(:pane) { Wassup::Pane.new(0.5, 0.5, 0.25, 0.25, 
                                  title: "Test", 
                                  interval: 30, 
                                  show_refresh: true,
                                  content_block: proc {}, 
                                  selection_blocks: {}, 
                                  selection_blocks_description: {}) }

    it "returns false when content_block is nil" do
      pane.content_block = nil
      expect(pane.needs_refresh?).to eq(false)
    end

    it "returns false when interval is nil" do
      pane.interval = nil
      expect(pane.needs_refresh?).to eq(false)
    end

    it "returns true when never refreshed" do
      expect(pane.needs_refresh?).to eq(true)
    end

    it "returns true when refresh interval has passed" do
      pane.last_refreshed = Time.now - 60
      expect(pane.needs_refresh?).to eq(true)
    end

    it "returns false when refresh interval has not passed" do
      pane.last_refreshed = Time.now - 15
      expect(pane.needs_refresh?).to eq(false)
    end
  end

  describe "#alert_count" do
    let(:pane) { Wassup::Pane.new(0.5, 0.5, 0.25, 0.25, 
                                  title: "Test", 
                                  interval: 30, 
                                  show_refresh: true,
                                  content_block: proc {}, 
                                  selection_blocks: {}, 
                                  selection_blocks_description: {}) }

    it "returns 0 when no contents" do
      expect(pane.alert_count).to eq(0)
    end

    it "returns total count of all data rows" do
      content1 = Wassup::Pane::Content.new("Page 1")
      content1.add_row("Row 1")
      content1.add_row("Row 2")
      
      content2 = Wassup::Pane::Content.new("Page 2")
      content2.add_row("Row 3")
      
      pane.contents = [content1, content2]
      expect(pane.alert_count).to eq(3)
    end
  end

  describe "#data_lines" do
    let(:pane) { Wassup::Pane.new(0.5, 0.5, 0.25, 0.25, 
                                  title: "Test", 
                                  interval: 30, 
                                  show_refresh: true,
                                  content_block: proc {}, 
                                  selection_blocks: {}, 
                                  selection_blocks_description: {}) }

    it "returns empty array when no contents" do
      expect(pane.data_lines).to eq([])
    end

    it "returns display text from current content" do
      content = Wassup::Pane::Content.new("Test")
      content.add_row("Line 1")
      content.add_row("Line 2")
      pane.contents = [content]
      
      expect(pane.data_lines).to eq(["Line 1", "Line 2"])
    end
  end

  describe "#refreshing?" do
    let(:pane) { Wassup::Pane.new(0.5, 0.5, 0.25, 0.25, 
                                  title: "Test", 
                                  interval: 30, 
                                  show_refresh: true,
                                  content_block: proc {}, 
                                  selection_blocks: {}, 
                                  selection_blocks_description: {}) }

    it "returns false when no content thread" do
      expect(pane.refreshing?).to eq(false)
    end

    it "returns true when content thread exists" do
      pane.content_thread = Thread.new { sleep 0.1 }
      expect(pane.refreshing?).to eq(true)
      pane.content_thread.kill
    end
  end

  describe "#scroll_left" do
    let(:pane) { Wassup::Pane.new(0.5, 0.5, 0.25, 0.25, 
                                  title: "Test", 
                                  interval: 30, 
                                  show_refresh: true,
                                  content_block: proc {}, 
                                  selection_blocks: {}, 
                                  selection_blocks_description: {},
                                  debug: true) }

    it "decrements selected_view_index" do
      pane.contents = [double, double, double]
      pane.selected_view_index = 1
      allow(pane).to receive(:load_current_view)
      
      pane.scroll_left
      expect(pane.selected_view_index).to eq(0)
    end

    it "wraps to last index when at beginning" do
      pane.contents = [double, double, double]
      pane.selected_view_index = 0
      allow(pane).to receive(:load_current_view)
      
      pane.scroll_left
      expect(pane.selected_view_index).to eq(2)
    end
  end

  describe "#scroll_right" do
    let(:pane) { Wassup::Pane.new(0.5, 0.5, 0.25, 0.25, 
                                  title: "Test", 
                                  interval: 30, 
                                  show_refresh: true,
                                  content_block: proc {}, 
                                  selection_blocks: {}, 
                                  selection_blocks_description: {},
                                  debug: true) }

    it "increments selected_view_index" do
      pane.contents = [double, double, double]
      pane.selected_view_index = 1
      allow(pane).to receive(:load_current_view)
      
      pane.scroll_right
      expect(pane.selected_view_index).to eq(2)
    end

    it "wraps to first index when at end" do
      pane.contents = [double, double, double]
      pane.selected_view_index = 2
      allow(pane).to receive(:load_current_view)
      
      pane.scroll_right
      expect(pane.selected_view_index).to eq(0)
    end
  end

  describe "#update_highlight" do
    let(:pane) { Wassup::Pane.new(0.5, 0.5, 0.25, 0.25, 
                                  title: "Test", 
                                  interval: 30, 
                                  show_refresh: true,
                                  content_block: proc {}, 
                                  selection_blocks: {}, 
                                  selection_blocks_description: {},
                                  debug: true) }

    before do
      content = Wassup::Pane::Content.new("Test")
      content.add_row("Line 1")
      content.add_row("Line 2")
      content.add_row("Line 3")
      pane.contents = [content]
    end

    it "returns without doing anything when highlight is false" do
      pane.highlight = false
      result = pane.update_highlight(1)
      expect(result).to be_nil
    end

    it "initializes highlighted_line to 0 when nil" do
      pane.highlighted_line = nil
      result = pane.update_highlight(1)
      expect(result).to eq(0)
    end

    it "increments highlighted_line" do
      pane.highlighted_line = 0
      result = pane.update_highlight(1)
      expect(result).to eq(1)
    end

    it "decrements highlighted_line" do
      pane.highlighted_line = 2
      result = pane.update_highlight(-1)
      expect(result).to eq(1)
    end

    it "prevents going below 0" do
      pane.highlighted_line = 0
      result = pane.update_highlight(-1)
      expect(result).to eq(0)
    end

    it "prevents going above data size" do
      pane.highlighted_line = 2
      result = pane.update_highlight(1)
      expect(result).to eq(2)
    end
  end
end