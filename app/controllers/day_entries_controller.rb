# app/controllers/day_entries_controller.rb
class DayEntriesController < ApplicationController
  before_action :set_week

  # PATCH /children/:child_id/weeks/:week_id/day_entries
  # Reçoit : { child_item_id:, day_of_week:, emoji_state: }
  # Répond en Turbo Stream ou JSON selon le client
  def update
    child_item = @week.child.child_items.find(params[:child_item_id])

    entry = DayEntry.set_emoji(
      week:        @week,
      child_item:  child_item,
      day_of_week: params[:day_of_week].to_i,
      emoji_state: params[:emoji_state]
    )

    respond_to do |format|
      format.turbo_stream do
        # Re-rendu de la ligne complète de l'item pour refléter la contagion
        render turbo_stream: turbo_stream.replace(
          "row_child_item_#{child_item.id}",
          partial: "weeks/item_row",
          locals: {
            child_item: child_item,
            week: @week,
            entries_by_day: day_entries_for(child_item)
          }
        )
      end
      format.json { render json: { ok: true, computed_points: entry.computed_points } }
    end
  rescue ActiveRecord::RecordInvalid => e
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace("flash", partial: "shared/flash", locals: { message: e.message }) }
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
