class AddIndexesToExpenses < ActiveRecord::Migration[8.0]
  def change
    # Adiciona índice para buscar rápido por usuário
    add_index :expenses, :user_id 
    
    # Adiciona índice para ordenar rápido por data (Dashboard usa muito isso)
    add_index :expenses, :date
    
    # Adiciona índice composto (Usuário + Data) para os gráficos serem instantâneos
    add_index :expenses, [:user_id, :date]
  end
end