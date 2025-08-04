require "rack"
require "rackup"
require "json"
require "logger"

class MCPRackApp
  def initialize(transport, logger)
    @transport = transport
    @logger = logger
  end

  def call(env)
    request = Rack::Request.new(env)

    # Log MCP-specific details for POST requests
    if request.post?
      body = request.body.read
      request.body.rewind
      begin
        parsed_body = JSON.parse(body)
        @logger.info("Request: #{parsed_body["method"]} (id: #{parsed_body["id"]})")
        @logger.debug("Request body: #{JSON.pretty_generate(parsed_body)}")
      rescue JSON::ParserError
        @logger.warn("Request body (raw): #{body}")
      end
    end

    # Handle the request
    response = @transport.handle_request(request)

    # Log the MCP response details
    _, _, body = response
    if body.is_a?(Array) && !body.empty? && body.first
      begin
        parsed_response = JSON.parse(body.first)
        if parsed_response["error"]
          @logger.error("Response error: #{parsed_response["error"]["message"]}")
        else
          @logger.info("Response: #{parsed_response["result"] ? "success" : "empty"} (id: #{parsed_response["id"]})")
        end
        @logger.debug("Response body: #{JSON.pretty_generate(parsed_response)}")
      rescue JSON::ParserError
        @logger.warn("Response body (raw): #{body}")
      end
    end

    response
  end

  def self.build_rack_app(transport)
    # Create a logger for MCP-specific logging
    logger = Logger.new($stdout)
    logger.formatter = proc do |_severity, _datetime, _progname, msg|
      "[MCP] #{msg}\n"
    end

    app = new(transport, logger)

    Rack::Builder.new do
      # Use CommonLogger for standard HTTP request logging
      use(Rack::CommonLogger, Logger.new($stdout))

      # Add other useful middleware
      use(Rack::ShowExceptions)

      run(app)
    end
  end

  def self.start_server(rack_app, port: 9292, host: "localhost")
    puts "Starting MCP HTTP server on http://#{host}:#{port}"
    puts "Use POST requests to initialize and send JSON-RPC commands"
    puts "Example initialization:"
    puts '  curl -i http://localhost:9292 --json \'{"jsonrpc":"2.0","method":"initialize","id":1,"params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}\''
    puts ""
    puts "The server will return a session ID in the Mcp-Session-Id header."
    puts "Use this session ID for subsequent requests."
    puts ""
    puts "Press Ctrl+C to stop the server"

    # Run the server
    Rackup::Handler.get("puma").run(rack_app, Port: port, Host: host)
  end
end
