module FlightPlanCli
  module Commands
    class Checkout
      include FlightPlanCli::Config

      def process(issue)
        puts "Checking out branch for #{issue}"
        local_branch_for(issue) ||
          remote_branch_for(issue) ||
          new_branch_for(issue)
      rescue Rugged::CheckoutError => e
        puts "Unable to checkout: #{e.message}".red
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
        fetch
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
        read_config
        branches = client.board_tickets(
          board_id: board_id, repo_id: repo_id, remote_number: issue
        )
      end

      def local_branches
        @local_branches ||= git.branches.each(:local)
      end

      def remote_branches
        @remote_branches ||= git.branches.each(:remote)
      end

      def fetch
        puts 'Fetching...'.green
        git.remotes.each { |remote| remote.fetch(credentials: credentials) }
      end

      def credentials
        @ssh_agent ||= Rugged::Credentials::SshKey.new(
          username: 'git',
          publickey: File.expand_path('~/.ssh/id_rsa.pub'),
          privatekey: File.expand_path('~/.ssh/id_rsa')
        )
      end
    end
  end
end
