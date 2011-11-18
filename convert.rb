require 'rexml/document'
banner = 'Usage: ruby convert.rb android_strings_xml_path rails_yml_path'

if ARGV.count < 2
  puts banner
  exit
end
file   = File.open(ARGV[1], "r")

xml = File.read(ARGV[0])
doc= REXML::Document.new(xml)

# order alphabetically
result = []
doc.elements.each('/resources/string') do |p|
  result << ('  ' + p.attributes['name']+': "'+ p.text.gsub(/\n/,' ').squeeze(' ') + '"')
end
result = result



output = []
header = []
while (line = file.gets)
  if line.start_with? ' '
    output << line.chop
  else
    header << line.chop
  end
end

result = (output | result).sort{|a, b| a.downcase <=> b.downcase}

routput = File.open(ARGV[1], "w")
header.each do |r|
  routput.puts r
  #puts r
end

result.each do |r|
  routput.puts r
  #puts r
end