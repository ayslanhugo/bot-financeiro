class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :expenses
  # Define um valor padrão caso o orçamento seja nil (vazio)
  def monthly_budget
    budget || 0.0
  end

  def current_month_spending
    expenses.where(date: Time.current.all_month).sum(:amount)
  end

  def remaining_balance
    monthly_budget - current_month_spending
  end

  def budget_progress_percent
    return 0 if monthly_budget.zero?
    (current_month_spending / monthly_budget) * 100
  end
end
