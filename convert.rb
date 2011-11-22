require 'rexml/document'
require 'builder'

def product_xml
  xml = Builder::XmlMarkup.new( :indent => 2 )
  xml.instruct! :xml, :encoding => "UTF-8"
  xml.product do |p|
    p.name "Test"
  end
end



banner = 'Usage: ruby convert.rb iOS_project_path android_project_path_with_res.'

if ARGV.count < 2
  puts banner
  exit
end
mapping = Hash.new
mapping["zh_Hans.lproj"] = 'values-zh'
mapping["zh_Hant.lproj"] = 'values-zh-rTW'
mapping["ru.lproj"] = 'values-ru'

def read_android(path)
  result = Hash.new  
  if File.exists?(path)
    xml = File.read(path)
    doc= REXML::Document.new(xml)
    # order alphabetically
    doc.elements.each('/resources/string') do |p|
      result[p.attributes['name']] = p.text.gsub(/\n/,' ').squeeze(' ')
    end
  end
  return result
end

i = 0
Dir["#{ARGV[0]}/**.lproj"].each do |language|
  puts "Processing #{language}..."
  short_name = language[language.rindex('/')+1..-1]
  #output = thisfile.gsub('xib', 'strings')
  filenum = 0;
  # 1. Read the iOS localization  
  result=Hash.new
  Dir["#{ARGV[0]}/#{language}/**.strings"].each do |filename|
    puts "Processing #{filename}..."    
    file = File.new(filename, "r")
    counter = 1
    while (line = file.gets)
      separator = '" = "'
      parts = line.partition separator
      if parts[1] == separator
        result[parts[0][1..-1]] = parts[2].chomp '"'
      end
      counter = counter + 1
    end
    file.close
    file = File.read(filename)
    filenum += 1
  end
  puts "String files:#{filenum}"  
  output = mapping[short_name]
  if output.nil?
    # use default
    code = short_name[0..short_name.index('.')-1]    
    output = "values-#{code}"
    puts "Unknown mapping for #{short_name}.  Using default #{output}"
  end

  full_output = "#{ARGV[1]}/#{output}/strings.xml"
  puts "Writing to #{full_output}"
  # 2. read the android original
  original = read_android("#{ARGV[1]}/values/strings.xml")
  original.each do |key, value|
    if result[key].nil? 
      result[key] = value
    end
  end
  
  # 3. read the android localization
  old = read_android(full_output)
  old.each do |key, value|
    result[key] = value
  end
  
  #write to android  
  puts result
  xml = Builder::XmlMarkup.new( :indent => 2 )
  xml.instruct! :xml, :encoding => "UTF-8"
  xml.resources do |r|
    result.each do |key, value|
      r.string value
    end
  end
  i = i + 1  
end

puts "Languages:#{i}"