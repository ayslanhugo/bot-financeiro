require "csv" # 👈 1. Isto permite ao Rails criar planilhas

class ExpensesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_expense, only: %i[ show edit update destroy ]

  # GET /expenses or /expenses.json
  def index
    # Garante que só vê as próprias despesas
    @expenses = current_user.expenses.order(date: :desc)
    
    # Prepara dados para os gráficos (apenas mês atual)
    @expenses_by_category = current_user.expenses.where(date: Time.current.all_month).group(:category).sum(:amount)
    @expenses_by_day = current_user.expenses.where(date: Time.current.all_month).group_by_day(:date).sum(:amount)

    @total_gasto = current_user.current_month_spending
    @orcamento = current_user.monthly_budget
    @saldo = current_user.remaining_balance

    # 👇 2. A Lógica do Download da Planilha
    respond_to do |format|
      format.html
      format.csv do
        # Gera o arquivo com nome tipo "gastos-2026-02-03.csv"
        send_data generate_csv(@expenses), filename: "gastos-#{Date.today}.csv"
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

  # POST /expenses
  def create
    @expense = current_user.expenses.build(expense_params)
    # Se não vier data (ex: via bot), assume hoje. Se vier do form manual, respeita a data escolhida.
    @expense.date ||= Time.current 

    respond_to do |format|
      if @expense.save
        # Redireciona para o Dashboard (root_path) em vez da tela de detalhes
        format.html { redirect_to root_path, notice: "Despesa criada com sucesso." }
      else
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /expenses/1
  def update
    respond_to do |format|
      if @expense.update(expense_params)
        # Volta para o Dashboard após editar
        format.html { redirect_to root_path, notice: "Despesa atualizada com sucesso.", status: :see_other }
      else
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /expenses/1
  def destroy
    @expense.destroy!

    respond_to do |format|
      # Volta para o Dashboard após apagar
      format.html { redirect_to root_path, notice: "Despesa apagada com sucesso.", status: :see_other }
    end
  end

  private
    def set_expense
      @expense = current_user.expenses.find(params[:id])
    end

    def expense_params
      params.require(:expense).permit(:description, :amount, :category, :user_id, :date)
    end

    # 👇 3. Método que desenha a planilha linha por linha
    def generate_csv(expenses)
      # col_sep: ";" é importante para o Excel no Brasil/Europa abrir as colunas certas
      CSV.generate(headers: true, col_sep: ";") do |csv|
        # Cabeçalho da Planilha
        csv << ["Data", "Descrição", "Categoria", "Valor (R$)", "Criado em"]

        # Linhas de dados
        expenses.each do |expense|
          csv << [
            expense.date.strftime("%d/%m/%Y"), # Data formatada (Dia/Mês/Ano)
            expense.description,
            expense.category,
            expense.amount.to_s.tr('.', ','),  # Troca ponto por vírgula (R$ 10,50)
            expense.created_at.strftime("%d/%m/%Y %H:%M")
          ]
        end
      end
    end
end