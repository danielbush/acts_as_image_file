ActiveRecord::Schema.define(:version => 0) do
  create_table :images, :force => true do |t|
    t.string :name
  end
  create_table :image2s, :force => true do |t|
    t.string :name
  end
  create_table :image_files, :force => true do |t|
    t.string :image_name
  end
  create_table :image_file2s, :force => true do |t|
    t.string :name
  end
  create_table :tags, :force => true do |t|
    t.string :name
  end
  create_table :tagged_images, :force => true do |t|
    t.integer :image_id , :tag_id , :null => false
    t.string :name
  end
end 
