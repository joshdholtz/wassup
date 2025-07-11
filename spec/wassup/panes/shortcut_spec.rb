RSpec.describe Wassup::Panes::Shortcut::Stories do
  let(:stories_pane) { Wassup::Panes::Shortcut::Stories.new(query: "is:open") }
  let(:pane_builder) { instance_double(Wassup::PaneBuilder) }
  let(:content_builder) { instance_double(Wassup::PaneBuilder::ContentBuilder) }

  describe "#initialize" do
    it "sets query_pages with single query" do
      expect(stories_pane.query_pages).to eq({ "": "is:open" })
    end

    it "accepts query_pages directly" do
      query_pages = { "Open" => "is:open", "Closed" => "is:closed" }
      stories_pane = Wassup::Panes::Shortcut::Stories.new(query_pages: query_pages)
      expect(stories_pane.query_pages).to eq(query_pages)
    end

    it "handles nil query" do
      stories_pane = Wassup::Panes::Shortcut::Stories.new
      expect(stories_pane.query_pages).to be_nil
    end
  end

  describe "#configure" do
    let(:story_data) do
      [
        {
          "id" => 12345,
          "name" => "Fix authentication bug",
          "app_url" => "https://app.shortcut.com/story/12345",
          "workflow_state" => { "name" => "In Progress" },
          "owners" => [
            { "profile" => { "mention_name" => "johndoe" } }
          ]
        }
      ]
    end

    before do
      allow(Wassup::Helpers::Shortcut).to receive(:search_stories).and_return(story_data)
      allow(Wassup::Helpers::Shortcut::Formatter).to receive(:story).and_return("Formatted Story")
      allow(pane_builder).to receive(:content).and_yield(content_builder)
      allow(pane_builder).to receive(:selection)
      allow(content_builder).to receive(:add_row)
    end

    it "configures the pane with story data" do
      expect(Wassup::Helpers::Shortcut).to receive(:search_stories).with(query: "is:open")

      stories_pane.configure(pane_builder)
    end

    it "adds formatted story rows to content" do
      expect(content_builder).to receive(:add_row).with("Formatted Story", story_data.first, page: "")

      stories_pane.configure(pane_builder)
    end

    it "configures selection to open story in Shortcut" do
      expect(pane_builder).to receive(:selection).with('enter', 'Open in Shortcut')

      stories_pane.configure(pane_builder)
    end

    it "handles multiple query pages" do
      query_pages = { "Open" => "is:open", "Closed" => "is:closed" }
      stories_pane = Wassup::Panes::Shortcut::Stories.new(query_pages: query_pages)
      
      allow(Wassup::Helpers::Shortcut).to receive(:search_stories).and_return(story_data)
      allow(Wassup::Helpers::Shortcut::Formatter).to receive(:story).and_return("Formatted Story")
      allow(pane_builder).to receive(:content).and_yield(content_builder)
      allow(pane_builder).to receive(:selection)
      allow(content_builder).to receive(:add_row)

      expect(Wassup::Helpers::Shortcut).to receive(:search_stories).with(query: "is:open")
      expect(Wassup::Helpers::Shortcut).to receive(:search_stories).with(query: "is:closed")
      expect(content_builder).to receive(:add_row).with("Formatted Story", story_data.first, page: "Open").once
      expect(content_builder).to receive(:add_row).with("Formatted Story", story_data.first, page: "Closed").once

      stories_pane.configure(pane_builder)
    end
  end
end