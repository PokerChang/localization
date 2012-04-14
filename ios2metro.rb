# convert existing iOS locationzation to Metro resource file (*.resw)
invalid_keys=['break', 'default', 'import', 'new']

require 'rexml/document'
require 'builder'

# Utility function to make transcoding the regex simpler.
def get_regex(pattern, encoding='ASCII', options=0)
  Regexp.new(pattern.encode(encoding),options)
end


def output_xml (result, attri)
  #sort result
  result = result.sort
  
  #output XML
  xml = Builder::XmlMarkup.new( :indent => 2 )
  xml.instruct! :xml, :encoding => "UTF-8"
  xml.root do |r|
    r<<'<xsd:schema id="root" xmlns="" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:msdata="urn:schemas-microsoft-com:xml-msdata">
      <xsd:import namespace="http://www.w3.org/XML/1998/namespace" />
      <xsd:element name="root" msdata:IsDataSet="true">
        <xsd:complexType>
          <xsd:choice maxOccurs="unbounded">
            <xsd:element name="metadata">
              <xsd:complexType>
                <xsd:sequence>
                  <xsd:element name="value" type="xsd:string" minOccurs="0" />
                </xsd:sequence>
                <xsd:attribute name="name" use="required" type="xsd:string" />
                <xsd:attribute name="type" type="xsd:string" />
                <xsd:attribute name="mimetype" type="xsd:string" />
                <xsd:attribute ref="xml:space" />
              </xsd:complexType>
            </xsd:element>
            <xsd:element name="assembly">
              <xsd:complexType>
                <xsd:attribute name="alias" type="xsd:string" />
                <xsd:attribute name="name" type="xsd:string" />
              </xsd:complexType>
            </xsd:element>
            <xsd:element name="data">
              <xsd:complexType>
                <xsd:sequence>
                  <xsd:element name="value" type="xsd:string" minOccurs="0" msdata:Ordinal="1" />
                  <xsd:element name="comment" type="xsd:string" minOccurs="0" msdata:Ordinal="2" />
                </xsd:sequence>
                <xsd:attribute name="name" type="xsd:string" use="required" msdata:Ordinal="1" />
                <xsd:attribute name="type" type="xsd:string" msdata:Ordinal="3" />
                <xsd:attribute name="mimetype" type="xsd:string" msdata:Ordinal="4" />
                <xsd:attribute ref="xml:space" />
              </xsd:complexType>
            </xsd:element>
            <xsd:element name="resheader">
              <xsd:complexType>
                <xsd:sequence>
                  <xsd:element name="value" type="xsd:string" minOccurs="0" msdata:Ordinal="1" />
                </xsd:sequence>
                <xsd:attribute name="name" type="xsd:string" use="required" />
              </xsd:complexType>
            </xsd:element>
          </xsd:choice>
        </xsd:complexType>
      </xsd:element>
    </xsd:schema>
    <resheader name="resmimetype">
      <value>text/microsoft-resx</value>
    </resheader>
    <resheader name="version">
      <value>2.0</value>
    </resheader>
    <resheader name="reader">
      <value>System.Resources.ResXResourceReader, System.Windows.Forms, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089</value>
    </resheader>
    <resheader name="writer">
      <value>System.Resources.ResXResourceWriter, System.Windows.Forms, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089</value>
    </resheader>'
    result.each do |key, value|
      a = {'name'=>key, 'xml:space'=>'preserve'}   
      if !attri[key].nil?
        attri[key].each do |ak, av|
          a[ak] = av
        end
      end
      r.data (a) {|d| d.value value}
    end
  end
end



banner = 'Usage: ruby ios2metro.rb iOS_project_path metro_project_path_with_res.'

if ARGV.count < 2
  puts banner
  exit
end
mapping = Hash.new
mapping["zh_Hans.lproj"] = 'zh-cn'
mapping["zh_Hant.lproj"] = 'zh-tw'

i = 0
Dir["#{ARGV[0]}/**.lproj"].each do |language|  
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
        if parts[1] != separator
          # try remove the space from the separator
          separator = '"="'.encode('UTF-16LE')
          parts = line.partition separator
        end
        if parts[1] == separator
          value = (parts[2][0..parts[2].index('";'.encode('UTF-16LE'))-1]).encode('UTF-8')
          # replace special chars to underscore _ in key
          regex = get_regex('[ ()/,\.\'\?:!\-&><]',line.encoding,16) # //u = 00010000 option bit set = 16
          key = (parts[0][1..-1].downcase.gsub regex, '_'.encode('UTF-16LE')).encode('UTF-8')
          
          # Append .Content to every key
          key = key + '.Content'
          
          # replace %@ to %s
          key = key.gsub '%@', '%s'
          value = (value.gsub '%@', '%s').gsub "'", "\\'"

          if invalid_keys.include? key
            skip += 1
          else
            result[key] = value
            token += 1
          end
        else
          skip += 1
        end
        counter = counter + 1
      end
    end
    puts "#{counter} lines. #{token} tokens.  skipped #{skip} lines"
    filenum += 1
  end
  #puts "String files:#{filenum}"  
  output = mapping[short_name]
  if output.nil?
    # use default
    code = short_name[0..short_name.index('.')-1]    
    output = "#{code}"
    puts "Using default #{output} mapping for #{short_name}."
  end
  dir = "#{ARGV[1]}/#{output}"
  
  begin
    Dir::mkdir(dir)
  rescue
    
  end
  full_output = "#{dir}/Resources.resw"
  
  attributes = {}
  
  # TODO: 2. read the English original

  
  # TODO: 3. read the localization
  
  #write to output  
  puts "Writing to #{full_output}"
  # puts result

  xml = output_xml result, attributes
  open(full_output, "w") do|f|
    f.write(xml)
  end
  i = i + 1  
end

puts "Converted #{i} languages."