class Expense < ApplicationRecord
  belongs_to :user

  # Validações básicas (não deixa salvar sem valor ou descrição)
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :description, presence: true


  before_save :normalize_category

  private

  def normalize_category
    if category.present?
      # 1. strip: Remove espaços inúteis no início e fim
      # 2. capitalize: Deixa "uber" -> "Uber" (ou "MERCADO" -> "Mercado")
      self.category = category.strip.capitalize
    else
      # Se não preencheu categoria, define como 'Outros'
      self.category = 'Outros'
    end
  end
end