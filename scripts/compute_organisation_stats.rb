# frozen_string_literal: true

# rails runner scripts/compute_organisation_stats.rb organisation_id

org = Organisation.find(ARGV[0])
users = org.users
targeted_users_count = users.where("created_at > ?", 30.days.ago).count

avec_email = { targeted: 0, oriented: 0, sans_rdv: 0, validation_compte: [], prise_de_rdv: [], delai_rdv: [], delai_rdv_total: [], delai_rdv_effectif: [] }
sans_email = { targeted: 0, oriented: 0, sans_rdv: 0, validation_compte: [], prise_de_rdv: [], delai_rdv: [], delai_rdv_total: [], delai_rdv_effectif: [] }

rdv_agent = {
  total: org.rdvs.where(created_by: "agent").count,
  seen: org.rdvs.where(created_by: "agent").where(status: "seen").count,
  excused: org.rdvs.where(created_by: "agent").where(status: "excused").count,
  notexcused: org.rdvs.where(created_by: "agent").where(status: "notexcused").count,
  validation_compte: [], prise_de_rdv: [], delai_rdv: [], delai_rdv_total: [], delai_rdv_effectif: []
}
rdv_usager = {
  total: org.rdvs.where(created_by: "user").count,
  seen: org.rdvs.where(created_by: "user").where(status: "seen").count,
  excused: org.rdvs.where(created_by: "user").where(status: "excused").count,
  notexcused: org.rdvs.where(created_by: "user").where(status: "notexcused").count,
  validation_compte: [], prise_de_rdv: [], delai_rdv: [], delai_rdv_total: [], delai_rdv_effectif: []
}

users.each do |user|
  user_hash = if user.versions.first.changeset[:email]
                avec_email
              else
                sans_email
              end

  user_hash[:validation_compte] << user.invitation_accepted_at - user.created_at if user.invitation_accepted_at
  if user.created_at > 30.days.ago
    user_hash[:targeted] += 1
    user_hash[:oriented] += 1 if user.rdvs.where(status: 2).first
    user_hash[:sans_rdv] += 1 if user.rdvs.empty?
  end

  if (rdv = user.rdvs.first)
    rdvs_hash = case rdv.created_by
                when "agent"
                  rdv_agent
                when "user"
                  rdv_usager
                end
    user_hash[:prise_de_rdv] << rdv.created_at - user.created_at
    rdvs_hash[:prise_de_rdv] << rdv.created_at - user.created_at
    user_hash[:delai_rdv] << rdv.starts_at - rdv.created_at
    rdvs_hash[:delai_rdv] << rdv.starts_at - rdv.created_at
    user_hash[:delai_rdv_total] << rdv.starts_at - user.created_at
    rdvs_hash[:delai_rdv_total] << rdv.starts_at - user.created_at
  end

  next unless (rdv_effectue = user.rdvs.where(status: 2).first)

  rdv_seen_hash = case rdv_effectue.created_by
                  when "agent"
                    rdv_agent
                  when "user"
                    rdv_usager
                  end
  user_hash[:delai_rdv_effectif] << rdv_effectue.starts_at - user.created_at
  rdv_seen_hash[:delai_rdv_effectif] << rdv_effectue.starts_at - user.created_at
end

{
  users_count: users.count,
  active_users_count: users.where.not(invitation_accepted_at: nil).count,
  targeted_users_count: targeted_users_count,
  avec_email: avec_email,
  sans_email: sans_email,
  rdv_agent: rdv_agent,
  rdv_usager: rdv_usager
}
