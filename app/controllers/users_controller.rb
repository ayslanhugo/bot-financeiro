class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user

  def update
    if @user.update(user_params)

      redirect_to root_path(month: params[:month]), notice: "Configurações atualizadas com sucesso!"
    else
      redirect_to root_path, alert: "Erro ao atualizar. Verifique os dados."
    end
  end

  private

  def set_user
    @user = current_user
  end

  def user_params
    params.require(:user).permit(:email, :telegram_id, :budget)
  end
end