# frozen_string_literal: true

describe Agent::UserPolicy, type: :policy do
  subject { described_class }

  let!(:organisation1) { create(:organisation) }
  let!(:organisation2) { create(:organisation) }
  let!(:agent) { create(:agent, basic_role_in_organisations: [organisation1, organisation2]) }

  context "in orga context" do
    let(:pundit_context) { AgentContext.new(agent, organisation1) }

    context "creating user that belongs to one of agent's orga" do
      let(:user) { build(:user, organisations: [organisation1]) }

      permissions :create? do
        it { is_expected.to permit(pundit_context, user) }
      end
    end

    context "creating user that belongs to both agent's orgas" do
      let(:user) { build(:user, organisations: [organisation1, organisation2]) }

      permissions :create? do
        # should not permit because in orga context
        it { is_expected.not_to permit(pundit_context, user) }
      end
    end

    context "creating user that belongs to no orga" do
      let(:user) { build(:user, organisations: []) }

      permissions :create? do
        it { is_expected.not_to permit(pundit_context, user) }
      end
    end

    context "creating user that belongs to orgas different from agents" do
      let(:user) { build(:user, organisations: [create(:organisation), create(:organisation)]) }

      permissions :create? do
        it { is_expected.not_to permit(pundit_context, user) }
      end
    end

    context "creating user that belongs both to agent's orga and different one" do
      let(:user) { build(:user, organisations: [organisation1, create(:organisation)]) }

      permissions :create? do
        it { is_expected.not_to permit(pundit_context, user) }
      end
    end
  end

  context "outside orga context, whole agent" do
    let(:pundit_context) { AgentContext.new(agent) }

    context "creating user that belongs to one of agent's orga" do
      let(:user) { build(:user, organisations: [organisation1]) }

      permissions :create? do
        it { is_expected.to permit(pundit_context, user) }
      end
    end

    context "creating user that belongs to both agent's orgas" do
      let(:user) { build(:user, organisations: [organisation1, organisation2]) }

      permissions :create? do
        it { is_expected.to permit(pundit_context, user) }
      end
    end

    context "creating user that belongs to no orga" do
      let(:user) { build(:user, organisations: []) }

      permissions :create? do
        it { is_expected.not_to permit(pundit_context, user) }
      end
    end

    context "creating user that belongs to orgas different from agents" do
      let(:user) { build(:user, organisations: [create(:organisation), create(:organisation)]) }

      permissions :create? do
        it { is_expected.not_to permit(pundit_context, user) }
      end
    end

    context "creating user that belongs both to agent's orga and different one" do
      let(:user) { build(:user, organisations: [organisation1, create(:organisation)]) }

      permissions :create? do
        it { is_expected.not_to permit(pundit_context, user) }
      end
    end
  end
end
