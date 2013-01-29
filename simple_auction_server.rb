require 'webrick'
require 'uri'
require 'net/http'

$own_address = 8080

class AuctionInfo
	# The representation is a hash mapping item names to [highest_bidder, highest_bid, end_time]
	def initialize
		@data = {}
	end
	def new_item(item, endTime)
		@data[item] = ["UNKNOWN", 0, endTime]
	end
	def bid(item, bid, client)
		if @data.has_key?(item)
			endTime = @data[item][2]
			if @data[item][1].to_i < bid.to_i and Time.new.to_i < endTime.to_i
				@data[item] = [client, bid, endTime]
			end
		end
	end
	def get_status(item)
		if @data.has_key?(item)
			return @data[item][0]
		end
	end
	def winner(item)
		if @data.has_key?(item)
			if @data[item][2].to_i + 1 <= Time.new.to_i
				return @data[item][0]
			else return "UNKNOWN"
			end
		end
	end
	def reset
		@data = {}
	end
	def has_item(item)
		return @data.has_key?(item)
	end
	def get_data
		return {}.replace(@data) 
	end
end

class StartAuctionServlet < WEBrick::HTTPServlet::AbstractServlet
	
	def initialize(server, data)
		@data = data
	end

	def do_POST(request, response)
		if request.query['name'] and request.query['end_time']
			@data.new_item(request.query['name'], request.query['end_time'].to_i)
		end
		response.status = 200
	end
	alias_method :do_GET, :do_POST
end

class BidServlet < WEBrick::HTTPServlet::AbstractServlet

	def initialize(server, data)
		@data = data
	end

	def do_POST(request, response)
		if request.query['name'] and request.query['client'] and request.query['bid']
			@data.bid(request.query['name'], request.query['bid'].to_i, request.query['client'])
      	end
      	response.status = 200
	end
	alias_method :do_GET, :do_POST
end

class StatusServlet < WEBrick::HTTPServlet::AbstractServlet
	
	def initialize(server, data)
		@data = data
	end

	def do_GET(request, response)

		if request.query['name']
			response.body = @data.get_status(request.query['name'])
		end
		response.status = 200
	end
	alias_method :do_POST, :do_GET
end

class WinnerServlet < WEBrick::HTTPServlet::AbstractServlet
	
	def initialize(server, data)
		@data = data
	end

	def do_GET(request, response)
		if request.query['name']
			response.body = @data.winner(request.query['name'])
		end
		response.status = 200
	end
	alias_method :do_POST, :do_GET
end

class ResetServlet < WEBrick::HTTPServlet::AbstractServlet
	
	def initialize(server, data)
		@data = data
	end
	def do_POST(request, response)
		@data.reset
		response.status = 200
	end
	alias_method :do_GET, :do_POST
end

class RandomServlet < WEBrick::HTTPServlet::AbstractServlet
	def initialize(server, data)
		@data = data
	end
	def do_GET(request, response)
		response.status = 200
		response.body = @data.get_data.to_s
	end
	alias_method :do_POST, :do_GET
end




data = AuctionInfo.new
server = WEBrick::HTTPServer.new(:Port => $own_address)
server.mount '/start_auction', StartAuctionServlet, data
server.mount '/bid', BidServlet, data
server.mount '/status', StatusServlet, data
server.mount '/winner', WinnerServlet, data
server.mount '/rst', ResetServlet, data
server.mount '/', RandomServlet, data
trap("INT") { server.shutdown }
server.start