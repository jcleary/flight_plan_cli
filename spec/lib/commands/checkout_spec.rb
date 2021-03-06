require 'spec_helper'

RSpec.describe FlightPlanCli::Commands::Checkout do
  describe '#process' do
    subject { described_class.new(issue_no, options) }
    let(:issue_no) { '5467' }
    let(:issue_title) { 'My New Feature' }
    let(:title_dash_case) { 'my-new-feature' }
    let(:issue_json) { { 'issue_no': issue_no } }
    let(:git) { double('git', branches: branches, remote: remote) }
    let(:branches) { double('branches', local: local_branches, remote: remote_branches) }
    let(:branch) { double('branch', name: branch_name) }
    let(:base_branch) { 'master' }
    let(:branch_prefix) { 'feature' }
    let(:branch_name) { "#{branch_prefix}/##{issue_no}-#{title_dash_case}" }
    let(:remote) { double('remote', fetch: true) }
    let(:local_branches) { [] }
    let(:remote_branches) { [] }
    let(:ticket) {
      {
        'ticket' => {
          'remote_number' => issue_no,
          'remote_title' => issue_title
        }
      }
    }
    let(:options) do
      { 'base' => base_branch, 'prefix' => branch_prefix }
    end

    before do
      allow(subject).to receive(:git) { git }
    end

    context 'when there is a local branch for the issue' do
      let(:local_branches) { [branch] }
      let(:output_text) { /Checking out local branch/ }

      it 'switches to the local branch' do
        expect(git).to receive(:checkout).with(branch_name)
        expect { subject.process }.to output(output_text).to_stdout
      end
    end

    context 'when there is a remote branch for the issue' do
      let(:remote_branches) { [branch] }
      let(:output_text) { /Checking out and tracking remote branch '#{branch_name}'/ }

      it 'checks out the remote branch locally' do
        expect(git).to receive(:checkout).with(branch_name)
        expect { subject.process }.to output(output_text).to_stdout
      end
    end

    context 'when there is no local or remote branch for an issue' do
      let(:output_text) { /Creating new branch #{branch_name} from master/ }
      let(:flight_plan) { double('FlightPlan') }

      context 'with no base branch provided' do
        it 'creates a local branch from master' do
          expect(subject).to receive(:flight_plan) { flight_plan }
          expect(flight_plan).to receive(:board_tickets)
            .with(remote_number: issue_no).and_return([ticket])
          expect(git).to receive(:checkout).with('master')
          expect(git).to receive(:pull)
          expect(git).to receive(:branch)
            .with(branch_name)
            .and_return(branch)
          expect(branch).to receive(:checkout)

          expect { subject.process }.to output(output_text).to_stdout
        end
      end

      context 'with base branch provided' do
        let(:base_branch) { 'other-branch' }
        let(:output_text) { /Creating new branch #{branch_name} from other-branch/ }

        it 'creates a local branch' do
          expect(subject).to receive(:flight_plan) { flight_plan }
          expect(flight_plan).to receive(:board_tickets)
            .with(remote_number: issue_no).and_return([ticket])
          expect(git).to receive(:checkout).with('other-branch')
          expect(git).to receive(:pull)
          expect(git).to receive(:branch)
            .with(branch_name)
            .and_return(branch)
          expect(branch).to receive(:checkout)

          expect { subject.process }.to output(output_text).to_stdout
        end
      end

      context 'with branch prefix provided' do
        let(:branch_prefix) { 'bug' }

        it 'creates a local branch' do
          expect(subject).to receive(:flight_plan) { flight_plan }
          expect(flight_plan).to receive(:board_tickets)
            .with(remote_number: issue_no).and_return([ticket])
          expect(git).to receive(:checkout).with('master')
          expect(git).to receive(:pull)
          expect(git).to receive(:branch)
            .with(branch_name)
            .and_return(branch)
          expect(branch).to receive(:checkout)

          expect { subject.process }.to output(output_text).to_stdout
        end
      end
    end
  end
end
