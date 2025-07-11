RSpec.describe Wassup::Panes::CircleCI::Workflows do
  let(:workflows_pane) { Wassup::Panes::CircleCI::Workflows.new(vcs: "github", org: "testorg", repo: "testrepo") }
  let(:pane_builder) { instance_double(Wassup::PaneBuilder) }
  let(:content_builder) { instance_double(Wassup::PaneBuilder::ContentBuilder) }

  describe "#initialize" do
    it "sets vcs, org, and repo attributes" do
      expect(workflows_pane.vcs).to eq("github")
      expect(workflows_pane.org).to eq("testorg")
      expect(workflows_pane.repo).to eq("testrepo")
    end
  end

  describe "#configure" do
    let(:workflows_data) do
      [
        {
          "id" => "workflow-1",
          "status" => "success",
          "project_slug" => "github/testorg/testrepo",
          "pipeline_number" => 123,
          "pipeline" => {
            "number" => 123,
            "vcs" => {
              "commit" => {
                "subject" => "Fix bug"
              }
            },
            "trigger" => {
              "actor" => {
                "login" => "johndoe"
              }
            }
          }
        }
      ]
    end

    before do
      allow(Wassup::Helpers::CircleCI).to receive(:workflows).and_return(workflows_data)
      allow(Wassup::Helpers::CircleCI::Formatter).to receive(:workflow).and_return("Formatted workflow")
      allow(pane_builder).to receive(:content).and_yield(content_builder)
      allow(pane_builder).to receive(:selection)
      allow(content_builder).to receive(:add_row)
    end

    it "configures the pane with workflow data" do
      expect(Wassup::Helpers::CircleCI).to receive(:workflows).with(
        vcs: "github",
        org: "testorg", 
        repo: "testrepo",
        limit_days: 14
      )

      workflows_pane.configure(pane_builder)
    end

    it "adds formatted workflow rows to content" do
      expect(content_builder).to receive(:add_row).with("Formatted workflow", workflows_data.first)

      workflows_pane.configure(pane_builder)
    end

    it "configures selection to open workflow in browser" do
      expect(pane_builder).to receive(:selection).with('enter', 'Open workflow in browser')

      workflows_pane.configure(pane_builder)
    end
  end
end