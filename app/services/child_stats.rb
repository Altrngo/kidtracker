# app/services/child_stats.rb
#
# Calcule les indicateurs d'un enfant.
# Une instance = un instantané : les résultats sont mémoïsés.
class ChildStats
  DAYS = %w[Lundi Mardi Mercredi Jeudi Vendredi Samedi Dimanche].freeze

  attr_reader :child

  def initialize(child)
    @child = child
  end

  # ── Base ──────────────────────────────────────────────────────
  def entries
    @entries ||= DayEntry.joins(:child_item)
                         .where(child_items: { child_id: child.id })
  end

  def counts
    @counts ||= entries.group(:emoji_state).count
  end

  def green         = counts.fetch("green", 0)
  def yellow        = counts.fetch("yellow", 0)
  def red           = counts.fetch("red", 0)
  def total_entries = green + yellow + red

  def success_rate
    return 0 if total_entries.zero?
    (green * 100.0 / total_entries).round
  end

  def share(state)
    return 0 if total_entries.zero?
    (counts.fetch(state, 0) * 100.0 / total_entries).round(1)
  end

  # ── Évolution hebdomadaire ────────────────────────────────────
  def weekly_scores(limit = 8)
    @weekly_scores ||= child.weeks
                            .order(start_date: :desc)
                            .limit(limit)
                            .to_a.reverse
                            .map do |w|
      score = w.finalized? ? w.week_score : w.day_entries.sum(:computed_points)
      { label: w.start_date.strftime("%d/%m"), score: score, finalized: w.finalized? }
    end
  end

  def average_week_score
    scores = weekly_scores.map { |w| w[:score] }
    return 0 if scores.empty?
    (scores.sum.to_f / scores.size).round(1)
  end

  # ── Par jour de la semaine ────────────────────────────────────
  def points_by_weekday
    raw = entries.group(:day_of_week).sum(:computed_points)
    (0..6).map { |d| { day: DAYS[d], short: DAYS[d][0..2], score: raw.fetch(d, 0) } }
  end

  def hardest_weekday = points_by_weekday.min_by { |d| d[:score] }

  # ── Par item ──────────────────────────────────────────────────
  def hardest_items(limit = 5)
    entries.where(emoji_state: "red")
           .joins(child_item: :item)
           .group("items.name")
           .order(Arel.sql("COUNT(*) DESC"))
           .limit(limit)
           .count
  end

  def best_items(limit = 5)
    entries.where(emoji_state: "green")
           .joins(child_item: :item)
           .group("items.name")
           .order(Arel.sql("COUNT(*) DESC"))
           .limit(limit)
           .count
  end

  # ── Points et privilèges ──────────────────────────────────────
  def points_earned
    @points_earned ||= child.point_transactions.where("amount > 0").sum(:amount)
  end

  def points_spent
    @points_spent ||= child.point_transactions.where("amount < 0").sum(:amount).abs
  end

  # Nombre d'unités de privilèges obtenues (tient compte des quantités)
  def privileges_redeemed
    @privileges_redeemed ||= child.point_transactions
                                  .where("reason LIKE ?", "Rachat :%")
                                  .sum(:quantity)
  end

  # Privilège le plus racheté
  def favourite_privilege
    row = child.point_transactions
               .where.not(privilege_id: nil)
               .joins(:privilege)
               .group("privileges.name")
               .order(Arel.sql("SUM(point_transactions.quantity) DESC"))
               .limit(1)
               .sum(:quantity)
    row.first  # [nom, quantité] ou nil
  end

  # ── Régularité ────────────────────────────────────────────────
  def current_week_fill_rate
    week = child.weeks.order(start_date: :desc).first
    return 0 if week.nil?

    items = child.child_items.active.count
    return 0 if items.zero?

    days   = ((Date.current - week.start_date).to_i + 1).clamp(1, 7)
    filled = week.day_entries.where(day_of_week: 0...days).count

    ((filled * 100.0) / (items * days)).round.clamp(0, 100)
  end

  def days_without_red
    week = child.weeks.order(start_date: :desc).first
    return 0 if week.nil?

    today_index = (Date.current.wday + 6) % 7
    streak = 0
    today_index.downto(0) do |d|
      break if week.day_entries.where(day_of_week: d, emoji_state: "red").exists?
      streak += 1
    end
    streak
  end
end
