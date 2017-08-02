task :upload_images_to_books do
  puts 'Add images to books'
  n = (Book.count / 100.0).ceil
  limit = 100
  (0..n).each do |i|
    puts "Offset # #{i} is running"
    Book.limit(limit).offset(i * limit).each do |book|
      image = book.images.new#в зависимости от того, как и где хранятся картинки по отношению к книги, возможно эту строку необходимо будет заменить
      my_file = Rails.root.join("app/assets/images/#{book.isbn}.jpg").open#предполаегтся, что тут будут находиться все картинки
      image.file = my_file
      book.save!
      puts "Saved image #{book.id} : #{book.isbn}"
    end
  end
end
