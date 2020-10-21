class Users::GeoSearch
  include SectorisationUtils

  def initialize(departement, city_code)
    @departement = departement
    @city_code = city_code
  end

  def departement_sectorisation_enabled?
    sectorisation_enabled?(@departement)
  end

  def attributed_organisations
    @attributed_organisations ||= \
      if departement_sectorisation_enabled?
        Organisation.attributed_to_sectors(matching_sectors)
      else
        Organisation.where(departement: @departement)
      end
  end

  def matching_zones
    return nil unless departement_sectorisation_enabled?

    @matching_zones ||= Zone.includes(:sector).where(city_code: @city_code)
  end

  def matching_sectors
    return nil unless departement_sectorisation_enabled?

    @matching_sectors ||= Sector.where(id: matching_zones.pluck(:sector_id))
  end

  def available_services
    @available_services ||= Service.where(id: available_motifs.pluck(:service_id).uniq)
  end

  def available_motifs
    @available_motifs ||= Motif.reservable_online.active.joins(:organisation, :plage_ouvertures).where(organisations: { id: attributed_organisations.pluck(:id) })
  end
end
