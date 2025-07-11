RSpec.describe Wassup::Helpers::Netlify do
  before do
    allow(ENV).to receive(:[]).with('WASSUP_NETLIFY_TOKEN').and_return('test-token')
  end

  describe ".deploys" do
    let(:deploys_response) do
      [
        {
          "id" => "deploy-1",
          "state" => "ready",
          "context" => "production",
          "branch" => "main",
          "commit_ref" => "abc123def456",
          "deploy_url" => "https://deploy-1.netlify.app"
        }
      ]
    end

    before do
      allow(RestClient::Request).to receive(:execute).and_return(deploys_response.to_json)
      allow(JSON).to receive(:parse).and_return(deploys_response)
    end

    it "fetches deploys for a site" do
      expect(RestClient::Request).to receive(:execute).with(
        method: :get,
        url: "https://api.netlify.com/api/v1/sites/test-site-id/deploys",
        headers: { "Authorization": "Bearer test-token", "User-Agent": "Wassup" }
      )

      deploys = Wassup::Helpers::Netlify.deploys(site_id: "test-site-id")
      expect(deploys).to eq(deploys_response)
    end
  end
end

RSpec.describe Wassup::Helpers::Netlify::Formatter do
  describe ".deploy" do
    let(:deploy) do
      {
        "review_id" => nil,
        "context" => "production",
        "state" => "ready",
        "error_message" => nil,
        "branch" => "main",
        "commit_ref" => "abc123def456789",
        "deploy_url" => "https://deploy-1.netlify.app"
      }
    end

    it "formats a successful deploy" do
      result = Wassup::Helpers::Netlify::Formatter.deploy(deploy)
      expect(result).to include("[fg=green]Production")
      expect(result).to include("(ready)")
      expect(result).to include("main@abc123d")
    end

    it "formats a building deploy with yellow color" do
      deploy["state"] = "building"
      result = Wassup::Helpers::Netlify::Formatter.deploy(deploy)
      expect(result).to include("[fg=yellow]Production")
      expect(result).to include("(building)")
    end

    it "formats an enqueued deploy with magenta color" do
      deploy["state"] = "enqueued"
      result = Wassup::Helpers::Netlify::Formatter.deploy(deploy)
      expect(result).to include("[fg=magenta]Production")
      expect(result).to include("(enqueued)")
    end

    it "formats an error deploy with red color" do
      deploy["state"] = "error"
      result = Wassup::Helpers::Netlify::Formatter.deploy(deploy)
      expect(result).to include("[fg=red]Production")
      expect(result).to include("(error)")
    end

    it "formats a cancelled deploy with gray color" do
      deploy["state"] = "cancelled"
      result = Wassup::Helpers::Netlify::Formatter.deploy(deploy)
      expect(result).to include("[fg=gray]Production")
      expect(result).to include("(cancelled)")
    end

    it "detects cancelled state from error message" do
      deploy["error_message"] = "Build was canceled"
      result = Wassup::Helpers::Netlify::Formatter.deploy(deploy)
      expect(result).to include("(cancelled)")
    end

    it "includes review ID when present" do
      deploy["review_id"] = 123
      result = Wassup::Helpers::Netlify::Formatter.deploy(deploy)
      expect(result).to include("- #123")
    end

    it "handles deploy-preview context" do
      deploy["context"] = "deploy-preview"
      result = Wassup::Helpers::Netlify::Formatter.deploy(deploy)
      expect(result).to include("Deploy Preview")
    end

    it "handles branch-deploy context" do
      deploy["context"] = "branch-deploy"
      result = Wassup::Helpers::Netlify::Formatter.deploy(deploy)
      expect(result).to include("Branch Deploy")
    end

    it "handles missing branch and commit gracefully" do
      deploy["branch"] = nil
      deploy["commit_ref"] = nil
      result = Wassup::Helpers::Netlify::Formatter.deploy(deploy)
      expect(result).not_to include("[fg=cyan]:")
    end

    it "uses HEAD when commit_ref is nil" do
      deploy["commit_ref"] = nil
      result = Wassup::Helpers::Netlify::Formatter.deploy(deploy)
      expect(result).to include("main@HEAD")
    end

    it "truncates commit ref to 7 characters" do
      deploy["commit_ref"] = "abcdefghijklmnop"
      result = Wassup::Helpers::Netlify::Formatter.deploy(deploy)
      expect(result).to include("main@abcdefg")
    end
  end
end