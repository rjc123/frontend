require "search"

class SearchBuilder

  # Essentially a script-like factory method.
  # Returns a new Search with all the bits set on it.
  # Not ideal but better than where we were.
  def for_term(term, organisation=nil)
    streams = []

    if organisation
      government_results = retrieve_government_results(term, organisation)
      unfiltered_government_results = retrieve_government_results(term)
    else
      government_results = retrieve_government_results(term)
      unfiltered_government_results = government_results
    end

    if raw_mainstream_results(term)["spelling_suggestions"]
      spelling_suggestion = raw_mainstream_results(term)["spelling_suggestions"].first
    else
      spelling_suggestion = nil
    end

    detailed_results = retrieve_detailed_guidance_results(term)
    # hackily downweight detailed results to prevent them swamping mainstream results
    adjusted_detailed_results = multiply_result_scores(detailed_results, 0.8)

    streams << SearchStream.new(
      "services-information",
      "Services and information",
      merge_result_sets(mainstream_results(term), adjusted_detailed_results),
      grouped_mainstream_results(term)[:recommended_link]
    )
    streams << SearchStream.new(
      "government",
      "Departments and policy",
      government_results
    )

    # This needs to be done before top result extraction, otherwise the
    # result count needs to incorporate the top result size.
    result_count = streams.map { |s| s.total_size }.sum

    top_result_sets = streams.reject { |s| s.key == "government" }.map(&:results)
    # Hackily downweight government results to stop them from swamping mainstream in top results
    top_result_sets << multiply_result_scores(unfiltered_government_results, 0.6)

    all_results_ordered = merge_result_sets(*top_result_sets)
    top_results = all_results_ordered[0..2]
    top_results.each do |result_to_remove|
      streams.detect do |stream|
        stream.results.delete(result_to_remove)
      end
    end

    Search.new(streams: streams,
               top_results: top_results,
               spelling_suggestion: spelling_suggestion,
               result_count: result_count)
  end

  def grouped_mainstream_results(term)
    @_grouped_mainstream_results ||= begin
      results = retrieve_mainstream_results(term)
      grouped_results = results.group_by do |result|
        if !result.respond_to?(:format)
          :everything_else
        else
          if result.format == 'recommended-link'
            :recommended_link
          else
            :everything_else
          end
        end
      end
      grouped_results[:recommended_link] ||= []
      grouped_results[:everything_else] ||= []
      grouped_results
    end
  end

  def mainstream_results(term)
    grouped_mainstream_results(term)[:everything_else]
  end

  def raw_mainstream_results(term)
    @_raw_mainstream_results ||= begin
      Frontend.mainstream_search_client.search(term, extra_search_parameters)
    end
  end

  def retrieve_mainstream_results(term)
    res = raw_mainstream_results(term)
    res["results"].map { |r| SearchResult.new(r) }
  end


  def retrieve_detailed_guidance_results(term)
    res = Frontend.detailed_guidance_search_client.search(term, extra_search_parameters)
    res["results"].map { |r| SearchResult.new(r) }
  end

  def retrieve_government_results(term, organisation = nil)
    extra_parameters = extra_search_parameters
    extra_parameters[:organisation_slug] = organisation if organisation
    res = Frontend.government_search_client.search(term, extra_parameters)
    res["results"].map { |r| GovernmentResult.new(r) }
  end

  def extra_search_parameters
    extra_parameters = { response_style: "hash",  minimum_should_match: "1" }
    extra_parameters
  end

  def merge_result_sets(*result_sets)
    # .sort_by(&:es_score) will return it back to front
    result_sets.flatten(1).sort_by(&:es_score).reverse
  end

  def multiply_result_scores(result_set, multiply_by)
    result_set.map do |result|
      result.result["es_score"] = result.result["es_score"] * multiply_by
      result
    end
  end
end
