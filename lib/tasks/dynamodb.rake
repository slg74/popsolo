module PopsoloTab
  CHROMATIC = %w[C C# D D# E F F# G G# A A# B].freeze
  NOTE_TO_SEMI = CHROMATIC.each_with_index.to_h.freeze

  # Tab display order: high e string first (top of tab)
  STRINGS = [
    { name: "e", open: 4  },
    { name: "B", open: 11 },
    { name: "G", open: 7  },
    { name: "D", open: 2  },
    { name: "A", open: 9  },
    { name: "E", open: 4  }
  ].freeze

  SCALE_DEFS = {
    "minor_pentatonic" => { title: "Minor Pentatonic",        intervals: [ 0, 3, 5, 7, 10 ]       },
    "major_pentatonic" => { title: "Major Pentatonic",        intervals: [ 0, 2, 4, 7, 9 ]        },
    "blues"            => { title: "Blues Scale",             intervals: [ 0, 3, 5, 6, 7, 10 ]   },
    "natural_minor"    => { title: "Natural Minor (Aeolian)", intervals: [ 0, 2, 3, 5, 7, 8, 10 ] },
    "dorian"           => { title: "Dorian Mode",             intervals: [ 0, 2, 3, 5, 7, 9, 10 ] }
  }.freeze

  ALL_KEYS = %w[C C# D D# E F F# G G# A A# B].freeze

  def self.notes_text(root, intervals)
    root_s = NOTE_TO_SEMI[root]
    intervals.map { |i| CHROMATIC[(root_s + i) % 12] }.join(" – ")
  end

  def self.generate_tab_svg(root, scale_type_key)
    defn      = SCALE_DEFS[scale_type_key]
    root_s    = NOTE_TO_SEMI[root]
    intervals = defn[:intervals]
    scale_set = intervals.map { |i| (root_s + i) % 12 }.to_set

    # Anchor box to where root falls on low E string (open = E = semitone 4)
    start_fret = (root_s - 4 + 12) % 12
    start_fret += 12 if start_fret < 2   # avoid open / fret-1 territory
    fret_span  = intervals.length <= 5 ? 4 : 5
    end_fret   = start_fret + fret_span
    fret_range = (start_fret..end_fret).to_a

    # Notes on each string within the box
    string_data = STRINGS.map do |str|
      hits = fret_range.filter_map do |fret|
        semi = (str[:open] + fret) % 12
        { fret: fret, root: (semi == root_s) } if scale_set.include?(semi)
      end
      { name: str[:name], hits: hits }
    end

    # Layout constants
    svg_w  = 560
    svg_h  = 230
    ml     = 52   # left margin
    mr     = 28
    mt     = 48   # top margin
    ss     = 23   # string spacing
    tab_w  = svg_w - ml - mr
    n      = fret_range.length

    fret_xs = fret_range.each_with_index.to_h do |fret, idx|
      [ fret, ml + (idx.to_f / (n - 1)) * tab_w ]
    end

    display_root = root.gsub("#", "♯")
    title_str    = "#{display_root}  #{defn[:title]}"
    notes_str    = notes_text(root, intervals)

    svg = +'<svg width="' + svg_w.to_s + '" height="' + svg_h.to_s +
          '" viewBox="0 0 ' + svg_w.to_s + " " + svg_h.to_s +
          "\" xmlns=\"http://www.w3.org/2000/svg\">\n"
    svg += '<rect width="' + svg_w.to_s + '" height="' + svg_h.to_s + '" fill="#0f0e1a" rx="10"/>' + "\n"

    svg += text_tag(svg_w / 2, 22, "middle", "#c4b5fd", 14, "bold", title_str)
    svg += text_tag(svg_w / 2, 38, "middle", "#4c4370", 10, "normal", notes_str)

    STRINGS.each_with_index do |str, i|
      y        = mt + i * ss
      stroke_w = (0.8 + (5 - i) * 0.22).round(2)

      svg += text_tag(ml - 22, y + 5, "middle", "#6e6590", 13, "normal", str[:name])
      svg += text_tag(ml - 8,  y + 5, "middle", "#352f5e", 13, "normal", "|")
      svg += '<line x1="' + ml.to_s + '" y1="' + y.to_s +
             '" x2="' + (ml + tab_w).to_s + '" y2="' + y.to_s +
             '" stroke="#2e2a52" stroke-width="' + stroke_w.to_s + '"/>' + "\n"
      svg += text_tag(ml + tab_w + 12, y + 5, "middle", "#352f5e", 13, "normal", "|")
    end

    string_data.each_with_index do |sdata, i|
      y = mt + i * ss
      sdata[:hits].each do |hit|
        x     = fret_xs[hit[:fret]]
        label = hit[:fret].to_s
        bw    = label.length > 1 ? 22 : 16

        svg += '<rect x="' + (x - bw / 2.0).round(1).to_s +
               '" y="' + (y - 8).to_s +
               '" width="' + bw.to_s + '" height="16" fill="#0f0e1a"/>' + "\n"

        color  = hit[:root] ? "#f87171" : "#60a5fa"
        weight = hit[:root] ? "bold"    : "normal"
        svg += text_tag(x.round(1), y + 5, "middle", color, 13, weight, label)
      end
    end

    bottom_y = mt + 5 * ss + 18
    fret_range.each do |fret|
      svg += text_tag(fret_xs[fret].round(1), bottom_y, "middle", "#3b3566", 10, "normal", fret.to_s)
    end
    svg += text_tag(ml - 22, bottom_y, "middle", "#2d2855", 9, "normal", "fr.")

    svg + "</svg>\n"
  end

  def self.text_tag(x, y, anchor, fill, size, weight, content)
    '<text x="' + x.to_s +
    '" y="' + y.to_s +
    '" text-anchor="' + anchor +
    '" fill="' + fill +
    '" font-family="\'JetBrains Mono\',monospace"' +
    ' font-size="' + size.to_s +
    '" font-weight="' + weight + '">' +
    content.to_s + "</text>\n"
  end
end

namespace :dynamodb do
  TABLE = ENV.fetch("DYNAMODB_TABLE", "popsolo_scales")

  desc "Create the popsolo_scales DynamoDB table (idempotent)"
  task create_table: :environment do
    if AWS_DYNAMODB.list_tables.table_names.include?(TABLE)
      puts "Table '#{TABLE}' already exists — skipping."
    else
      AWS_DYNAMODB.create_table(
        table_name:            TABLE,
        billing_mode:          "PAY_PER_REQUEST",
        attribute_definitions: [
          { attribute_name: "key_name",   attribute_type: "S" },
          { attribute_name: "scale_type", attribute_type: "S" }
        ],
        key_schema: [
          { attribute_name: "key_name",   key_type: "HASH"  },
          { attribute_name: "scale_type", key_type: "RANGE" }
        ]
      )
      AWS_DYNAMODB.wait_until(:table_exists, table_name: TABLE)
      puts "Created table '#{TABLE}'."
    end
  end

  desc "Seed popsolo_scales with guitar tab SVGs (12 keys × 5 scales = 60 records)"
  task seed: :environment do
    total = PopsoloTab::ALL_KEYS.length * PopsoloTab::SCALE_DEFS.length
    done  = 0

    PopsoloTab::ALL_KEYS.each do |key|
      PopsoloTab::SCALE_DEFS.each do |scale_type, defn|
        svg   = PopsoloTab.generate_tab_svg(key, scale_type)
        notes = PopsoloTab.notes_text(key, defn[:intervals])

        AWS_DYNAMODB.put_item(
          table_name: TABLE,
          item: {
            "key_name"   => key,
            "scale_type" => scale_type,
            "notes"      => notes,
            "svg_data"   => svg
          }
        )

        done += 1
        print "\r  #{done}/#{total}  #{key} #{defn[:title]}               "
        $stdout.flush
      end
    end
    puts "\nDone — #{total} records written to '#{TABLE}'."
  end

  desc "Create table and seed all scale data (idempotent)"
  task setup: %i[create_table seed]
end
