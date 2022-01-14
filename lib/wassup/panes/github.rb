module Wassup
  module Panes
    module GitHub
      class PullRequests
        attr_accessor :org
        attr_accessor :repo

        def initialize(org:, repo:)
          @org = org
          @repo = repo
        end

        def configure(pane)
          pane.content do |content|
            prs = Helpers::GitHub.pull_requests(org: org, repo: repo)
            prs.each do |pr|
              display = Helpers::GitHub::Formatter.pr(pr)
              content.add_row(display, pr)
            end
          end
          pane.selection('enter', 'Open PR in browser') do |pr|
            `open #{pr['html_url']}`
          end
        end
      end

      class Releases
        attr_accessor :org
        attr_accessor :repo

        def initialize(org:, repo:)
          @org = org
          @repo = repo
        end

        def configure(pane)
          pane.content do |content|
            releases = Helpers::GitHub.releases(org: org, repo: repo)
            releases.each do |release|
              display = Helpers::GitHub::Formatter.release(release)
              content.add_row(display, release)
            end
          end
          pane.selection('enter', 'Open release in browser') do |pr|
            `open #{pr['html_url']}`
          end
        end
      end

      class Search
        attr_accessor :org
        attr_accessor :repo
        attr_accessor :query
        attr_accessor :show_interactions

        def initialize(org:, repo: nil, query:, show_interactions: false)
          @org = org
          @repo = repo
          @query = query
          @show_interactions = show_interactions
        end

        def configure(pane)
          pane.content do |content|
            # Uses GitHub's /search/issues API
            # Docs - https://docs.github.com/en/search-github/searching-on-github/searching-issues-and-pull-requests
            issues_or_prs = Helpers::GitHub.issues(org: org, repo: repo, q: query)
            issues_or_prs.each do |issue_or_pr|
              display = if issue_or_pr.has_key?('pull_request')
                          Helpers::GitHub::Formatter.pr(issue_or_pr, show_repo: true, show_interactions: show_interactions)
                        else
                          Helpers::GitHub::Formatter.issue(issue_or_pr, show_repo: true, show_interactions: show_interactions)
                        end
              content.add_row(display, issue_or_pr)
            end
          end
          pane.selection('enter', 'Open in browser') do |pr|
            `open #{pr['html_url']}`
          end
        end
      end
    end
  end
end