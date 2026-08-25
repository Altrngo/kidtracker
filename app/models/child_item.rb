class ChildItem < ApplicationRecord
  belongs_to :child
  belongs_to :item

  has_many :day_entries, dependent: :destroy

  validates :green_points,  presence: true, numericality: { only_integer: true }
  validates :yellow_points, presence: true, numericality: { only_integer: true }
  validates :red_points,    presence: true, numericality: { only_integer: true }
  validates :item_id, uniqueness: { scope: :child_id,
    message: "est déjà assigné à cet enfant" }

  before_validation :set_defaults, on: :create

  scope :active, -> { where(active: true) }

  # Retourne les points correspondant à un état de smiley donné
  def points_for(emoji_state)
    case emoji_state.to_s
    when "green"  then green_points
    when "yellow" then yellow_points
    when "red"    then red_points
    else 0
    end
  end

  private

  def set_defaults
    self.green_points  ||= 1
    self.yellow_points ||= 0
    self.red_points    ||= -1
    self.active        = true if active.nil?
  end
end
