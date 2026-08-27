# app/helpers/application_helper.rb
module ApplicationHelper
  # Mappe une couleur hex (stockée dans avatar_color) vers un nom de couleur CSS
  COLOR_MAP = {
    "#7C3AED" => "purple",
    "#2563EB" => "blue",
    "#059669" => "teal",
    "#D97706" => "amber",
    "#DC2626" => "red",
    "#DB2777" => "pink",
    "#0891B2" => "cyan"
  }.freeze

  def child_color_name(hex)
    COLOR_MAP.fetch(hex, "blue")
  end

  # Retourne la classe CSS de score selon la valeur
  def score_class(value)
    if value.positive?    then "kt-row-score--pos"
    elsif value.negative? then "kt-row-score--neg"
    else                       "kt-row-score--zero"
    end
  end

  def tx_class(amount)
    amount >= 0 ? "kt-tx-amount--pos" : "kt-tx-amount--neg"
  end
end
