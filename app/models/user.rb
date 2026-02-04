class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :expenses, dependent: :destroy
  
  has_many :categories, dependent: :destroy

  after_create :create_default_categories

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

  private

  def create_default_categories
    defaults = ["Alimentacao", "Transporte", "Moradia", "Lazer", "Saude", "Educacao", "Outros"]
    defaults.each do |cat_name|
      categories.create(name: cat_name)
    end
  end
end