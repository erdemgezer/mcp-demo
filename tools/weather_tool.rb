class WeatherTool < MCP::Tool
  description "A tool for getting the weather"
  input_schema(
    properties: {
      city: { type: "string" },
    },
  )

  def self.call(city:)
    MCP::Tool::Response.new([{
      type: "text",
      text: "The weather in #{city} is sunny",
    }])
  end
end



