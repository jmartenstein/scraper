# scraper.rb
# Justin Martenstenstein, April 2011

# scrapes food truck websites and reports back relevant scheduling info

require 'rubygems'

require 'timeout'
require 'open-uri'
require 'nokogiri'
require 'gdata'
require 'yaml'

# add another layer (or infinite layers), so that we can search via
# xpath, and then apply that result to a regex

# the additional layer will need to be a hash, so that we can designate
# what is an xpath and what is a regex


# TODO: 
#  1) Modify function to parse "sub-nodes"
#  2) x Save data to yaml
#  3) Migrate to truck class 	


class Scraper

attr_accessor :parser_config

### FUNCTIONS ###

def parseGCal(hash, name)

   # load the yaml file with auth info
   account_yml = YAML.load(File.read('./config/account.yml'))

   # initialize the client object, then send the login information
   client = GData::Client::Calendar.new()
   client.clientlogin(account_yml['username'], account_yml['password'])

   daterange = "start-min=2011-06-12T00:00:00&start-max=2011-06-15T23:59:59"

   # submit for the feed
   feed = client.get(hash['url'] + "?" + daterange).to_xml

   #puts feed.class

   # just print info on the first entry for now
   first = feed.elements['entry']

   puts "Title: " + first.elements['title'].text
   puts 
   puts "Summary:"
   puts first.elements['summary'].text

   #
   #feed.elements.each('entry') do |entry|
   #   puts entry.elements['title'].text
   #   puts entry.elements['summary'].text
   #   puts
   #end

   #puts feed.elements.first

end

def parseHTML(hash, name)

   # grab the url for what the site's url, but timeout if the script
   # waits too long
   begin
      @doc = Nokogiri::HTML(open(hash['url'], :read_timeout => 5))
   rescue Timeout::Error
      abort "timeout!"
   end

   # check to make sure there are sub nodes
   sub_nodes = hash['sub_nodes']
   if sub_nodes.nil?
      abort "no sub nodes found!"
   end

   # initialize the hash to store all the values / strings retrieved
   # from the html document, and a few other housekeeping elements
   list_list    = []
   key_count    = 0

   # extract each of the sub nodes
   sub_nodes.each do | path_list |

      last_key_count = 0
      i = 0

      # if we actually want the second layer "node" to operate on a subset
      # of the document, then we will probably need to change the iterator
      # to some sort of recursive function
      @node = @doc

      #puts path_list.first.inspect

      path_list.keys.each do | key |

         path = path_list[key]

         # initialize a list to store each of the (string) values
         value_list = []

         if key == 'xpath'
            # do an xpath search for each of our nodes
         elsif key == 'regex'
            value_list.push('regex')
         end

         # now store the list into a (new) hash
         list_list.push(value_list)

         # check to see if the current list is larger than the last one
         # we checked; if it is, throw a warning
         if i > 0
            if last_key_count != value_list.count
               $stderr.puts "WARNING: node count mismatch"
               $stderr.puts "previous count : #{last_key_count}"
               $stderr.puts "current count  : #{value_list.count}"
               $stderr.puts "one of your parse paths is probably wrong"
            end
         end

         # increment our counts
         last_key_count = value_list.count
         i = i + 1

         #puts i
         #puts last_key_count

      end

      key_count = last_key_count
   end

   # print out the parsed results
   (0 ... key_count).each do | i |
      csv_list = [name]
      list_list.each do | list |
         csv_list.push(list[i])
      end
      puts csv_list.join(",")
   end

end  # parse


def extract_via_xpath(xml_string, xpath_string)
   
   found_list = []

   source_xml = Nokogiri::XML(xml_string)

   source_xml.root.xpath(xpath_string).each do | element |
      found_list.push(element.text)
   end

   return found_list

end  # def extract_via_xpath

def extract_via_regex(source_string, regex_string)

   rxp = Regexp::new(regex_string)
   return source_string.gsub(rxp, '\1')

end  # def extract_via_regex

def parse_nodes(node_list, string)

   temp_list = []
   parsed_list = []

   node_list.keys.each do | key |

      if (key == "xpath") then
         parsed_list = extract_via_xpath(string, node_list[key])
      end

      if (key == "regex") then

         # if the list is empty, there probably wasn't an xpath,
         if (parsed_list.empty?) 
            parsed_list.push(string)
         end

         # go through the parsed list (either the list returned from 
         # xpath, or the string, and run the regex against each
         parsed_list.each do | item | 
            temp_list.push(extract_via_regex(item, node_list[key]))
         end

         # now assign the temp_list back to the parsed_list
         parsed_list = temp_list

      end

   end

   return parsed_list

end  # def parse_nodes

def build_lists(sub_nodes, string)

   sub_nodes_list = []
   return_list = []

   # first build a list of lists based on what comes back from
   # the parse_nodes function
   sub_nodes.each do | node |
      sub_nodes_list.push(parse_nodes(node["node"],string))
   end

   key_count = sub_nodes_list[0].count

   # now we want to pivot the list of lists
   (0 ... key_count).each do | j |
      temp_list = []
      sub_nodes_list.each do | list |
         temp_list.push(list[j])
      end
      return_list.push(temp_list)
   end

   return return_list

end  # def build_lists

def load(filename="./config/scraper.yml")
   @parser_config = YAML::load_file(filename)
end

def load_from_config()
end

def initialize()

   @parser_config = {}

end # def initialize

end  # class Scraper
