# app/controllers/day_entries_controller.rb
class DayEntriesController < ApplicationController
  before_action :set_week

  # PATCH .../day_entries/:id
  # Params : child_item_id, day_of_week, emoji_state
  # emoji_state == "none" → l'entrée est supprimée
  def update
    child_item = @week.child.child_items.find(params[:child_item_id])
    day        = params[:day_of_week].to_i

    if params[:emoji_state] == "none"
      @week.day_entries.where(child_item: child_item, day_of_week: day).destroy_all
    else
      DayEntry.set_emoji(
        week:        @week,
        child_item:  child_item,
        day_of_week: day,
        emoji_state: params[:emoji_state]
      )
    end

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace(
            "row_child_item_#{child_item.id}",
            partial: "weeks/item_row",
            locals: {
              child_item:     child_item,
              week:           @week,
              entries_by_day: day_entries_for(child_item)
            }
          ),
          turbo_stream.replace(
            "week_totals",
            partial: "weeks/totals",
            locals: { week: @week }
          )
        ]
      end
      format.json { render json: { ok: true } }
    end
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound => e
    respond_to do |format|
      format.turbo_stream { head :unprocessable_entity }
      format.json { render json: { ok: false, error: e.message }, status: :unprocessable_entity }
    end
  end

  private

  def set_week
    child = Child.find(params[:child_id])
    authorize child, :show?
    @week = child.weeks.find(params[:week_id])
  end

  def day_entries_for(child_item)
    @week.day_entries
         .where(child_item: child_item)
         .each_with_object({}) { |e, h| h[e.day_of_week] = e }
  end
end
