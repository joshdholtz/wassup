RSpec.describe Wassup::Panes::Netlify::Deploys do
  let(:deploys_pane) { Wassup::Panes::Netlify::Deploys.new(site_id: "test-site-id") }
  let(:pane_builder) { instance_double(Wassup::PaneBuilder) }
  let(:content_builder) { instance_double(Wassup::PaneBuilder::ContentBuilder) }

  describe "#initialize" do
    it "sets site_id attribute" do
      expect(deploys_pane.site_id).to eq("test-site-id")
    end
  end

  describe "#configure" do
    let(:deploy_data) do
      [
        {
          "id" => "deploy-123",
          "state" => "ready",
          "context" => "production",
          "branch" => "main",
          "commit_ref" => "abc123",
          "admin_url" => "https://app.netlify.com/sites/test-site",
          "url" => "https://test-site.netlify.app",
          "deploy_ssl_url" => "https://deploy-123--test-site.netlify.app",
          "review_id" => nil
        }
      ]
    end

    before do
      allow(Wassup::Helpers::Netlify).to receive(:deploys).and_return(deploy_data)
      allow(Wassup::Helpers::Netlify::Formatter).to receive(:deploy).and_return("Formatted Deploy")
      allow(pane_builder).to receive(:content).and_yield(content_builder)
      allow(pane_builder).to receive(:selection)
      allow(content_builder).to receive(:add_row)
    end

    it "configures the pane with deploy data" do
      expect(Wassup::Helpers::Netlify).to receive(:deploys).with(site_id: "test-site-id")

      deploys_pane.configure(pane_builder)
    end

    it "adds formatted deploy rows to content" do
      expect(content_builder).to receive(:add_row).with("Formatted Deploy", deploy_data.first)

      deploys_pane.configure(pane_builder)
    end

    it "configures selection to open deploy in Netlify admin" do
      expect(pane_builder).to receive(:selection).with('enter', 'Open in Netlify')

      deploys_pane.configure(pane_builder)
    end

    it "configures selection to open preview" do
      expect(pane_builder).to receive(:selection).with('o', 'Open preview')

      deploys_pane.configure(pane_builder)
    end
  end
end