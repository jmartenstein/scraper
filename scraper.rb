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

site_parser = {
   'Skillet' => {
      'parse' => 'html',
      'url' => 'http://www.skilletstreetfood.com',
      'sub_nodes' => [
         { 'xpath' => "//div[@class='weekly_feed']//div[@class='date']" },
         { 'xpath' => "//div[@class='weekly_feed']//p[@class='description_address']" },
         { 'xpath' => "//div[@class='weekly_feed']//p[@class='description_content']" }
      ]
   },
   "Marination" => {
      'parse'     => 'html',
      'url'       => 'http://marinationmobile.com/locations',
      'sub_nodes' => [
         { 'xpath' => '//h3' }
      ]
   },
   "Here There Grill" => {
      'parse'     => 'html',
      'url'       => 'http://hereandtheregrill.com/our-locations',
      'sub_nodes' => [
      ]
   },
   'Parfait' => {
      'parse'        => 'gcal',
      'url'          => 'https://www.google.com/calendar/feeds/parfait.icecream@gmail.com/public/basic',
      'sub_nodes'    => [
      ]
   },
   'Pai Foods' => {
      'parse'        => 'gcal',
      'url'          => 'https://www.google.com/calendar/feeds/pai@paifoods.com/public/basic',
      'sub_nodes'    => [
      ]
   }
}


# TODO: 
#  1) Modify function to parse "sub-nodes"
#  2) x Save data to yaml
#  3) Migrate to truck class 	


def parseGCal(hash, name)

   # load the yaml file with auth info
   account_yml = YAML.load(File.read('../scraper/account.yml'))

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
   list_list         = []
   last_key_count    = 0
   i                 = 0

   # extract each of the sub nodes
   sub_nodes.each do | path_list |

      # if we actually want the second layer "node" to operate on a subset
      # of the document, then we will probably need to change the iterator
      # to some sort of recursive function
      @node = @doc

      path_list.keys.each do | key |

         path = path_list[key]

         # initialize a list to store each of the (string) values
         value_list = []

         if key == 'xpath'
            # do an xpath search for each of our nodes
            @node.root.xpath(path).each do | element |
               value_list.push(element.text)
            end
         end

         # now store the list back into a (new) hash
         list_list.push(value_list)

         # check to see if the current list is larger than the last one
         # we checked; if it, throw a warning
         if i > 0
            if last_key_count > value_list.count
               $stderr.puts "WARNING: node count mismatch"
i Foods
               $stderr.puts "current  count: value_list.count"
               $stderr.puts "previous count: #{last_key_count}"
            end
         end

         # increment our counts
         last_key_count = value_list.count
         i = i + 1

      end

   end

   # print out the parsed results
   (0 ... last_key_count).each do | i |
      csv_list = [name]
      list_list.each do | list |
         csv_list.push(list[i])
      end
      puts csv_list.join(",")
   end

end  # parse

# open the scraper config file, load to a hash
file = './scraper.yml'
site_parser = YAML::load_file(file)

#calendar_url = "https://www.google.com/calendar/feeds/pai@paifoods.com/public/basic?start-min=#{starttime}&start-max=#{endtime}"
name = "Parfait"
parseGCal(site_parser[name], name)

# parse the Skillet website
name = "Skillet"
parseHTML(site_parser[name], name)

# parse the Here and There Grill website
name = 'Here There Grill'
#parse(site_parser[name], name)

# parse the Marination Mobile website
name = "Marination"
#parseHTML(site_parser[name], name)

