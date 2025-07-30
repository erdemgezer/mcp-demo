class CurrencyTool < MCP::Tool
  description "A tool for converting currencies"
  input_schema(
    properties: {
      amount: { type: "number" },
      from: { type: "string" },
      to: { type: "string" },
    },
  )

  def self.call(amount:, from:, to:)
    MCP::Tool::Response.new([{
      type: "text",
      text: "The conversion of #{amount} #{from} to #{to} is #{amount * 2}",
    }])
  end
end


