class Search
  attr_reader :term, :streams, :top_results, :spelling_suggestion, :result_count

  def initialize(options)
    @term                 = options[:term]
    @streams              = options[:streams]
    @top_results          = options[:top_results]
    @spelling_suggestion  = options[:spelling_suggestion]
    @result_count         = options[:result_count]
  end
end
