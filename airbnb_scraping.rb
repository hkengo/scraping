
#jsに対応していないgem
require 'mechanize'
require 'csv'
require 'pp'
#jsに対応しているgem
require 'capybara'
require 'capybara/poltergeist'
require 'pry-rails'

class AirbnbCrawler < Mechanize

	
	def crawl_index(page_num)
		puts "GET page: #{page_num}"
		if page_num == 1
			self.get "https://www.airbnb.jp/s?host_id=7509034&s_tag=S6Cl-Mfg"
		elsif page_num >= 2
			self.get "https://www.airbnb.jp/s?host_id=7509034&ss_id=b4u7xp61&page=#{page_num}&s_tag=S6Cl-Mfg"
		end
		self.page.search('a.media-photo').map do |space_link|
			puts "Found #{space_link['href']}"
			space_link['href'] = "https://www.airbnb.jp" + space_link['href']
		end
	end
	
	def crawl_detail(page_uri)
		puts "GET #{page_uri}"
		self.get page_uri
		name = self.page.search('h1.overflow').text
		price = self.page.search('div#photos > span > span > div > div > div > span > span').text.gsub(/[^0-9]/, '').to_i
		# page.form_with(:name => nil) { |form| form.click_button(form.button_with(:name => '日本語で読む')) }
		text = ''
		self.page.search('div#description > div > div > div > div > div > p > span').each do |t|
			text = text + t.text + '\r\n'
		end
		
		capacity = self.page.search('div.row > div.col-md-6 > div > a.link-reset > strong').text.gsub(/[^0-9]/, '').to_i
		
		
		#画像はairbnb_get_image.rbで取れる
		
		#トップの画像を取得
		# src = self.page.search('div#photos/span.cover-photo/img.hide').at('img')['src']
		# self.get(src).save_as("./top_images/#{name}/" + name + "_top" + ".jpg")
		
		#トップ以外のスペース画像を取得
		# self.page.search("div > div > div > a.photo-grid-photo > img").each_with_index do |img, i|
		# 	puts src = img['src']
		# 	puts self.get(src).save_as("./top_images/#{name}/" + name + "_#{i+1}" + ".jpg")
		# end
		
		space_attr = { link: page_uri,
			             name: name,
									 price: price,
								   text: text,
								   capacity: capacity}
	end
end

AirbnbCrawler.new do |agent|
	attr_keys = []
  space_infos = (1..10).inject([]) { |page_list, page_num| page_list.concat agent.crawl_index(page_num) }.inject([]) do |space_infos, link|
    space_info = agent.crawl_detail(link)
    attr_keys += space_info.keys
    space_infos.push space_info
  end
	attr_keys.uniq!
	
	CSV.open('airbnb_scraping.csv', 'w') do |csv|
		csv << attr_keys
		space_infos.each do |info|
			row = attr_keys.map { |key| info.has_key?(key) ? info[key] :nil }
			csv << row
			pp row
		end
	end
end
	