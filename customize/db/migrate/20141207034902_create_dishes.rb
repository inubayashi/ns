#coding : utf-8
class CreateDishes < ActiveRecord::Migration
  def change
    create_table :dishes do |t|
      t.string :name, null: false #料理名
      t.integer :kcal, null: false #容量あたりのカロリー
      t.integer :yen, null: false #容量あたりの値段
      t.string :genra #ジャンル 日本食など
      t.string :category #カテゴリー 主食、主菜、副菜
      t.timestamps
    end
  end
end
