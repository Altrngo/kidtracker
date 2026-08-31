# app/controllers/dashboard_controller.rb
class DashboardController < ApplicationController
  def index
    @children  = policy_scope(Child).includes(child_items: :item)
    @today     = Date.current
    @day_index = (@today.wday + 6) % 7   # 0 = lundi … 6 = dimanche
    @summaries = @children.map { |child| build_summary(child) }
  end

  private

  def build_summary(child)
    week         = Week.current_for(child)
    active_items = child.child_items.active
    entries      = week.day_entries.where(child_item_id: active_items.select(:id))
    today        = entries.where(day_of_week: @day_index)

    {
      child:        child,
      week:         week,
      week_score:   entries.sum(:computed_points),
      today_score:  today.sum(:computed_points),
      today_filled: today.count,
      today_total:  active_items.count
    }
  end
end
