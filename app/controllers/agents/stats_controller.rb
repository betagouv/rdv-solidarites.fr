class Agents::StatsController < AgentAuthController
  respond_to :html, :json

  def index
    @stats = Stat.new(rdvs: rdvs_for_current_agent)

    respond_to do |format|
      format.ods { send_data(RdvStatBuilderService.perform_with(current_organisation, StringIO.new), filename: "stats.ods", type: "application/ods") }
      format.html
    end
  end

  def rdvs
    authorize(current_agent)
    render json: Stat.new(rdvs: rdvs_for_current_agent).rdvs_group_by_week_fr.chart_json
  end

  private

  def rdvs_for_current_agent
    policy_scope(Rdv).joins(:agents).where(agents: { id: current_agent.id })
  end
end
