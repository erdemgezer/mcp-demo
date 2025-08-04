require "mcp"
require "mcp/server/transports/streamable_http_transport"
require "logger"
require_relative "tools/erp_low_stock_tool"
require_relative "tools/erp_order_tool"
require_relative "tools/erp_shipment_tool"
require_relative "rack_app"

server = MCP::Server.new(
  name: "ERP MCP Server",
  tools: [ErpLowStockTool, ErpOrderTool, ErpShipmentTool],
  resources: [],
  prompts: [],
)

# Create the Streamable HTTP transport
transport = MCP::Server::Transports::StreamableHTTPTransport.new(server)
server.transport = transport

# Build and start the Rack application
rack_app = MCPRackApp.build_rack_app(transport)
MCPRackApp.start_server(rack_app)
