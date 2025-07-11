RSpec.describe Wassup::Helpers::CircleCI do
  describe ".workflows" do
    let(:pipeline_response) do
      {
        "items" => [
          {
            "id" => "pipeline-1",
            "updated_at" => "2023-01-01T00:00:00Z",
            "number" => 123,
            "vcs" => {
              "commit" => {
                "subject" => "Fix bug in authentication"
              }
            },
            "trigger" => {
              "actor" => {
                "login" => "johndoe"
              }
            }
          }
        ]
      }
    end

    let(:workflow_response) do
      {
        "items" => [
          {
            "id" => "workflow-1",
            "status" => "success"
          }
        ]
      }
    end

    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("WASSUP_CIRCLE_CI_API_TOKEN").and_return("test-token")
      allow(RestClient::Request).to receive(:execute).and_return(pipeline_response.to_json, workflow_response.to_json)
      allow(JSON).to receive(:parse).and_return(pipeline_response, workflow_response)
    end

    it "fetches workflows from CircleCI API" do
      expect(RestClient::Request).to receive(:execute).with(
        method: :get,
        url: "https://circleci.com/api/v2/project/github/org/repo/pipeline",
        headers: { "Circle-Token": "test-token" }
      )

      workflows = Wassup::Helpers::CircleCI.workflows(vcs: "github", org: "org", repo: "repo")
      expect(workflows).to be_an(Array)
    end

    it "filters workflows by limit_days" do
      old_pipeline_response = {
        "items" => [
          {
            "id" => "pipeline-1",
            "updated_at" => "2020-01-01T00:00:00Z",
            "number" => 123,
            "vcs" => {
              "commit" => {
                "subject" => "Fix bug in authentication"
              }
            },
            "trigger" => {
              "actor" => {
                "login" => "johndoe"
              }
            }
          }
        ]
      }
      
      allow(JSON).to receive(:parse).and_return(old_pipeline_response, workflow_response)
      allow(Time).to receive(:now).and_return(Time.parse("2023-01-01T00:00:00Z"))

      workflows = Wassup::Helpers::CircleCI.workflows(vcs: "github", org: "org", repo: "repo", limit_days: 1)
      expect(workflows).to be_empty
    end

    it "includes pipeline data in workflow" do
      workflows = Wassup::Helpers::CircleCI.workflows(vcs: "github", org: "org", repo: "repo")
      expect(workflows.first["pipeline"]).to eq(pipeline_response["items"].first)
    end

    it "handles missing workflows gracefully" do
      allow(JSON).to receive(:parse).and_return(pipeline_response, {"items" => []})
      
      workflows = Wassup::Helpers::CircleCI.workflows(vcs: "github", org: "org", repo: "repo")
      expect(workflows).to be_empty
    end
  end
end

RSpec.describe Wassup::Helpers::CircleCI::Formatter do
  describe ".workflow" do
    let(:workflow) do
      {
        "status" => "success",
        "pipeline" => {
          "number" => 123,
          "vcs" => {
            "commit" => {
              "subject" => "Fix authentication bug"
            }
          },
          "trigger" => {
            "actor" => {
              "login" => "johndoe"
            }
          }
        }
      }
    end

    it "formats successful workflows with green status" do
      result = Wassup::Helpers::CircleCI::Formatter.workflow(workflow)
      expect(result).to include("[fg=green]success")
      expect(result).to include("#123")
      expect(result).to include("johndoe")
      expect(result).to include("Fix authentication bug")
    end

    it "formats failed workflows with red status" do
      workflow["status"] = "failed"
      result = Wassup::Helpers::CircleCI::Formatter.workflow(workflow)
      expect(result).to include("[fg=red]failed")
    end

    it "formats other statuses with yellow" do
      workflow["status"] = "running"
      result = Wassup::Helpers::CircleCI::Formatter.workflow(workflow)
      expect(result).to include("[fg=yellow]running")
    end

    it "handles missing commit message" do
      workflow["pipeline"]["vcs"]["commit"] = nil
      result = Wassup::Helpers::CircleCI::Formatter.workflow(workflow)
      expect(result).to include("[fg=gray]")
    end

    it "formats numbers with consistent width" do
      result = Wassup::Helpers::CircleCI::Formatter.workflow(workflow)
      expect(result).to match(/\[fg=yellow\]#123\s+/)
    end
  end
end