class KeysController < ApplicationController
  ALL_KEYS = %w[C C# D D# E F F# G G# A A# B].freeze

  # Circle of fifths display order (C at top, clockwise)
  FIFTHS_ORDER = %w[C G D A E B F# C# G# D# A# F].freeze

  def index
    @keys = FIFTHS_ORDER
  end

  def show
    @key_name = params[:key_name]
    unless ALL_KEYS.include?(@key_name)
      redirect_to root_path, alert: "Unknown key." and return
    end
    @scales = Scale.for_key(@key_name)
    @keys   = FIFTHS_ORDER
  end
end
