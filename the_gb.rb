require 'rubygems'
require 'watir-webdriver'
require 'open-uri'
require 'nokogiri'
require 'csv'

url     = 'http://georgebrown.ca/co/listings/program'
browser = Watir::Browser.start url

programLinks = [
  'http://www.georgebrown.ca/CO/gbc/programs/gened.html',
  'http://www.georgebrown.ca/CO/gbc/programs/libstudies.html',
  'http://www.georgebrown.ca/CO/gbc/continuous-learning/hospitality-ce/course-listing.html',
  'http://www.georgebrown.ca/co/ad/',
  'http://www.georgebrown.ca/co/pls/',
  'http://www.georgebrown.ca/co/csec/',
  'http://www.georgebrown.ca/co/hs/',
  'http://www.georgebrown.ca/co/hca/',
  'http://www.georgebrown.ca/co/cet/',
  'http://www.georgebrown.ca/co/bus/'
]

programLinks.each do |link|
  puts link
  browser.goto link
  if browser.text.include? "Links to course outlines (listed alphabetically by course code)"
    outlineLinks = browser.links(:href, /html/).collect { |link| link.href }
    outlineLinks.each do |link|
      url = link
      begin
        file = open(url)
        doc = Nokogiri::HTML(file)
        courseTitle   = /(?<=COURSE NAME:).*(?=COURSE CODE)/u.match(doc)
        courseCode    = /(?<=COURSE CODE:).*(?=CREDIT HOURS)/u.match(doc)
        requiredBooks = /(?<=LIST OF TEXTBOOKS AND OTHER TEACHING AIDS).*(?=TESTING POLICY)/smu.match(doc)
        CSV.open("course_data.csv", "ab") do |csv|
          csv << ["#{courseTitle}", "#{courseCode}", "#{requiredBooks}"]
        end
      rescue OpenURI::HTTPError => e
        if e.message == '404 Not Found'
          # supress and ignore the 404
        else
          raise e
        end
      end
    end
  else
    programLinks = browser.links(:xpath, \
                    '//*[(@id = "ctl00_ctl00_ctl00_ContentPlaceHolderMain_'\
                    'ContentPlaceHolderMain_ContentPlaceHolderMiddleColumn_'\
                    'ContentBlock1")]//li/a').collect { |link| link.href }
    programLinks.each do |link|
      puts link
      browser.goto link
      if browser.text.include? "Links to course outlines (listed alphabetically by course code)"
        outlineLinks = browser.links(:href, /html/).collect { |link| link.href }
        outlineLinks.each do |link|
          url = link
          begin
            file = open(url)
            doc = Nokogiri::HTML(file)
            courseTitle   = /(?<=COURSE NAME:).*(?=COURSE CODE)/u.match(doc)
            courseCode    = /(?<=COURSE CODE:).*(?=CREDIT HOURS)/u.match(doc)
            requiredBooks = /(?<=LIST OF TEXTBOOKS AND OTHER TEACHING AIDS).*(?=TESTING POLICY)/smu.match(doc)
            CSV.open("course_data.csv", "ab") do |csv|
              csv << ["#{courseTitle}", "#{courseCode}", "#{requiredBooks}"]
            end
          rescue OpenURI::HTTPError => e
            if e.message == '404 Not Found'
              # handle 404 error
            else
              raise e
            end
          end
        end
        browser.back
      end
      browser.back
    end
  end
end
