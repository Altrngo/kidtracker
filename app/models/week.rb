class Week < ApplicationRecord
  belongs_to :child
  has_many :day_entries, dependent: :destroy

  DAYS = %w[Lundi Mardi Mercredi Jeudi Vendredi Samedi Dimanche].freeze

  validates :start_date, presence: true
  validates :start_date, uniqueness: { scope: :child_id }
  validate  :start_date_must_be_monday

  scope :finalized,     -> { where(finalized: true) }
  scope :not_finalized, -> { where(finalized: false) }
  scope :recent,        -> { order(start_date: :desc) }

  # Trouve ou crée la semaine courante pour un enfant donné
  def self.current_for(child)
    monday = Date.current.beginning_of_week(:monday)
    find_or_create_by!(child: child, start_date: monday)
  end

  def end_date
    start_date + 6.days
  end

  def label
    "Semaine du #{start_date.strftime('%d/%m')} au #{end_date.strftime('%d/%m/%Y')}"
  end

  # Calcule et persiste le score de la semaine, crédite le solde de l'enfant
  def finalize!
    return if finalized?

    total = day_entries.sum(:computed_points)

    transaction do
      update!(week_score: total, finalized: true)

      # Crée une transaction de points pour traçabilité
      child.point_transactions.create!(
        amount: total,
        reason: "Semaine du #{start_date.strftime('%d/%m/%Y')}"
      )

      # Met à jour le solde de l'enfant
      child.increment!(:total_points, total)
    end
  end

  private

  def start_date_must_be_monday
    return unless start_date
    unless start_date.monday?
      errors.add(:start_date, "doit être un lundi")
    end
  end
end
