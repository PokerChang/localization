require 'rexml/document'
require 'builder'

# Utility function to make transcoding the regex simpler.
def get_regex(pattern, encoding='ASCII', options=0)
  Regexp.new(pattern.encode(encoding),options)
end


def output_xml (result)
  #sort result
  result = result.sort
  
  #output XML
  xml = Builder::XmlMarkup.new( :indent => 2 )
  xml.instruct! :xml, :encoding => "UTF-8"
  xml.resources do |r|
    result.each do |key, value|
      r.string value, :name=>key
    end
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
  Dir["#{language}/Localizable.strings"].each do |filename|
    puts "Processing #{filename}..."    
    counter = 1
    token = 0
    skip = 0
    open(filename, "rb:UTF-16LE") do |file|
      while (line = file.gets)
        separator = '" = "'.encode('UTF-16LE')
        parts = line.partition separator
        if parts[1] == separator
          value = (parts[2][0..parts[2].index('";'.encode('UTF-16LE'))-1]).encode('UTF-8')
          # replace special chars to underscore _
          regex = get_regex('[ ()/,\.\'\?:]',line.encoding,16) # //u = 00010000 option bit set = 16
          key = (parts[0][1..-1].downcase.gsub regex, '_'.encode('UTF-16LE')).encode('UTF-8')
          # replace %@ to %s
          key = key.gsub '%@', '%s'
          value = value.gsub '%@', '%s'
          
          result[key] = value
          token += 1
        else
          skip += 1
        end
        counter = counter + 1
      end
    end
    puts "#{counter} lines. #{token} tokens.  skipped #{skip} lines"
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
  puts "Writing to #{full_output}"
  # puts result

  puts output_xml result
  i = i + 1  
end

puts "Languages:#{i}"