RSpec.describe Wassup::App do
  describe ".debug" do
    let(:path) { "/tmp/test_supfile" }
    let(:app) { instance_double(Wassup::App) }
    let(:pane) { instance_double(Wassup::Pane) }

    before do
      allow(Wassup::App).to receive(:new).and_return(app)
      allow(app).to receive(:panes).and_return({"1" => pane})
      allow(pane).to receive(:title).and_return("Test Pane")
      allow(pane).to receive(:contents).and_return([])
      allow(pane).to receive(:content_block).and_return(proc {})
      allow(Wassup::PaneBuilder::ContentBuilder).to receive(:new).and_return(double(contents: []))
      allow($stdin).to receive(:gets).and_return("1\n")
    end

    it "creates an app in debug mode" do
      expect(Wassup::App).to receive(:new).with(path: path, debug: true)
      
      # Mock the output to prevent actual printing
      allow(STDOUT).to receive(:puts)
      
      Wassup::App.debug(path: path)
    end
  end

  describe "#initialize" do
    let(:path) { "/tmp/test_supfile" }

    before do
      allow(File).to receive(:new).with(path).and_return(double(read: ""))
    end

    it "initializes with default values" do
      app = Wassup::App.new(path: path, debug: true)
      
      expect(app.panes).to eq({})
      expect(app.debug).to eq(true)
      expect(app.port).to be_nil
    end

    it "sets port when provided" do
      app = Wassup::App.new(path: path, port: 8080, debug: true)
      expect(app.port).to eq(8080)
    end
  end

  describe "#add_pane" do
    let(:path) { "/tmp/test_supfile" }
    let(:app) { Wassup::App.new(path: path, debug: true) }
    let(:pane_builder) { instance_double(Wassup::PaneBuilder) }
    let(:pane) { instance_double(Wassup::Pane) }

    before do
      allow(File).to receive(:new).with(path).and_return(double(read: ""))
      allow(Wassup::PaneBuilder).to receive(:new).and_return(pane_builder)
      allow(pane_builder).to receive(:height).and_return(0.5)
      allow(pane_builder).to receive(:width).and_return(0.5)
      allow(pane_builder).to receive(:top).and_return(0.25)
      allow(pane_builder).to receive(:left).and_return(0.25)
      allow(pane_builder).to receive(:title).and_return("Test Pane")
      allow(pane_builder).to receive(:description).and_return("Test Description")
      allow(pane_builder).to receive(:alert_level).and_return(nil)
      allow(pane_builder).to receive(:highlight).and_return(true)
      allow(pane_builder).to receive(:interval).and_return(30)
      allow(pane_builder).to receive(:show_refresh).and_return(true)
      allow(pane_builder).to receive(:content_block).and_return(proc {})
      allow(pane_builder).to receive(:selection_blocks).and_return({})
      allow(pane_builder).to receive(:selection_blocks_description).and_return({})
      allow(Wassup::Pane).to receive(:new).and_return(pane)
      allow(pane).to receive(:focus_handler=)
    end

    it "adds a pane to the panes hash" do
      expect(Wassup::PaneBuilder).to receive(:new)
      expect(Wassup::Pane).to receive(:new).with(
        0.5, 0.5, 0.25, 0.25,
        title: "Test Pane",
        description: "Test Description",
        alert_level: nil,
        highlight: true,
        focus_number: 1,
        interval: 30,
        show_refresh: true,
        content_block: kind_of(Proc),
        selection_blocks: {},
        selection_blocks_description: {},
        port: nil,
        debug: true
      )
      
      app.add_pane do |pane|
        # This block would be called in real usage
      end
      
      expect(app.panes["1"]).to eq(pane)
    end

    it "increments focus number for subsequent panes" do
      app.add_pane { |pane| }
      app.add_pane { |pane| }
      
      expect(app.panes).to have_key("1")
      expect(app.panes).to have_key("2")
    end
  end

  describe "#start_debug" do
    let(:path) { "/tmp/test_supfile" }
    let(:app) { Wassup::App.new(path: path, debug: true) }
    let(:file) { double(read: "puts 'Hello from Supfile'") }

    before do
      allow(File).to receive(:new).with(path).and_return(file)
    end

    it "evaluates the supfile content" do
      expect(app).to receive(:eval).with("puts 'Hello from Supfile'")
      app.start_debug(path)
    end

    it "handles errors gracefully" do
      allow(File).to receive(:new).with(path).and_raise(StandardError.new("Test error"))
      expect { app.start_debug(path) }.not_to raise_error
    end
  end

  describe "#row_help" do
    let(:path) { "/tmp/test_supfile" }
    let(:app) { Wassup::App.new(path: path, debug: true) }

    before do
      allow(File).to receive(:new).and_return(double(read: ""))
    end

    it "returns help hash for row controls" do
      help = app.row_help
      expect(help).to be_a(Hash)
      expect(help["j"]).to eq("moves row highlight down")
      expect(help["k"]).to eq("moves row highlight up")
      expect(help["enter"]).to eq("perform selection on highlighted row")
    end
  end

  describe "#page_help" do
    let(:path) { "/tmp/test_supfile" }
    let(:app) { Wassup::App.new(path: path, debug: true) }

    before do
      allow(File).to receive(:new).and_return(double(read: ""))
    end

    it "returns help hash for page controls" do
      help = app.page_help
      expect(help).to be_a(Hash)
      expect(help["h"]).to eq("previous page in pane")
      expect(help["l"]).to eq("next page in pane")
    end
  end
end