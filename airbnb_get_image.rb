#jsに対応しているgem
require 'Capybara'
require 'Capybara/poltergeist'
require 'net/http'
require 'uri'
require 'pry-rails'


class AirbnbCrawler
	
	def session_set
		# セッション生成
		Capybara.run_server = false
		Capybara.register_driver :poltergeist do |app|
			Capybara::Poltergeist::Driver.new(app, :js_errors => false, :timeout => 60)
		end
		@session = Capybara::Session.new(:poltergeist)
	end
	
	def save_image(url, dirName, fileName)
		# ready filepath
		filePath = dirName + fileName
		
		unless File.exist?(filePath)
			# create folder if not exist
			FileUtils.mkdir_p(dirName) unless FileTest.exist?(dirName)
			
			# write image adata
			print "IMAGE: #{url}"
			open(filePath, 'wb') do |file|
				file.puts Net::HTTP.get_response(URI.parse(url)).body
			end
		else
			puts "File is alrady exist."
		end
	end
	
	def crawl_index(page_num)
		puts "GET page: #{page_num}"
		if page_num == 1
			@session.visit("https://www.airbnb.jp/s?host_id=7509034&s_tag=S6Cl-Mfg")
		elsif page_num >= 2
			@session.visit("https://www.airbnb.jp/s?host_id=7509034&ss_id=b4u7xp61&page=#{page_num}&s_tag=S6Cl-Mfg")
		end
		@session.all('div > a.media-photo').map do |space_link|
			space_link['href']
		end
	end
	
	def crawl_detail(page_uri)
		puts "GET #{page_uri}"
		@session.visit(page_uri)
		page = Nokogiri::HTML.parse(@session.html)
		name = page.search('h1.overflow').text
		
		#トップの画像
		src = page.search('div#photos/span.cover-photo/img.hide').at('img')['src']
		dirName = "./images/#{name}/"
		fileName = name + "_top" + ".jpg"
		puts save_image(src, dirName, fileName)
		
		#サブの写真
		page.search('ul > li.pull-left > a.media-photo.media-slideshow').each_with_index do |a, i|
			break if i > 29
			href = a['href']
			dirName = "./images/#{name}/"
			fileName = "#{name}_#{i + 1}.jpg"
			puts save_image(href, dirName, fileName)
		end
	end
end

agent = AirbnbCrawler.new
agent.session_set
space_infos = (1..10).inject([]) { |page_list, page_num| page_list.concat agent.crawl_index(page_num) }.inject([]) do |space_infos, link|
	space_info = agent.crawl_detail(link)
end
