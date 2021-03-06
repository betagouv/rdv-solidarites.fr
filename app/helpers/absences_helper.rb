# frozen_string_literal: true

module AbsencesHelper
  def absence_tag(absence)
    if absence.in_progress?
      tag.span("En cours", class: "badge badge-info")
    elsif absence.starts_at.past?
      tag.span("Passée", class: "badge badge-light")
    end
  end
end
