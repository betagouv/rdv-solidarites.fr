# frozen_string_literal: true

class SearchCreneauxForAgentsService < BaseService
  def initialize(agent_creneaux_search_form)
    @form = agent_creneaux_search_form
  end

  def perform
    lieux.map { build_result(_1) }
  end

  private

  def build_result(lieu)
    OpenStruct.new(
      lieu: lieu,
      next_availability: FindAvailabilityService.perform_with(
        @form.motif.name,
        lieu,
        Time.zone.today,
        for_agents: true,
        agent_ids: @form.agent_ids,
        motif_location_type: @form.motif.location_type,
        service: @form.service
      ),
      creneaux: CreneauxBuilderService.perform_with(
        @form.motif.name,
        lieu,
        @form.date_range,
        for_agents: true,
        agent_ids: @form.agent_ids,
        motif_location_type: @form.motif.location_type,
        service: @form.service
      )
    )
  end

  def lieux
    return [] if @form.motif.blank?

    return @lieux unless @lieux.nil?

    @lieux = @form.organisation.lieux
    @lieux = \
      if @form.lieu_ids.present?
        @lieux.where(id: @form.lieu_ids)
      else
        @lieux.for_motif(@form.motif)
      end
    @lieux = @lieux.where(id: PlageOuverture.where(agent_id: @form.agent_ids).select(:lieu_id)) if @form.agent_ids.present?
    @lieux = @lieux.ordered_by_name
    @lieux
  end
end
