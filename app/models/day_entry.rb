class DayEntry < ApplicationRecord
  belongs_to :week
  belongs_to :child_item

  EMOJI_STATES = %w[green yellow red].freeze

  validates :day_of_week,     inclusion: { in: 0..6 }
  validates :emoji_state,     inclusion: { in: EMOJI_STATES }
  validates :child_item_id,   uniqueness: { scope: [ :week_id, :day_of_week ],
                                message: "déjà renseigné pour ce jour" }

  before_save :apply_contagion
  before_save :compute_points

  # Point d'entrée principal : met à jour ou crée une entrée pour un jour donné
  def self.set_emoji(week:, child_item:, day_of_week:, emoji_state:)
    entry = find_or_initialize_by(
      week: week,
      child_item: child_item,
      day_of_week: day_of_week
    )
    entry.emoji_state = emoji_state
    entry.save!
    entry
  end

  private

  # Applique la règle de contagion AVANT la sauvegarde de l'entrée courante.
  #
  # Règle : on regarde les entrées jaunes consécutives qui PRÉCÈDENT
  # immédiatement le jour courant (dans la même semaine, pour le même child_item).
  #
  # - Si le jour courant devient vert  → les jaunes précédents deviennent verts
  # - Si le jour courant devient rouge → les jaunes précédents deviennent rouges
  # - Si le jour courant devient jaune → rien à faire sur les précédents
  def apply_contagion
    return if emoji_state == "yellow"

    # Récupère les entrées précédentes triées par jour décroissant
    previous_entries = week.day_entries
                           .where(child_item: child_item)
                           .where("day_of_week < ?", day_of_week)
                           .order(day_of_week: :desc)

    # Remonte la chaîne tant que c'est jaune (consécutif)
    streak = []
    previous_entries.each do |entry|
      break unless entry.emoji_state == "yellow"
      # Vérifie que les jours sont bien consécutifs (pas de trou)
      expected_day = streak.empty? ? day_of_week - 1 : streak.last.day_of_week - 1
      break unless entry.day_of_week == expected_day
      streak << entry
    end

    return if streak.empty?

    # Propage l'état courant (green ou red) aux jaunes consécutifs
    streak.each do |entry|
      # On bypasse les callbacks pour éviter une récursion infinie
      entry.update_columns(
        emoji_state:      emoji_state,
        computed_points:  entry.child_item.points_for(emoji_state)
      )
    end
  end

  # Calcule les points de CETTE entrée selon son état final
  def compute_points
    self.computed_points = child_item.points_for(emoji_state)
  end
end
