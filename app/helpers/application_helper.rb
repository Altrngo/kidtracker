# app/helpers/application_helper.rb
module ApplicationHelper
  # Mappe une couleur hex (stockée dans avatar_color) vers un nom de couleur CSS
  COLOR_MAP = {
    "#378ADD" => "blue",
    "#1D9E75" => "teal",
    "#D85A30" => "coral",
    "#BA7517" => "amber",
    "#534AB7" => "purple",
    "#D4537E" => "pink"
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
