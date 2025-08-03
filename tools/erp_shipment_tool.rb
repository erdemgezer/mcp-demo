class ErpShipmentTool < MCP::Tool
  description "A tool for managing shipments and tracking deliveries"
  input_schema(
    properties: {
      action: {
        type: "string",
        enum: ["create", "search", "update_status", "track", "list"],
        description: "The action to perform on shipments"
      },
      shipment_id: { type: "string", description: "The ID of the shipment" },
      order_id: { type: "string", description: "The order ID to create shipment for" },
      tracking_number: { type: "string", description: "Tracking number for the shipment" },
      status: { type: "string", description: "New status for shipment update" }
    }
  )

  # Sample shipments data
  SAMPLE_SHIPMENTS = [
    {
      shipment_id: "SHIP-001",
      order_id: "ORD-001",
      tracking_number: "TRK-001-XYZ",
      carrier: "FastShip Express",
      status: "delivered",
      created_date: "2024-01-15",
      shipped_date: "2024-01-16",
      delivered_date: "2024-01-18",
      destination: {
        street: "123 Business Ave",
        city: "San Francisco",
        state: "CA",
        zip: "94105",
        country: "USA"
      },
      tracking_events: [
        { date: "2024-01-15", status: "created", location: "Warehouse WH1", description: "Shipment created" },
        { date: "2024-01-16", status: "picked_up", location: "Warehouse WH1", description: "Package picked up by carrier" },
        { date: "2024-01-17", status: "in_transit", location: "Oakland, CA", description: "Package in transit" },
        { date: "2024-01-18", status: "delivered", location: "San Francisco, CA", description: "Package delivered to recipient" }
      ]
    },
    {
      shipment_id: "SHIP-002",
      order_id: "ORD-002",
      tracking_number: "TRK-002-ABC",
      carrier: "QuickDeliver",
      status: "in_transit",
      created_date: "2024-01-17",
      shipped_date: "2024-01-18",
      delivered_date: nil,
      destination: {
        street: "456 Startup Blvd",
        city: "Austin",
        state: "TX",
        zip: "73301",
        country: "USA"
      },
      tracking_events: [
        { date: "2024-01-17", status: "created", location: "Warehouse WH2", description: "Shipment created" },
        { date: "2024-01-18", status: "picked_up", location: "Warehouse WH2", description: "Package picked up by carrier" },
        { date: "2024-01-19", status: "in_transit", location: "Dallas, TX", description: "Package in transit to destination" }
      ]
    },
    {
      shipment_id: "SHIP-003",
      order_id: "ORD-003",
      tracking_number: nil,
      carrier: nil,
      status: "pending",
      created_date: "2024-01-17",
      shipped_date: nil,
      delivered_date: nil,
      destination: {
        street: "789 Enterprise Way",
        city: "Seattle",
        state: "WA",
        zip: "98101",
        country: "USA"
      },
      tracking_events: [
        { date: "2024-01-17", status: "created", location: "Warehouse WH1", description: "Shipment created, awaiting carrier assignment" }
      ]
    }
  ].freeze

  def self.call(action:, shipment_id: nil, order_id: nil, tracking_number: nil, status: nil)
    case action
    when "list"
      list_shipments
    when "create"
      create_shipment(order_id)
    when "search"
      search_shipment(shipment_id, order_id)
    when "update_status"
      update_shipment_status(shipment_id, status)
    when "track"
      track_shipment(tracking_number, shipment_id)
    else
      MCP::Tool::Response.new([{
        type: "text",
        text: "Invalid action. Use 'create', 'search', 'update_status', or 'track'."
      }])
    end
  end

  private

  def self.list_shipments
    MCP::Tool::Response.new([{
      type: "text",
      text: "Shipments: #{SAMPLE_SHIPMENTS.map { |s| s[:shipment_id] }.join(", ")}"
    }])
  end

  def self.create_shipment(order_id)
    return MCP::Tool::Response.new([{
      type: "text",
      text: "Error: Order ID is required to create a shipment."
    }]) unless order_id

    # Check if shipment already exists for this order
    existing = SAMPLE_SHIPMENTS.find { |s| s[:order_id] == order_id }
    if existing
      return MCP::Tool::Response.new([{
        type: "text",
        text: "Shipment already exists for order #{order_id}: #{existing[:shipment_id]}"
      }])
    end

    # Generate new shipment
    new_shipment_id = "SHIP-#{sprintf('%03d', SAMPLE_SHIPMENTS.length + 1)}"

    MCP::Tool::Response.new([{
      type: "text",
      text: "Shipment created successfully: #{new_shipment_id}\n" +
           "Order ID: #{order_id}\n" +
           "Status: pending\n" +
           "Created: #{Date.today.strftime('%Y-%m-%d')}\n\n" +
           "Shipment is pending carrier assignment."
    }])
  end

  def self.search_shipment(shipment_id, order_id)
    if shipment_id
      shipment = SAMPLE_SHIPMENTS.find { |s| s[:shipment_id] == shipment_id }
    elsif order_id
      shipment = SAMPLE_SHIPMENTS.find { |s| s[:order_id] == order_id }
    else
      return MCP::Tool::Response.new([{
        type: "text",
        text: "Error: Either shipment ID or order ID is required for searching."
      }])
    end

    if shipment
      MCP::Tool::Response.new([{
        type: "text",
        text: "Shipment found:\n\n#{format_shipment(shipment)}"
      }])
    else
      search_term = shipment_id || order_id
      MCP::Tool::Response.new([{
        type: "text",
        text: "Shipment not found: #{search_term}"
      }])
    end
  end

  def self.update_shipment_status(shipment_id, new_status)
    return MCP::Tool::Response.new([{
      type: "text",
      text: "Error: Shipment ID and status are required."
    }]) unless shipment_id && new_status

    shipment = SAMPLE_SHIPMENTS.find { |s| s[:shipment_id] == shipment_id }

    unless shipment
      return MCP::Tool::Response.new([{
        type: "text",
        text: "Shipment not found: #{shipment_id}"
      }])
    end

    MCP::Tool::Response.new([{
      type: "text",
      text: "Shipment #{shipment_id} status updated from '#{shipment[:status]}' to '#{new_status}'\n" +
           "Timestamp: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
    }])
  end

  def self.track_shipment(tracking_number, shipment_id)
    if tracking_number
      shipment = SAMPLE_SHIPMENTS.find { |s| s[:tracking_number] == tracking_number }
    elsif shipment_id
      shipment = SAMPLE_SHIPMENTS.find { |s| s[:shipment_id] == shipment_id }
    else
      return MCP::Tool::Response.new([{
        type: "text",
        text: "Error: Either tracking number or shipment ID is required."
      }])
    end

    unless shipment
      search_term = tracking_number || shipment_id
      return MCP::Tool::Response.new([{
        type: "text",
        text: "No shipment found for: #{search_term}"
      }])
    end

    if shipment[:tracking_number].nil?
      return MCP::Tool::Response.new([{
        type: "text",
        text: "Tracking not available - shipment #{shipment[:shipment_id]} is still pending carrier assignment."
      }])
    end

    tracking_info = format_tracking(shipment)
    MCP::Tool::Response.new([{
      type: "text",
      text: "Tracking Information:\n\n#{tracking_info}"
    }])
  end

  def self.format_shipment(shipment)
    destination = shipment[:destination]
    dest_text = "#{destination[:street]}, #{destination[:city]}, #{destination[:state]} #{destination[:zip]}, #{destination[:country]}"

    <<~TEXT
      Shipment ID: #{shipment[:shipment_id]}
      Order ID: #{shipment[:order_id]}
      Status: #{shipment[:status]}
      Tracking Number: #{shipment[:tracking_number] || 'Not assigned'}
      Carrier: #{shipment[:carrier] || 'Not assigned'}

      Dates:
      Created: #{shipment[:created_date]}
      Shipped: #{shipment[:shipped_date] || 'Not shipped'}
      Delivered: #{shipment[:delivered_date] || 'Not delivered'}

      Destination:
      #{dest_text}
    TEXT
  end

  def self.format_tracking(shipment)
    events_text = shipment[:tracking_events].map do |event|
      "#{event[:date]} - #{event[:status].upcase} (#{event[:location]})\n  #{event[:description]}"
    end.join("\n\n")

    <<~TEXT
      Tracking Number: #{shipment[:tracking_number]}
      Carrier: #{shipment[:carrier]}
      Current Status: #{shipment[:status].upcase}

      Tracking Events:
      #{events_text}
    TEXT
  end
end
