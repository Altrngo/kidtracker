# app/models/week.rb
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

  def self.current_for(child)
    monday = Date.current.beginning_of_week(:monday)
    find_or_create_by!(child: child, start_date: monday)
  end

  def end_date = start_date + 6.days

  def label
    "Semaine du #{start_date.strftime('%d/%m')} au #{end_date.strftime('%d/%m/%Y')}"
  end

  # `author` est le parent qui a cliqué sur « Finaliser ».
  def finalize!(author = nil)
    return if finalized?

    total = day_entries.sum(:computed_points)

    transaction do
      update!(week_score: total, finalized: true)

      child.point_transactions.create!(
        amount: total,
        reason: "Semaine du #{start_date.strftime('%d/%m/%Y')}",
        user:   author
      )

      child.increment!(:total_points, total)
    end
  end

  private

  def start_date_must_be_monday
    return unless start_date
    errors.add(:start_date, "doit être un lundi") unless start_date.monday?
  end
end
