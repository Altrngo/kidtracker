# app/controllers/point_transactions_controller.rb
class PointTransactionsController < ApplicationController
  before_action :set_child

  def index
    @transactions = @child.point_transactions.recent.includes(:privilege)
  end

  # GET — formulaire de rachat d'un privilège
  def new
    authorize @child, :show?
    @privileges   = policy_scope(Privilege).active.order(:point_cost)
    @transaction  = PointTransaction.new
  end

  # POST — effectue le rachat ou l'ajustement
  def create
    authorize @child, :show?

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

  def redeem_privilege
    privilege = policy_scope(Privilege).find(params[:point_transaction][:privilege_id])

    if @child.total_points < privilege.point_cost
      redirect_to new_child_point_transaction_path(@child),
        alert: "Solde insuffisant (#{@child.total_points} pts) pour ce privilège (#{privilege.point_cost} pts)."
      return
    end

    ActiveRecord::Base.transaction do
      tx = @child.point_transactions.create!(
        privilege: privilege,
        amount:    -privilege.point_cost,
        reason:    "Rachat : #{privilege.name}"
      )
      @child.decrement!(:total_points, privilege.point_cost)
    end

    redirect_to child_point_transactions_path(@child),
      notice: "Privilège \"#{privilege.name}\" accordé ! −#{privilege.point_cost} pts."
  end

  def manual_adjustment
    # Réservé à l'admin ou au parent propriétaire de l'enfant
    amount = params[:point_transaction][:amount].to_i
    reason = params[:point_transaction][:reason].presence || "Ajustement manuel"

    if amount.zero?
      redirect_to new_child_point_transaction_path(@child),
        alert: "Le montant ne peut pas être zéro."
      return
    end

    ActiveRecord::Base.transaction do
      @child.point_transactions.create!(amount: amount, reason: reason)
      @child.increment!(:total_points, amount)
    end

    sign = amount.positive? ? "+#{amount}" : amount.to_s
    redirect_to child_point_transactions_path(@child),
      notice: "Ajustement de #{sign} pts enregistré."
  end
end
