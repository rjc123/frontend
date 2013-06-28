class Search
  attr_reader :streams, :top_results, :spelling_suggestion, :result_count

  def initialize(options)
    @streams              = options[:streams]
    @top_results          = options[:top_results]
    @spelling_suggestion  = options[:spelling_suggestion]
    @result_count         = options[:result_count]
  end
end
