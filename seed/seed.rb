require 'csv'
puts 'Clean database'
[Category, Author].each { |model| model.destroy_all }

puts 'Seed categories'
categories = ['Action & Adventure', 'Classic Fiction', 'Crime & Mystery', 'Fantasy', 'Historical', 'Romance', 'Science Fiction', 'Thrillers & Suspense']

categories.each { |category| Category.create!(name: category) }
all_categories = Category.all

puts 'Load CSV dump'
csv_text = File.read(Rails.root.join('lib', 'seeds', 'database.csv')) #здесь можно/нужно изменить путь к файлу из которого будет производиться запись в БД
csv = CSV.parse(csv_text, :headers => true, :encoding => 'ISO-8859-1')

puts 'Parse CSV'
csv.each do |row|
  author_name = row['author'].nil? ? FFaker::Book.author.split(' ') : row['author'].split(' ')
  dimensions = row['dimensions'].gsub(/\[|\]/,'').split(',').map(&:to_i)
  category = eval(row['category'])
  author = Author.find_or_create_by(first_name: author_name.first, last_name: author_name.last)
  b = Book.new
  b.title = row['title']
  b.autors.push(author)
  b.category = categories.include?(category.last) ? Category.where(name: category.last).first : all_categories.sample
  b.published = row['published']
  b.description = FFaker::HipsterIpsum.paragraphs.join('')#description книги плохо парсился, так как там куча абзацев + дефолтный текст, поэтому тут используется FFaker
  b.width = dimensions[0]
  b.height = dimensions[1]
  b.depth = row['pages'].to_i * 0.01
  b.price = row['price'].to_i
  b.isbn = row['isbn'].to_i#поле isbn необходимо для поиска картинки этой книги
  b.save!
end
