# frozen_string_literal: true

class PhtPostService
  def initialize(pht_client)
    @pht_client = pht_client
    @known = {}

    @counters = {
      'feed' => {
        page: 1,
        has_next: true
      },
      'topic' => {
        page: 1,
        has_next: true
      }
    }
  end

  def preload
    @known = @pht_client.load_fix_page
    preload_next_page 'feed'
    preload_next_page 'topic'
    preload_wiki
  end

  def get_flow_post(id)
    get_post 'feed', id
  end

  private

  def preload_next_page(list)
    counter = @counters[list]
    pages = @pht_client.load_pages(list, counter[:page], 1)
    @known.merge! pages

    if pages.empty?
      counter[:has_next] = false
    else
      counter[:page] += 1
      counter[:has_next] = true
    end

    counter[:has_next]
  end

  def preload_wiki
    wiki_ids = @pht_client.load_wiki_ids.filter { |id| id != 6 }

    wiki_ids.each do |id|
      @known.merge! @pht_client.load_pages('wiki', 1, nil, id)
    end
  end

  def get_post(list, id)
    loop do
      post = @known[id]
      return post unless post.nil?

      return @pht_client.fetch_content_post(id) unless preload_next_page(list)
    end
  end
end
