require "mcp"
require "mcp/server/transports/streamable_http_transport"
require "rack"
require "rackup"
require "json"
require "logger"
require_relative "tools/currency_tool"
require_relative "tools/weather_tool"

server = MCP::Server.new(
  name: "my_mcp_server",
  tools: [CurrencyTool, WeatherTool],
  resources: [],
  prompts: [],
)

# Create the Streamable HTTP transport
transport = MCP::Server::Transports::StreamableHTTPTransport.new(server)
server.transport = transport

# Create a logger for MCP-specific logging
mcp_logger = Logger.new($stdout)
mcp_logger.formatter = proc do |_severity, _datetime, _progname, msg|
  "[MCP] #{msg}\n"
end

# Create a Rack application with logging
app = proc do |env|
  request = Rack::Request.new(env)

  # Log MCP-specific details for POST requests
  if request.post?
    body = request.body.read
    request.body.rewind
    begin
      parsed_body = JSON.parse(body)
      mcp_logger.info("Request: #{parsed_body["method"]} (id: #{parsed_body["id"]})")
      mcp_logger.debug("Request body: #{JSON.pretty_generate(parsed_body)}")
    rescue JSON::ParserError
      mcp_logger.warn("Request body (raw): #{body}")
    end
  end

  # Handle the request
  response = transport.handle_request(request)

  # Log the MCP response details
  _, _, body = response
  if body.is_a?(Array) && !body.empty? && body.first
    begin
      parsed_response = JSON.parse(body.first)
      if parsed_response["error"]
        mcp_logger.error("Response error: #{parsed_response["error"]["message"]}")
      else
        mcp_logger.info("Response: #{parsed_response["result"] ? "success" : "empty"} (id: #{parsed_response["id"]})")
      end
      mcp_logger.debug("Response body: #{JSON.pretty_generate(parsed_response)}")
    rescue JSON::ParserError
      mcp_logger.warn("Response body (raw): #{body}")
    end
  end

  response
end

# Wrap the app with Rack middleware
rack_app = Rack::Builder.new do
  # Use CommonLogger for standard HTTP request logging
  use(Rack::CommonLogger, Logger.new($stdout))

  # Add other useful middleware
  use(Rack::ShowExceptions)

  run(app)
end

# Start the server
puts "Starting MCP HTTP server on http://localhost:9292"
puts "Use POST requests to initialize and send JSON-RPC commands"
puts "Example initialization:"
puts '  curl -i http://localhost:9292 --json \'{"jsonrpc":"2.0","method":"initialize","id":1,"params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}\''
puts ""
puts "The server will return a session ID in the Mcp-Session-Id header."
puts "Use this session ID for subsequent requests."
puts ""
puts "Press Ctrl+C to stop the server"

# Run the server
# Use Rackup to run the server
Rackup::Handler.get("puma").run(rack_app, Port: 9292, Host: "localhost")
