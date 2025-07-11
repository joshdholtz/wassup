RSpec.describe Wassup::Panes::GitHub::PullRequests do
  let(:pr_pane) { Wassup::Panes::GitHub::PullRequests.new(org: "testorg", repo: "testrepo") }
  let(:pane_builder) { instance_double(Wassup::PaneBuilder) }
  let(:content_builder) { instance_double(Wassup::PaneBuilder::ContentBuilder) }

  describe "#initialize" do
    it "sets org and repo attributes" do
      expect(pr_pane.org).to eq("testorg")
      expect(pr_pane.repo).to eq("testrepo")
      expect(pr_pane.show_username).to eq(false)
      expect(pr_pane.show_interactions).to eq(false)
    end

    it "accepts optional parameters" do
      pr_pane = Wassup::Panes::GitHub::PullRequests.new(
        org: "testorg", 
        repo: "testrepo",
        show_username: true,
        show_interactions: true
      )
      expect(pr_pane.show_username).to eq(true)
      expect(pr_pane.show_interactions).to eq(true)
    end
  end

  describe "#configure" do
    let(:pr_data) do
      [
        {
          "number" => 123,
          "title" => "Add new feature",
          "html_url" => "https://github.com/testorg/testrepo/pull/123",
          "created_at" => "2023-01-01T00:00:00Z",
          "user" => { "login" => "johndoe" }
        }
      ]
    end

    before do
      allow(Wassup::Helpers::GitHub).to receive(:pull_requests).and_return(pr_data)
      allow(Wassup::Helpers::GitHub::Formatter).to receive(:pr).and_return("Formatted PR")
      allow(pane_builder).to receive(:content).and_yield(content_builder)
      allow(pane_builder).to receive(:selection)
      allow(content_builder).to receive(:add_row)
    end

    it "configures the pane with PR data" do
      expect(Wassup::Helpers::GitHub).to receive(:pull_requests).with(
        org: "testorg",
        repo: "testrepo"
      )

      pr_pane.configure(pane_builder)
    end

    it "adds formatted PR rows to content" do
      expect(content_builder).to receive(:add_row).with("Formatted PR", pr_data.first)

      pr_pane.configure(pane_builder)
    end

    it "configures selection to open PR in browser" do
      expect(pane_builder).to receive(:selection).with('enter', 'Open PR in browser')

      pr_pane.configure(pane_builder)
    end
  end
end

RSpec.describe Wassup::Panes::GitHub::Releases do
  let(:releases_pane) { Wassup::Panes::GitHub::Releases.new(org: "testorg", repo: "testrepo") }
  let(:pane_builder) { instance_double(Wassup::PaneBuilder) }
  let(:content_builder) { instance_double(Wassup::PaneBuilder::ContentBuilder) }

  describe "#initialize" do
    it "sets org and repo attributes" do
      expect(releases_pane.org).to eq("testorg")
      expect(releases_pane.repo).to eq("testrepo")
    end
  end

  describe "#configure" do
    let(:release_data) do
      [
        {
          "tag_name" => "v1.0.0",
          "name" => "Version 1.0.0",
          "html_url" => "https://github.com/testorg/testrepo/releases/tag/v1.0.0",
          "published_at" => "2023-01-01T00:00:00Z"
        }
      ]
    end

    before do
      allow(Wassup::Helpers::GitHub).to receive(:releases).and_return(release_data)
      allow(Wassup::Helpers::GitHub::Formatter).to receive(:release).and_return("Formatted Release")
      allow(pane_builder).to receive(:content).and_yield(content_builder)
      allow(pane_builder).to receive(:selection)
      allow(content_builder).to receive(:add_row)
    end

    it "configures the pane with release data" do
      expect(Wassup::Helpers::GitHub).to receive(:releases).with(
        org: "testorg",
        repo: "testrepo"
      )

      releases_pane.configure(pane_builder)
    end

    it "adds formatted release rows to content" do
      expect(content_builder).to receive(:add_row).with("Formatted Release", release_data.first)

      releases_pane.configure(pane_builder)
    end

    it "configures selection to open release in browser" do
      expect(pane_builder).to receive(:selection).with('enter', 'Open release in browser')

      releases_pane.configure(pane_builder)
    end
  end
end

RSpec.describe Wassup::Panes::GitHub::Search do
  let(:search_pane) { Wassup::Panes::GitHub::Search.new(org: "testorg", query: "is:open") }
  let(:pane_builder) { instance_double(Wassup::PaneBuilder) }
  let(:content_builder) { instance_double(Wassup::PaneBuilder::ContentBuilder) }

  describe "#initialize" do
    it "sets org and query attributes with defaults" do
      expect(search_pane.org).to eq("testorg")
      expect(search_pane.repo).to be_nil
      expect(search_pane.query).to eq("is:open")
      expect(search_pane.show_repo).to eq(true)
      expect(search_pane.show_username).to eq(false)
      expect(search_pane.show_interactions).to eq(false)
    end

    it "accepts optional parameters" do
      search_pane = Wassup::Panes::GitHub::Search.new(
        org: "testorg",
        repo: "testrepo",
        query: "is:open",
        show_repo: false,
        show_username: true,
        show_interactions: true
      )
      expect(search_pane.repo).to eq("testrepo")
      expect(search_pane.show_repo).to eq(false)
      expect(search_pane.show_username).to eq(true)
      expect(search_pane.show_interactions).to eq(true)
    end
  end

  describe "#configure" do
    let(:issue_data) do
      [
        {
          "number" => 42,
          "title" => "Fix bug",
          "html_url" => "https://github.com/testorg/testrepo/issues/42",
          "created_at" => "2023-01-01T00:00:00Z",
          "user" => { "login" => "johndoe" }
        }
      ]
    end

    let(:pr_data) do
      [
        {
          "number" => 123,
          "title" => "Add feature",
          "html_url" => "https://github.com/testorg/testrepo/pull/123",
          "created_at" => "2023-01-01T00:00:00Z",
          "user" => { "login" => "janedoe" },
          "pull_request" => {}
        }
      ]
    end

    before do
      allow(pane_builder).to receive(:content).and_yield(content_builder)
      allow(pane_builder).to receive(:selection)
      allow(content_builder).to receive(:add_row)
    end

    it "configures the pane with issue data" do
      allow(Wassup::Helpers::GitHub).to receive(:issues).and_return(issue_data)
      allow(Wassup::Helpers::GitHub::Formatter).to receive(:issue).and_return("Formatted Issue")

      expect(Wassup::Helpers::GitHub).to receive(:issues).with(
        org: "testorg",
        repo: nil,
        q: "is:open"
      )

      search_pane.configure(pane_builder)
    end

    it "formats issues correctly" do
      allow(Wassup::Helpers::GitHub).to receive(:issues).and_return(issue_data)
      expect(Wassup::Helpers::GitHub::Formatter).to receive(:issue).with(
        issue_data.first,
        show_repo: true,
        show_username: false,
        show_interactions: false
      )

      search_pane.configure(pane_builder)
    end

    it "formats pull requests correctly" do
      allow(Wassup::Helpers::GitHub).to receive(:issues).and_return(pr_data)
      expect(Wassup::Helpers::GitHub::Formatter).to receive(:pr).with(
        pr_data.first,
        show_repo: true,
        show_username: false,
        show_interactions: false
      )

      search_pane.configure(pane_builder)
    end

    it "adds formatted rows to content" do
      allow(Wassup::Helpers::GitHub).to receive(:issues).and_return(issue_data)
      allow(Wassup::Helpers::GitHub::Formatter).to receive(:issue).and_return("Formatted Issue")

      expect(content_builder).to receive(:add_row).with("Formatted Issue", issue_data.first)

      search_pane.configure(pane_builder)
    end

    it "configures selection to open items in browser" do
      allow(Wassup::Helpers::GitHub).to receive(:issues).and_return(issue_data)
      allow(Wassup::Helpers::GitHub::Formatter).to receive(:issue).and_return("Formatted Issue")

      expect(pane_builder).to receive(:selection).with('enter', 'Open in browser')

      search_pane.configure(pane_builder)
    end
  end
end