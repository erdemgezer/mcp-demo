class ErpOrderTool < MCP::Tool
  description "A tool for creating and searching orders in the ERP"
  input_schema(
    properties: {
      action: {
        type: "string",
        enum: [ "list", "create", "search"],
        description: "The action to perform on the order"
      },
      order_id: { type: "string", description: "The ID of the order to search for" },
      order_data: { type: "object", description: "The data of the order to create" }
    }
  )

  def self.call(action:, order_id: nil, order_data: nil)
    case action
    when "list"
      list_orders
    when "create"
      create_order(order_data)
    when "search"
      search_order(order_id)
    else
      MCP::Tool::Response.new([{
        type: "text",
        text: "Invalid action. Use 'create' or 'search'."
      }])
    end
  end

  private

  def self.list_orders
    MCP::Tool::Response.new([{
      type: "text",
      text: "Orders: #{SAMPLE_ORDERS.map { |o| o[:order_id] }.join(", ")}"
    }])
  end

  def self.create_order(order_data)
    return MCP::Tool::Response.new([{
      type: "text",
      text: "Error: Order data is required for creating an order."
    }]) unless order_data

    # Generate new order ID
    new_order_id = "ORD-#{Time.now.to_i}"

    # Create order with provided data
    new_order = {
      order_id: new_order_id,
      customer_id: order_data["customer_id"] || "CUST-#{sprintf('%03d', rand(100..999))}",
      customer_name: order_data["customer_name"] || "New Customer",
      order_date: Date.today.strftime("%Y-%m-%d"),
      status: "pending",
      total_amount: order_data["total_amount"] || 0.0,
      currency: order_data["currency"] || "USD",
      items: order_data["items"] || [],
      shipping_address: order_data["shipping_address"] || {},
      tracking_number: nil
    }

    MCP::Tool::Response.new([{
      type: "text",
      text: "Order created successfully: #{new_order_id}\n\n#{format_order(new_order)}"
    }])
  end

  def self.search_order(order_id)
    return MCP::Tool::Response.new([{
      type: "text",
      text: "Error: Order ID is required for searching."
    }]) unless order_id

    order = SAMPLE_ORDERS.find { |o| o[:order_id] == order_id }

    if order
      MCP::Tool::Response.new([{
        type: "text",
        text: "Order found:\n\n#{format_order(order)}"
      }])
    else
      MCP::Tool::Response.new([{
        type: "text",
        text: "Order not found: #{order_id}"
      }])
    end
  end

  def self.format_order(order)
    items_text = order[:items].map do |item|
      "  - #{item[:product_name]} (#{item[:sku]}): #{item[:quantity]} x $#{item[:unit_price]}"
    end.join("\n")

    address = order[:shipping_address]
    address_text = "#{address[:street]}, #{address[:city]}, #{address[:state]} #{address[:zip]}, #{address[:country]}"

    <<~TEXT
      Order ID: #{order[:order_id]}
      Customer: #{order[:customer_name]} (#{order[:customer_id]})
      Date: #{order[:order_date]}
      Status: #{order[:status]}
      Total: $#{order[:total_amount]} #{order[:currency]}

      Items:
      #{items_text}

      Shipping Address:
      #{address_text}

      Tracking: #{order[:tracking_number] || 'Not assigned'}
    TEXT
  end

  SAMPLE_ORDERS = [
    {
      order_id: "ORD-001",
      customer_id: "CUST-001",
      customer_name: "Acme Corporation",
      order_date: "2024-01-15",
      status: "fulfilled",
      total_amount: 1299.99,
      currency: "USD",
      items: [
        { sku: "SKU-001", product_name: "Wireless Headphones", quantity: 2, unit_price: 199.99 },
        { sku: "SKU-002", product_name: "USB-C Cable", quantity: 5, unit_price: 19.99 }
      ],
      shipping_address: {
        street: "123 Business Ave",
        city: "San Francisco",
        state: "CA",
        zip: "94105",
        country: "USA"
      },
      tracking_number: "TRK-001-XYZ"
    },
    {
      order_id: "ORD-002",
      customer_id: "CUST-002",
      customer_name: "TechStart Inc.",
      order_date: "2024-01-16",
      status: "processing",
      total_amount: 2499.95,
      currency: "USD",
      items: [
        { sku: "SKU-007", product_name: "Laptop Computer", quantity: 1, unit_price: 1299.99 },
        { sku: "SKU-009", product_name: "External Monitor", quantity: 2, unit_price: 599.98 }
      ],
      shipping_address: {
        street: "456 Startup Blvd",
        city: "Austin",
        state: "TX",
        zip: "73301",
        country: "USA"
      },
      tracking_number: nil
    },
    {
      order_id: "ORD-003",
      customer_id: "CUST-003",
      customer_name: "Global Solutions Ltd",
      order_date: "2024-01-17",
      status: "pending",
      total_amount: 899.97,
      currency: "USD",
      items: [
        { sku: "SKU-001", product_name: "Wireless Headphones", quantity: 1, unit_price: 199.99 },
        { sku: "SKU-002", product_name: "USB-C Cable", quantity: 10, unit_price: 19.99 },
        { sku: "SKU-011", product_name: "Tablet Case", quantity: 3, unit_price: 49.99 }
      ],
      shipping_address: {
        street: "789 Enterprise Way",
        city: "Seattle",
        state: "WA",
        zip: "98101",
        country: "USA"
      },
      tracking_number: nil
    }
  ].freeze
end
