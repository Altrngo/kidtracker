# app/controllers/point_transactions_controller.rb
class PointTransactionsController < ApplicationController
  before_action :set_child

  def index
    @transactions = @child.point_transactions
                          .recent
                          .includes(:privilege, :user)
  end

  def new
    @privileges  = policy_scope(Privilege).active.order(:point_cost)
    @transaction = PointTransaction.new
  end

  def create
    if params[:point_transaction][:privilege_id].present?
      redeem_privilege
    else
      manual_adjustment
    end
  end

  private

  def set_child
    @child = Child.find(params[:child_id])
    authorize @child, :show?
  end

  # ── Rachat d'un privilège, en une ou plusieurs unités ─────────
  def redeem_privilege
    privilege = policy_scope(Privilege).find(params[:point_transaction][:privilege_id])
    quantity  = params[:point_transaction][:quantity].to_i
    quantity  = 1 if quantity < 1

    total_cost = privilege.point_cost * quantity

    if @child.total_points < total_cost
      redirect_to new_child_point_transaction_path(@child),
        alert: "Solde insuffisant : #{total_cost} pts nécessaires, " \
               "#{@child.first_name} en a #{@child.total_points}."
      return
    end

    label = quantity > 1 ? "#{privilege.name} ×#{quantity}" : privilege.name

    ActiveRecord::Base.transaction do
      @child.point_transactions.create!(
        privilege: privilege,
        quantity:  quantity,
        amount:    -total_cost,
        reason:    "Rachat : #{label}",
        user:      current_user
      )
      @child.decrement!(:total_points, total_cost)
    end

    redirect_to child_point_transactions_path(@child),
      notice: "#{label} accordé à #{@child.first_name} — #{total_cost} pts déduits."
  end

  # ── Ajustement manuel ────────────────────────────────────────
  def manual_adjustment
    amount = params[:point_transaction][:amount].to_i
    reason = params[:point_transaction][:reason].presence || "Ajustement manuel"

    if amount.zero?
      redirect_to new_child_point_transaction_path(@child),
        alert: "Le montant ne peut pas être zéro."
      return
    end

    ActiveRecord::Base.transaction do
      @child.point_transactions.create!(
        amount:   amount,
        reason:   reason,
        quantity: 1,
        user:     current_user
      )
      @child.increment!(:total_points, amount)
    end

    sign = amount.positive? ? "+#{amount}" : amount.to_s
    redirect_to child_point_transactions_path(@child),
      notice: "Ajustement de #{sign} pts enregistré."
  end
end
