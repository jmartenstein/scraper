# scraper.rb
# Justin Martenstenstein, April 2011

# scrapes food truck websites and reports back relevant scheduling info

require 'timeout'
require 'open-uri'
require 'nokogiri'
require 'yaml'

# add another layer (or infinite layers), so that we can search via
# xpath, and then apply that result to a regex

# the additional layer will need to be a hash, so that we can designate
# what is an xpath and what is a regex

site_parser = {
	'Skillet' => {
		'url'				=> 'http://www.skilletstreetfood.com',
		'sub_nodes'		=> [
			{ 'xpath' => "//div[@class='weekly_feed']//div[@class='date']" },
			{ 'xpath' => "//div[@class='weekly_feed']//p[@class='description_address']" },
			{ 'xpath' => "//div[@class='weekly_feed']//p[@class='description_content']" }
		]
	},
	"Marination" => {
		'url'				=> 'http://marinationmobile.com/locations',
		'sub_nodes'		=> [
			{ 'xpath' => '//h3' }
		]
	},
	"Here There Grill" => {
		'url'				=> 'http://hereandtheregrill.com/our-locations',
		'sub_nodes'		=> [
		]
	}
}


# TODO: 
#  1) Modify function to parse "sub-nodes"
#	2) x Save data to yaml
#	3) Migrate to truck class 	

def parse(hash, name)

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
	list_list 			= []
	last_key_count 	= 0
	i 						= 0

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
					$stderr.puts "current  count: value_list.count"
					$stderr.puts "previous count: #{last_key_count}"
				end
			end

			# increment our counts
			last_key_count = value_list.count
			i = i + 1

		end

	end

	(0 ... last_key_count).each do | i |
		csv_list = [name]
		list_list.each do | list |
			csv_list.push(list[i])
		end
		puts csv_list.join(",")
	end

end  # parse

#file = './scraper.yml'
#site_parser = YAML::load_file(file)

#puts site_parser
#puts site_parser['Here There Grill']['url']

name = "Skillet"
parse(site_parser[name], name)
name = 'Here There Grill'
#parse(site_parser[name], name)
name = "Marination"
parse(site_parser[name], name)

#parse_marination()
#parse_whereyaat()
y = YAML::dump(site_parser)
puts y
