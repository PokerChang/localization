<h1>Merge an Android strings.xml into Ruby on Rails i18n yml file</h1>
<h1>Usage</h1>
ruby convert.rb android_strings_xml_path rails_yml_path
<h1>Description</h1>
This simple ruby script will merge Android strings file into Ruby on Rails i18n yml file.  The result is sorted alphabetically.  It's safe to rerun.  Current only English is tested but it can be easily convert to other languages.

<h1>TODO</h1>
<ol>
<li>Merge both ways</li>
<li>Automatically enumerate all possible android locales and create according to locales for Rails</li>
</ol>