RSpec.describe Wassup::Helpers::Shortcut do
  before do
    allow(ENV).to receive(:[]).with('WASSUP_SHORTCUT_TOKEN').and_return('test-token')
  end

  describe ".members" do
    let(:members_response) do
      [
        {
          "id" => "member-1",
          "profile" => {
            "mention_name" => "johndoe",
            "name" => "John Doe"
          }
        }
      ]
    end

    before do
      allow(RestClient::Request).to receive(:execute).and_return(members_response.to_json)
      allow(JSON).to receive(:parse).and_return(members_response)
    end

    it "fetches members from Shortcut API" do
      expect(RestClient::Request).to receive(:execute).with(
        method: :get,
        url: "https://api.app.shortcut.com/api/v3/members",
        headers: { "Shortcut-Token": "test-token", "Content-Type": "application/json" }
      )

      members = Wassup::Helpers::Shortcut.members
      expect(members).to eq(members_response)
    end
  end

  describe ".workflows" do
    let(:workflows_response) do
      [
        {
          "id" => "workflow-1",
          "name" => "Development",
          "states" => [
            { "id" => "state-1", "name" => "In Progress" },
            { "id" => "state-2", "name" => "Done" }
          ]
        }
      ]
    end

    before do
      allow(RestClient::Request).to receive(:execute).and_return(workflows_response.to_json)
      allow(JSON).to receive(:parse).and_return(workflows_response)
    end

    it "fetches workflows from Shortcut API" do
      expect(RestClient::Request).to receive(:execute).with(
        method: :get,
        url: "https://api.app.shortcut.com/api/v3/workflows",
        headers: { "Shortcut-Token": "test-token", "Content-Type": "application/json" }
      )

      workflows = Wassup::Helpers::Shortcut.workflows
      expect(workflows).to eq(workflows_response)
    end
  end

  describe ".search_stories" do
    let(:members_response) do
      [
        {
          "id" => "member-1",
          "profile" => {
            "mention_name" => "johndoe",
            "name" => "John Doe"
          }
        }
      ]
    end

    let(:workflows_response) do
      [
        {
          "id" => "workflow-1",
          "name" => "Development",
          "states" => [
            { "id" => "state-1", "name" => "In Progress" },
            { "id" => "state-2", "name" => "Done" }
          ]
        }
      ]
    end

    let(:search_response) do
      {
        "data" => [
          {
            "id" => 12345,
            "name" => "Fix login bug",
            "workflow_id" => "workflow-1",
            "workflow_state_id" => "state-1",
            "owner_ids" => ["member-1"],
            "follower_ids" => ["member-1"]
          }
        ],
        "next" => nil
      }
    end

    before do
      allow(Wassup::Helpers::Shortcut).to receive(:members).and_return(members_response)
      allow(Wassup::Helpers::Shortcut).to receive(:workflows).and_return(workflows_response)
      allow(RestClient::Request).to receive(:execute).and_return(search_response.to_json)
      allow(JSON).to receive(:parse).and_return(search_response)
    end

    it "searches for stories and enriches them with member and workflow data" do
      expect(RestClient::Request).to receive(:execute).with(
        method: :get,
        url: "https://api.app.shortcut.com/api/v3/search/stories",
        payload: { page_size: 25, query: "bug" },
        headers: { "Shortcut-Token": "test-token", "Content-Type": "application/json" }
      )

      stories = Wassup::Helpers::Shortcut.search_stories(query: "bug")
      
      expect(stories).to be_an(Array)
      expect(stories.first["owners"]).to eq([members_response.first])
      expect(stories.first["followers"]).to eq([members_response.first])
      expect(stories.first["workflow"]).to eq(workflows_response.first)
      expect(stories.first["workflow_state"]).to eq(workflows_response.first["states"].first)
    end

    it "uses default page size of 25" do
      expect(RestClient::Request).to receive(:execute).with(
        method: :get,
        url: "https://api.app.shortcut.com/api/v3/search/stories",
        payload: { page_size: 25, query: "bug" },
        headers: { "Shortcut-Token": "test-token", "Content-Type": "application/json" }
      )

      Wassup::Helpers::Shortcut.search_stories(query: "bug")
    end

    it "uses custom page size when provided" do
      expect(RestClient::Request).to receive(:execute).with(
        method: :get,
        url: "https://api.app.shortcut.com/api/v3/search/stories",
        payload: { page_size: 50, query: "bug" },
        headers: { "Shortcut-Token": "test-token", "Content-Type": "application/json" }
      )

      Wassup::Helpers::Shortcut.search_stories(query: "bug", page_size: 50)
    end

    it "handles pagination" do
      paginated_response = search_response.dup
      paginated_response["next"] = "/api/v3/search/stories?page_token=abc"
      
      second_page_response = {
        "data" => [
          {
            "id" => 67890,
            "name" => "Another story",
            "workflow_id" => "workflow-1",
            "workflow_state_id" => "state-2",
            "owner_ids" => [],
            "follower_ids" => []
          }
        ],
        "next" => nil
      }

      allow(JSON).to receive(:parse).and_return(paginated_response, second_page_response)
      allow(RestClient::Request).to receive(:execute).and_return(
        paginated_response.to_json,
        second_page_response.to_json
      )

      stories = Wassup::Helpers::Shortcut.search_stories(query: "bug")
      expect(stories.length).to eq(2)
    end
  end
end

RSpec.describe Wassup::Helpers::Shortcut::Formatter do
  describe ".story" do
    let(:story) do
      {
        "id" => 12345,
        "name" => "Fix authentication bug in login flow",
        "workflow_state" => {
          "name" => "In Progress"
        },
        "owners" => [
          {
            "profile" => {
              "mention_name" => "johndoe"
            }
          },
          {
            "profile" => {
              "mention_name" => "janedoe"
            }
          }
        ]
      }
    end

    it "formats a story with all information" do
      result = Wassup::Helpers::Shortcut::Formatter.story(story)
      
      expect(result).to include("#12345")
      expect(result).to include("In Progress")
      expect(result).to include("johndoe, janedoe")
      expect(result).to include("Fix authentication bug in login flow")
    end

    it "formats story ID with consistent width" do
      result = Wassup::Helpers::Shortcut::Formatter.story(story)
      expect(result).to match(/\[fg=yellow\]#12345\s+/)
    end

    it "handles empty owners array" do
      story["owners"] = []
      result = Wassup::Helpers::Shortcut::Formatter.story(story)
      expect(result).to include("[fg=white] ")
    end

    it "handles nil owners" do
      story["owners"] = nil
      result = Wassup::Helpers::Shortcut::Formatter.story(story)
      expect(result).to include("[fg=white] ")
    end

    it "uses correct color formatting" do
      result = Wassup::Helpers::Shortcut::Formatter.story(story)
      expect(result).to include("[fg=yellow]#12345")
      expect(result).to include("[fg=cyan]In Progress")
      expect(result).to include("[fg=white]johndoe, janedoe")
      expect(result).to include("[fg=gray]Fix authentication bug in login flow")
    end
  end
end