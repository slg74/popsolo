class Scale
  TABLE = ENV.fetch("DYNAMODB_TABLE", "popsolo_scales")

  SCALE_TYPES = {
    "minor_pentatonic" => "Minor Pentatonic",
    "major_pentatonic" => "Major Pentatonic",
    "blues"            => "Blues Scale",
    "natural_minor"    => "Natural Minor (Aeolian)",
    "dorian"           => "Dorian Mode"
  }.freeze

  DISPLAY_ORDER = %w[minor_pentatonic major_pentatonic blues natural_minor dorian].freeze

  attr_reader :key_name, :scale_type, :notes, :svg_data

  def initialize(attrs)
    @key_name   = attrs["key_name"]
    @scale_type = attrs["scale_type"]
    @notes      = attrs["notes"]
    @svg_data   = attrs["svg_data"]
  end

  def display_name
    SCALE_TYPES[@scale_type] || @scale_type.humanize
  end

  def self.for_key(key_name)
    DISPLAY_ORDER.filter_map do |scale_type|
      resp = AWS_DYNAMODB.get_item(
        table_name: TABLE,
        key: { "key_name" => key_name, "scale_type" => scale_type }
      )
      new(resp.item) if resp.item
    end
  end
end
