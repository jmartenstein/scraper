
# test_scraper.rb

require './src/scraper'
require 'test/unit'

class ScraperTest < Test::Unit::TestCase

def setup
   @scraper1 = Scraper.new()
end

def teardown
end

# test that the class initialized properly, make sure a blank
# scraper hash is created
def test_initialize1()
   hash = @scraper1.parser_config
   assert(hash.empty?)
end

# if no parameters specified, then automatically load the scraper.yml file
def test_load1()
   @scraper1.load()
   hash = @scraper1.parser_config()
   assert_equal("Skillet", hash.first.first)
end

# we can also specify a file at load time
def test_load2()
   @scraper1.load("./test/test.yml")
   hash = @scraper1.parser_config()
   assert_equal("foo", hash.first.first)
end

# or we can load from a config hash
def test_load3()
end

def test_build_lists1()

   source = "<foo><time>Monday, 11am - 2pm</time>" + 
                 "<location>Wallingford</location>" +
                 "<time>Tuesday, 11am - 2pm</time>" +
                 "<location>South Lake Union</location></food>"
   sub_nodes = [ 
      { 
         "node" => {
            "xpath" => '//time/text()',
            "regex" => '^(\w+),\s.*$'
         }
      }, {
         "node" => {
            "xpath" => "//location/text()"
         }
      }
   ]
   expected_lists = [["Monday", "Wallingford"], 
                     ["Tuesday", "South Lake Union" ]]

   result_lists = @scraper1.build_lists(sub_nodes, source)

   i = 0
   expected_lists.each do | list |
      j = 0
      list.each do | item |
         assert_equal(item, result_lists[i][j])
         j = j+1
      end
      i = i+1
   end
   

end

# try a test parse
def test_parse_nodes1()

   source_string = "<foo><bar>Monday - Wallingford</bar></foo>"
   node = {
      "xpath" => "//bar/text()",
      "regex" => '^(\w+)\s-\s\w+$'
   }
   expected_string = "Monday"

   result_list = @scraper1.parse_nodes(node, source_string)
   assert_equal(expected_string, result_list.first)

end

def test_parse_nodes2()

   source_string = "<foo><bar>Monday - Wallingford</bar>" +
                   "<bar>Tuesday - South Lake Union</bar></foo>"
   node = {
      "xpath" => "//bar/text()",
      "regex" => '^\w+\s-\s([\w\s]+)'
   }
   expected_list = [ "Wallingford", "South Lake Union" ]

   result_list = @scraper1.parse_nodes(node, source_string)

   i = 0
   expected_list.each do | expected |
      assert_equal(expected, result_list[i])
      i = i+1
   end

end

def test_extract_via_xpath1()

   xml_string = "<foo><bar>test</bar></foo>"
   xpath_string = "//bar/text()"

   expected_string = "test"
   result_list = @scraper1.extract_via_xpath(xml_string, xpath_string)

   assert_equal(expected_string, result_list.first)

end

def test_extract_via_regex1()

   source_string = "Wallingford, Monday, 11am - 2pm"
   regex_string = '^\w+,\s(\w+),.*'

   expected_result = "Monday"
   actual_result = @scraper1.extract_via_regex(source_string, regex_string)

   assert_equal(expected_result, actual_result)

end

end  # class ScraperTest
