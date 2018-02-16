module FlightPlanCli
  module Commands
    class Checkout
      include FlightPlanCli::Config

      def initialize
        read_config
        @fetched = false
      end

      def process(issue)
        puts "Checking out branch for #{issue}"
        local_branch_for(issue) ||
          remote_branch_for(issue) ||
          new_branch_for(issue)
      rescue Git::GitExecuteError => e
        puts 'Unable to checkout'.red
        puts e.message
      end

      private

      def local_branch_for(issue)
        issue_branches = local_branches.map(&:name).grep(/##{issue}[^0-9]/)
        return false unless issue_branches.count == 1

        branch = issue_branches.first
        puts "Checking out local branch '#{branch}'".green
        git.checkout(branch)
        true
      end

      def remote_branch_for(issue)
        issue_branches = remote_branches.map(&:name).grep(/##{issue}[^0-9]/)
        return false unless issue_branches.count == 1

        remote_branch_name = issue_branches.first
        branch = remote_branches.find { |rb| rb.name == remote_branch_name }

        puts "Checking out and tracking remote branch '#{branch.name}'".green
        checkout_locally(branch)
        true
      end

      def checkout_locally(branch)
        local_name = branch.name[branch.remote_name.size + 1..-1]
        new_branch = git.branches.create(local_name, branch.name)
        new_branch.upstream = branch
        git.checkout(local_name)
      end

      def new_branch_for(issue)
        branches = client.board_tickets(remote_number: issue)
        # TODO: update flight_plan to only return one issue when remote_numer is provided
        branches = branches.select { |b| b['ticket']['remote_number'] == issue }
        return false unless branches.count == 1

        branch_name = branch_name(branches.first)

        puts "Creating new branch #{branch_name} from master".green

        git.branches.create(branch_name, 'origin/master')
        git.checkout(branch_name)
      end

      def branch_name(branch)
        "feature/##{branch['ticket']['remote_number']}-" +
          branch['ticket']['remote_title']
            .gsub(/[^a-z0-9\s]/i, '')
            .tr(' ', '-')
            .downcase
      end

      def local_branches
        git.branches.local
      end

      def remote_branches
        fetch
        git.branches.remote
      end

      def fetch
        return if @fetched
        puts 'Fetching...'.green
        git.remote('origin').fetch
        @fetched = true
      end
    end
  end
end
