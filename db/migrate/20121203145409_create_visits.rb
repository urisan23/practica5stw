class CreateVisits < ActiveRecord::Migration
  def up
    create_table :visits do |t|
         t.string :country
         t.string :abbr
         t.string :ip
      end
      add_index :visits, :ip
  end

  def down
    drop_table :visits
  end
end
