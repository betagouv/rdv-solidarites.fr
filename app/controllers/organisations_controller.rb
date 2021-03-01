class OrganisationsController < ApplicationController
  layout "application"

  def new
    @organisation = Organisation.new
    @organisation.agent_roles.build(level: AgentRole::LEVEL_ADMIN)
    @organisation.agent_roles.first.build_agent
  end

  def create
    @organisation = Organisation.new(organisation_params)
    @organisation.agent_roles.each do |agent_role|
      # because we're not passing through the regular `.invite!` method, we
      # have to hack our way into creating a user that bypasses validations and
      # callbacks:
      agent_role.agent.skip_confirmation!
      agent_role.agent.skip_invitation = true
      agent_role.agent.define_singleton_method(:password_required?) { false }
      agent_role.agent.define_singleton_method(:postpone_email_change?) { false }
      # forces devise_token_auth sync_uid to run
    end

    if Organisation.exists?(departement: @organisation.departement)
      flash[:error] = I18n.t("activerecord.errors.models.organisation.existing_orga_with_dep_need_connected_agent_html")
      redirect_to action: :new
    elsif @organisation.save
      agent = @organisation.agents.first
      agent.deliver_invitation if agent.from_safe_domain?
    else
      flash[:error] = @organisation.errors.full_messages.join(", ")
      redirect_to action: :new
    end
  end

  def organisation_params
    params.require(:organisation)
      .permit(
        :name, :departement,
        agent_roles_attributes: [:level, { agent_attributes: [:email, :service_id] }]
      )
  end
end
