class CreneauxBuilderService < BaseService
  def initialize(motif_name, lieu, inclusive_date_range, **options)
    @motif_name = motif_name
    @lieu = lieu
    @inclusive_date_range = inclusive_date_range
    @options = options
    @for_agents = options.fetch(:for_agents, false)
    @agent_ids = options.fetch(:agent_ids, nil)
    @agent_name = options.fetch(:agent_name, false)
    @motif_location_type = options.fetch(:motif_location_type, nil)
    @plages_ouvertures = options[:plages_ouvertures]
    @only_first = options[:only_first]
  end

  def perform
    creneaux = plages_ouvertures.flat_map { |po| creneaux_for_plage_ouverture(po) }
    creneaux = creneaux.select { |c| c.starts_at >= Time.zone.now }
    uniq_by = @for_agents ? ->(c) { [c.starts_at, c.agent_id] } : ->(c) { c.starts_at }
    creneaux.uniq(&uniq_by).sort_by(&:starts_at)
  end

  def plages_ouvertures
    @plages_ouvertures ||= PlageOuverture
      .not_expired_for_motif_name_and_lieu(@motif_name, @lieu)
      .where(({ agent_id: @agent_ids } unless @agent_ids.nil?))
      .where(({ motifs: { location_type: @motif_location_type } } if @motif_location_type.present?))
  end

  private

  def motifs_for_plage_ouverture(plage_ouverture)
    motifs = plage_ouverture.motifs.where(name: @motif_name).active
    motifs = motifs.where(location_type: @motif_location_type) if @motif_location_type.present?
    @for_agents ? motifs : motifs.reservable_online
  end

  def creneaux_for_plage_ouverture(plage_ouverture)
    motifs_for_plage_ouverture(plage_ouverture)
      .flat_map { creneaux_for_plage_ouverture_and_motif(plage_ouverture, _1) }
  end

  def creneaux_for_plage_ouverture_and_motif(plage_ouverture, motif)
    plage_ouverture.occurences_for(@inclusive_date_range).flat_map do |occurence|
      creneaux_builder_for_date_service = CreneauxBuilderForDateService
        .new(plage_ouverture, motif, occurence.starts_at.to_date, @lieu, inclusive_date_range: @inclusive_date_range, **@options)
      if @only_first
        enum = creneaux_builder_for_date_service.next_creneaux_enumerator
        begin
          [enum.next]
        rescue StopIteration
          []
        end
      else
        creneaux_builder_for_date_service.perform
      end
    end.compact
  end
end
