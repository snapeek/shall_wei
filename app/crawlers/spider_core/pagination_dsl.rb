module SpiderCore
  module PaginationDSL

    attr_accessor :next_page, :skip_pages

    def keep_eyes_on_next_page(pattern, opts = {}, &block)
      kind = opts[:kind] || :css
      
      actions << lambda {
        element = first(kind, pattern)
        path = block_given? ? yield(element) : element && element[:href]
        if path && !@is_stop
          @paths.unshift(path)
          logger.info "Start crawl next page."
        end
      }
    end
  end
end
