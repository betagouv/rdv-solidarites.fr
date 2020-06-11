class Organisation < ApplicationRecord
  has_paper_trail
  has_many :lieux, dependent: :destroy
  has_many :motifs, dependent: :destroy
  has_many :absences, dependent: :destroy
  has_many :rdvs, dependent: :destroy
  has_many :webhook_endpoints, dependent: :destroy
  has_and_belongs_to_many :agents, -> { distinct }

  has_many :user_profiles
  has_many :users, through: :user_profiles

  validates :name, presence: true, uniqueness: true
  validates :departement, presence: true, length: { is: 2 }
  validates :phone_number, phone: { allow_blank: true }

  after_create :notify_admin_organisation_created

  accepts_nested_attributes_for :agents

  def notify_admin_organisation_created
    return unless agents.present?

    Admins::OrganisationMailer.organisation_created(agents.first).deliver_later
  end

  def recent?
    1.week.ago < created_at
  end
end
