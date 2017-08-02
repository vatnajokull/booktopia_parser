class Parser
  BASEURL = 'https://www.booktopia.com.au'
  require 'nokogiri'

  def parse_list(url)
    page = Nokogiri::HTML(open(url))
    page.css('ul#product-browse').css('div.product').each do |product|
      book_url = product.css('div.image')&.css('a')&.attr('href')&.text
      List.create!(book_url: book_url)
    end
  end

  def parse_book(url)
    page = Nokogiri::HTML(open(BASEURL + url))
    author_name = page.css('div#contributors')&.css('a')&.first&.text
    #так как у книги из booktopia.com.au может быть несколько категорий, тут парсится 2 последнии из хлебных крошек
    # к примеру "Books > Non-Fiction > Computing & I.T. > Computer Programming & Software Development > Program Concepts & Learning to Program"
    #cat = Program Concepts & Learning to Program
    #parent_cat = Computer Programming & Software Development
    cat = page.css('div#breadcrumbs')&.css('a')[-1]&.text
    parent_cat = page.css('div#breadcrumbs')&.css('a')[-2]&.text
    div_details = page.css('div#details')
    author = Author.find_or_create_by(name: author_name)
    category = Category.find_or_create_by(title: cat)
    category.update(parent: parent_cat) if category.parent.nil?

    book = author.books.new
    book.title = page.css('div#product-title')&.css('h1')&.text
    book.category_id = category.id
    book.description = page.css('div#description')&.text&.split(/\n/)&.sort_by{|p| p&.size}&.last&.lstrip&.gsub(/\r/,'')#description книги плохо парсился, так как там куча абзацев + дефолтный текст, в данном случае сохраняется самый длинный абзац, можно использовать в книге его или генерить при помощи FFaker
    book.image_url = page.css('div#image')&.css('img')&.attr('src')&.text&.gsub(/\r|\n/,'')&.gsub(/.pagespeed(.+|$)/,'')#тут будет храниться прямая ссылка на картинку, которую потом можно будет скачать
    book.price = page.css('div.prices')&.css('div.sale-price')&.first&.text&.gsub(/\$/,'')&.to_f
    book.pages = parse_book_details(div_details, 'Number Of Pages: ')&.to_i
    book.publisher = parse_book_details(div_details, 'Publisher:')&.lstrip&.rstrip
    book.isbn = parse_book_details(div_details, 'ISBN:')&.lstrip&.rstrip
    book.isbn_10 = parse_book_details(div_details, 'ISBN-10:')&.lstrip&.rstrip
    date_string = div_details.css('span.label').select{|b| b.text == ' Published: '}&.first&.next&.text&.gsub(/\t/,'')&.lstrip&.rstrip
    book.published = Date.parse(date_string) if !date_string.nil?
    book.save!

    List.where('book_url = ?', url).first.update!(parsed: true)
  end

  private

  def parse_book_details(div_details, field)
    div_details.css('b')&.select{|b| b&.text == field}&.first&.next&.text
  end
end
