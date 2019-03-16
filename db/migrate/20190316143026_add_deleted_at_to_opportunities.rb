class AddDeletedAtToOpportunities < ActiveRecord::Migration[5.2]
  def change
    add_column :opportunities, :deleted_at, :datetime
    add_index  :opportunities, :deleted_at
  end
end
