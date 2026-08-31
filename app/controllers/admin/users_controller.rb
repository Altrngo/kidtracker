# app/controllers/admin/users_controller.rb
module Admin
  class UsersController < ApplicationController
    before_action :require_admin!
    before_action :set_user, only: %i[show edit update destroy]

    def index
      @users = User.includes(:children).order(:username)
    end

    def show
      @children = @user.children
    end

    def new
      @user = User.new
    end

    def create
      @user = User.new(user_params)
      if @user.save
        redirect_to admin_users_path, notice: "Utilisateur #{@user.display_name} créé."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      attrs = user_params
      # Ne pas écraser le mot de passe si le champ est laissé vide
      attrs = attrs.except(:password, :password_confirmation) if attrs[:password].blank?

      if @user.update(attrs)
        redirect_to admin_users_path, notice: "Utilisateur mis à jour."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @user == current_user
        redirect_to admin_users_path, alert: "Vous ne pouvez pas supprimer votre propre compte."
        return
      end

      @user.destroy
      redirect_to admin_users_path, notice: "Utilisateur supprimé."
    end

    private

    def require_admin!
      redirect_to root_path, alert: "Accès réservé à l'administrateur." unless current_user.admin?
    end

    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      params.require(:user)
            .permit(:email, :username, :password, :password_confirmation, :admin)
    end
  end
end
