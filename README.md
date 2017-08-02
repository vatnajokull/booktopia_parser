# Bookstore DB
## Набор скриптов для парсинга сайта https://www.booktopia.com.au
### Базовые положения
1. В папке lib находится файл `parser.rb`
2. Скрипт расчитан на работу с двумя моделями List и Book
  * В List хранится список ссылок на книги и индикатор того, была ли эта книга пропарсена или нет
  миграция модели
  ```
  create_table "lists", force: :cascade do |t|
    t.text     "book_url"
    t.boolean  "parsed",     default: false
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end
  ```
* В Book хранится непосредственно вся информация о книге, миграция модели:
```
create_table "books", force: :cascade do |t|
  t.string   "title"
  t.integer  "pages"
  t.text     "description"
  t.datetime "created_at",  null: false
  t.datetime "updated_at",  null: false
  t.integer  "author_id"
  t.integer  "category_id"
  t.string   "image_url"
  t.string   "isbn"
  t.string   "isbn_10"
  t.string   "publisher"
  t.float    "price"
  t.date     "published"
  t.index ["author_id"], name: "index_books_on_author_id", using: :btree
  t.index ["category_id"], name: "index_books_on_category_id", using: :btree
end
```

### Пример использования
1. К примеру мы хотим спарсить книги из раздела [Non-Fiction/Computing & I.T.](https://www.booktopia.com.au/books-online/non-fiction/computing-i-t-/cU-p1.html)
2. Для этого определяем количество страниц в каталоге, в данном случае из 967
3. Запускаем метод `parse_list` в цикле, к примеру
  ```
  for i in 1..967 do
    Parser.new.parse_list("https://www.booktopia.com.au/books-online/non-fiction/computing-i-t-/cU-p#{i}.html")
  end
  ```
4. После того, как у нас цикл отработает, в базе, в таблице `lists` окажется 96639 записей
5. Далее необходимо запустить метод `parse_book` для какой-то записи тз таблицы `lists`, пример скрипта может быть следующим
```
books = List.where(parsed: false).limit(50)
books.each do |book|
  Parser.new.parse_book(book.book_url)
end
```
6. В результате будет выполнения каждой итерации цикла, будет распарсена страница книги и информация о ней сохранится в базу, в таблицу `books`
7. В качестве рекомендаци и для удобства парсинга большого количества страниц и книг, я рекомендую использовал [Sidekiq](https://github.com/mperham/sidekiq) он позволяет запускать процессы в нескольких потоках, за счет чего общая скорость парсинга возрастает

## Дамб существующей базы (папка seed)
1. Копируем файл database.csv в папку из которой будет производиться запись, у меня в seed.rb прописано, что этот файл находится в `lib/seeds`
2. Запускаем `seed.rb`, он создает фиксированный список категорий и проходя по database.csv создает книги
3. Копируем картинки книг из [Dropbox](https://www.dropbox.com/sh/tnr8tk924pi6s84/AADRYtG7yiolt6fAN5xgnUfaa?dl=0), у меня они хранились в `app/assets/images`
4. Запускаем rake task по заливке картинок
  `rake upload_images_to_books`
