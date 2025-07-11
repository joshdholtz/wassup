RSpec.describe Wassup::Helpers::GitHub do
  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("WASSUP_GITHUB_USERNAME").and_return("testuser")
    allow(ENV).to receive(:[]).with("WASSUP_GITHUB_ACCESS_TOKEN").and_return("token123")
  end

  describe ".issues" do
    let(:issues_response) do
      {
        "items" => [
          {
            "number" => 42,
            "title" => "Fix bug in login",
            "created_at" => "2023-01-01T00:00:00Z",
            "user" => { "login" => "johndoe" },
            "comments" => 5,
            "reactions" => { "total_count" => 3 }
          }
        ]
      }
    end

    before do
      allow(Wassup::Helpers::GitHub::RateLimiter).to receive(:execute_request).and_return(issues_response.to_json)
      allow(JSON).to receive(:parse).and_return(issues_response)
    end

    it "searches for issues in an organization" do
      expect(Wassup::Helpers::GitHub::RateLimiter).to receive(:execute_request).with(
        method: :get,
        url: "https://api.github.com/search/issues?q=org:testorg"
      )

      issues = Wassup::Helpers::GitHub.issues(org: "testorg")
      expect(issues).to eq(issues_response["items"])
    end

    it "searches for issues in a specific repository" do
      expect(Wassup::Helpers::GitHub::RateLimiter).to receive(:execute_request).with(
        method: :get,
        url: "https://api.github.com/search/issues?q=repo:testorg/testrepo"
      )

      Wassup::Helpers::GitHub.issues(org: "testorg", repo: "testrepo")
    end

    it "includes additional query parameters" do
      expect(Wassup::Helpers::GitHub::RateLimiter).to receive(:execute_request).with(
        method: :get,
        url: "https://api.github.com/search/issues?q=org:testorg is:open"
      )

      Wassup::Helpers::GitHub.issues(org: "testorg", q: "is:open")
    end
  end

  describe ".repos" do
    let(:repos_response) do
      [
        { "name" => "repo1", "full_name" => "org/repo1" },
        { "name" => "repo2", "full_name" => "org/repo2" }
      ]
    end

    before do
      allow(Wassup::Helpers::GitHub::RateLimiter).to receive(:execute_request).and_return(repos_response.to_json)
      allow(JSON).to receive(:parse).and_return(repos_response)
    end

    it "fetches repositories for an organization" do
      expect(Wassup::Helpers::GitHub::RateLimiter).to receive(:execute_request).with(
        method: :get,
        url: "https://api.github.com/orgs/testorg/repos"
      )

      repos = Wassup::Helpers::GitHub.repos(org: "testorg")
      expect(repos).to eq(repos_response)
    end
  end

  describe ".pull_requests" do
    let(:repos_response) do
      [{ "name" => "repo1" }, { "name" => "repo2" }]
    end

    let(:pr_response) do
      [
        {
          "number" => 123,
          "title" => "Add new feature",
          "created_at" => "2023-01-01T00:00:00Z",
          "user" => { "login" => "contributor" }
        }
      ]
    end

    before do
      allow(Wassup::Helpers::GitHub::RateLimiter).to receive(:execute_request).and_return(repos_response.to_json, pr_response.to_json, pr_response.to_json)
      allow(JSON).to receive(:parse).and_return(repos_response, pr_response, pr_response)
    end

    it "fetches pull requests for a specific repository" do
      allow(Wassup::Helpers::GitHub::RateLimiter).to receive(:execute_request).and_return(pr_response.to_json)
      allow(JSON).to receive(:parse).and_return(pr_response)
      
      expect(Wassup::Helpers::GitHub::RateLimiter).to receive(:execute_request).with(
        method: :get,
        url: "https://api.github.com/repos/testorg/testrepo/pulls?per_page=100"
      )

      prs = Wassup::Helpers::GitHub.pull_requests(org: "testorg", repo: "testrepo")
      expect(prs).to eq(pr_response)
    end

    it "fetches pull requests for all repositories in an organization" do
      prs = Wassup::Helpers::GitHub.pull_requests(org: "testorg")
      expect(prs.length).to eq(2)
    end
  end

  describe ".releases" do
    let(:releases_response) do
      [
        {
          "tag_name" => "v1.0.0",
          "name" => "Version 1.0.0",
          "published_at" => "2023-01-01T00:00:00Z"
        }
      ]
    end

    before do
      allow(Wassup::Helpers::GitHub::RateLimiter).to receive(:execute_request).and_return(releases_response.to_json)
      allow(JSON).to receive(:parse).and_return(releases_response)
    end

    it "fetches releases for a repository" do
      expect(Wassup::Helpers::GitHub::RateLimiter).to receive(:execute_request).with(
        method: :get,
        url: "https://api.github.com/repos/testorg/testrepo/releases"
      )

      releases = Wassup::Helpers::GitHub.releases(org: "testorg", repo: "testrepo")
      expect(releases).to eq(releases_response)
    end
  end
end

RSpec.describe Wassup::Helpers::GitHub::Formatter do
  describe ".issue" do
    let(:issue) do
      {
        "number" => 42,
        "title" => "Fix authentication bug",
        "created_at" => "2023-01-01T00:00:00Z",
        "user" => { "login" => "johndoe" },
        "comments" => 5,
        "reactions" => { "total_count" => 3 },
        "repository_url" => "https://api.github.com/repos/org/repo"
      }
    end

    before do
      allow(Time).to receive(:now).and_return(Time.parse("2023-01-11T00:00:00Z"))
    end

    it "formats an issue with basic information" do
      result = Wassup::Helpers::GitHub::Formatter.issue(issue)
      expect(result).to include("#42")
      expect(result).to include("10d ago")
      expect(result).to include("Fix authentication bug")
    end

    it "includes repository name when show_repo is true" do
      result = Wassup::Helpers::GitHub::Formatter.issue(issue, show_repo: true)
      expect(result).to include("[fg=gray]repo")
    end

    it "includes username when show_username is true" do
      result = Wassup::Helpers::GitHub::Formatter.issue(issue, show_username: true)
      expect(result).to include("[fg=magenta]johndoe")
    end

    it "includes interactions when show_interactions is true" do
      result = Wassup::Helpers::GitHub::Formatter.issue(issue, show_interactions: true)
      expect(result).to include("[fg=red]8")
    end

    it "delegates to pr formatter" do
      expect(Wassup::Helpers::GitHub::Formatter).to receive(:pr).with(issue, show_repo: true, show_username: true, show_interactions: true)
      Wassup::Helpers::GitHub::Formatter.issue(issue, show_repo: true, show_username: true, show_interactions: true)
    end
  end

  describe ".pr" do
    let(:pr) do
      {
        "number" => 123,
        "title" => "Add new authentication method",
        "created_at" => "2023-01-01T00:00:00Z",
        "user" => { "login" => "contributor" },
        "comments" => 3,
        "reactions" => { "total_count" => 2 },
        "repository_url" => "https://api.github.com/repos/org/myrepo"
      }
    end

    before do
      allow(Time).to receive(:now).and_return(Time.parse("2023-01-11T00:00:00Z"))
    end

    it "formats a pull request with basic information" do
      result = Wassup::Helpers::GitHub::Formatter.pr(pr)
      expect(result).to include("#123")
      expect(result).to include("10d ago")
      expect(result).to include("Add new authentication method")
    end

    it "calculates days correctly" do
      result = Wassup::Helpers::GitHub::Formatter.pr(pr)
      expect(result).to include(" 10d ago")
    end

    it "formats number with consistent width" do
      result = Wassup::Helpers::GitHub::Formatter.pr(pr)
      expect(result).to match(/\[fg=yellow\]#123\s+/)
    end
  end

  describe ".release" do
    let(:release) do
      {
        "tag_name" => "v2.1.0",
        "name" => "Version 2.1.0 - Bug fixes",
        "published_at" => "2023-01-05T00:00:00Z"
      }
    end

    before do
      allow(Time).to receive(:now).and_return(Time.parse("2023-01-15T00:00:00Z"))
    end

    it "formats a release with tag name and days" do
      result = Wassup::Helpers::GitHub::Formatter.release(release)
      expect(result).to include("v2.1.0")
      expect(result).to include(" 10d ago")
      expect(result).to include("Version 2.1.0 - Bug fixes")
    end

    it "uses correct color formatting" do
      result = Wassup::Helpers::GitHub::Formatter.release(release)
      expect(result).to include("[fg=yellow]v2.1.0")
      expect(result).to include("[fg=cyan] 10d ago")
      expect(result).to include("[fg=gray]Version 2.1.0 - Bug fixes")
    end
  end
end