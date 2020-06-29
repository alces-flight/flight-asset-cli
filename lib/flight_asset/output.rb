module FlightAsset
  class BaseOutput
    def initialize(el, **opts)
      @element = el
      @opts = Hashie::Mash.new(**opts.dup)
    end

    def output
      mode = @element.is_a?(Array) ? :multi : :singular
      variety = $stdout.tty? ? :tty : :tsv
      send(:"#{mode}_#{variety}", @element)
    end

    private

    def singular_tty(element)
      # Converts procs to prettified data
      data = tty_procs.map do |key, proc|
        header = Paint[key + ':', '#2794d8']
        value = Paint[proc.call(element), :green]
        [header, value]
      end

      # Determines the maximum width header for padding
      max = data.max { |h, v| h.length }[0].length

      # Prints the data with required padding
      data.each do |header, value|
        puts "#{' ' * (max - header.length)}#{header} #{value}"
      end
    end

    def multi_tty(elements)
      $stderr.puts "No results!" and return if elements.empty?

      heads, procs = tty_procs.each_with_object([[], []]) do |(k, p), m|
        m[0] << k
        m[1] << p
      end
      table = TTY::Table.new(header: heads)
      elements.each do |element|
        table << procs.map { |p| p.call(element) }
      end
      puts table.render(:unicode, padding: [0,1])
    end

    def singular_tsv(element)
      puts tsv_procs.map { |_, p| p.call(element) }.join("\t")
    end

    def multi_tsv(elements)
      $stderr.puts "No results!" and return if elements.empty?

      elements.each do |element|
        puts singular_tsv(element)
      end
    end

    ##
    # Method that returns '(none)' instead of nil when connect
    # to as tty. This is used extensively when printing
    def tty_none_or_nil
      tty? ? '(none)' : nil
    end

    def tty_procs
      raise NotImplementedError
    end

    def tsv_procs
      raise NotImplementedError
    end
  end

  class Output < BaseOutput
    def decommissioned
      if verbose? || mixed_decommissioned?
        ['Decommissioned', ->(a) { a.decommissioned ? 'yes' : 'no' }]
      end
    end

    def mixed_decommissioned?
      @opts.include_decommissioned && !@opts.only_decommissioned
    end

    def verbose?
      @opts.verbose || !$stdout.tty?
    end
  end

  class AssetGroupOutput < Output
    def tty_procs
      [].tap do |a|
        a << ['Name', ->(e) { e.name }]
        a << ['Category', ->(e) { e.category_name || tty_none_or_nil }]
        a << group_unix_name
        a << decommissioned
      end
        .compact
    end

    def tsv_procs
      # NOTE: Do not change the order of these columns.  New columns are added
      # to the end only.
      [].tap do |a|
        a << ['Name', ->(e) { e.name }]
        a << ['Category', ->(e) { e.category_name || tty_none_or_nil }]
        a << decommissioned
        a << group_unix_name
      end
        .compact
    end

    def group_unix_name
      ['Genders Name', ->(a) { a.unix_name || tty_none_or_nil } ]
    end
  end
end
