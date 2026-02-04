require "csv"

class ExpensesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_expense, only: %i[ show edit update destroy ]

  # GET /expenses
  def index
    # 1. Escopo Base: Prepara a consulta mas NÃO vai ao banco ainda
    # Se usaste o scaffold de Categoria e alteraste a relação, usa .includes(:category)
    # Se ainda salvas o nome da categoria como texto, remove o .includes(:category)
    base_expenses = current_user.expenses.order(date: :desc)

    # 2. Dados para os Gráficos e Totais (Filtro do Mês Atual)
    # Usamos "range" para pegar o mês inteiro de uma vez
    current_month = Time.current.all_month
    expenses_this_month = base_expenses.where(date: current_month)

    # Cálculos agregados (Banco de dados faz a conta, é mais rápido que o Ruby)
    @total_gasto = current_user.current_month_spending
    @orcamento   = current_user.monthly_budget
    @saldo       = current_user.remaining_balance

    # Gráficos (Otimizados)
    @expenses_by_category = expenses_this_month.group(:category).sum(:amount)
    @expenses_by_day      = expenses_this_month.group_by_day(:date).sum(:amount)

    respond_to do |format|
      format.html do
        # ⚡ OTIMIZAÇÃO VISUAL:
        # Na tela, mostra apenas as últimas 100 despesas.
        # Isso faz a página carregar 10x mais rápido se tiveres muitos dados.
        @expenses = base_expenses.limit(100)
      end

      format.csv do
        # No Excel/CSV, queremos TUDO. Então usamos a base completa.
        send_data generate_csv(base_expenses), filename: "gastos-#{Date.today}.csv"
      end
    end
  end

  def show
  end

  def new
    @expense = Expense.new
  end

  def edit
  end

  def create
    @expense = current_user.expenses.build(expense_params)
    @expense.date ||= Time.current

    if @expense.save
      redirect_to root_path, notice: "Despesa criada com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @expense.update(expense_params)
      redirect_to root_path, notice: "Despesa atualizada.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @expense.destroy!
    redirect_to root_path, notice: "Despesa apagada.", status: :see_other
  end

  private
    def set_expense
      @expense = current_user.expenses.find(params[:id])
    end

    def expense_params
      # Permitimos category como string (nome) conforme seu form atual
      params.require(:expense).permit(:description, :amount, :category, :user_id, :date)
    end

    def generate_csv(expenses)
      # Batches: find_each economiza memória do servidor processando em lotes de 1000
      CSV.generate(headers: true, col_sep: ";") do |csv|
        csv << ["Data", "Descrição", "Categoria", "Valor (R$)", "Criado em"]

        expenses.find_each do |expense|
          csv << [
            expense.date&.strftime("%d/%m/%Y"),
            expense.description,
            expense.category, # Se mudaste para relacionamento, usa expense.category.name
            expense.amount.to_s.tr('.', ','),
            expense.created_at.strftime("%d/%m/%Y %H:%M")
          ]
        end
      end
    end
end