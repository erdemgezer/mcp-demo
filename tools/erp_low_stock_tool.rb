class ErpLowStockTool < MCP::Tool
  description "A tool for searching the ERP for low stock items. Default threshold is 10."
  input_schema(
    properties: {
      threshold: {
        type: "number",
        description: "The threshold for low stock items. Default is 10."
      },
      warehouse: {
        type: "string",
        description: "The warehouse to search for low stock items. Default is all warehouses."
      },
    },
  )

  def self.call(threshold: 10, warehouse: nil)
    all = [
      { sku: "SKU-001", warehouse: "WH1", available: 3 },
      { sku: "SKU-002", warehouse: "WH1", available: 12 },
      { sku: "SKU-007", warehouse: "WH2", available: 0 },
      { sku: "SKU-009", warehouse: "WH2", available: 7 }
    ]


    filtered = all.select { |r| r[:available] < threshold }
    filtered = filtered.select { |r| r[:warehouse] == warehouse } if warehouse && !warehouse.empty?
    filtered_skus = filtered.map { |r| r[:sku] }.join(", ")

    MCP::Tool::Response.new([{
      type: "text",
      text: "The low stock items in #{warehouse || "all warehouses"} are #{filtered_skus}",
    }])
  end
end
