class DashboardStatsService
  def initialize(author = nil)
    @author = author
  end

  # Overview stats
  def total_documents
    documents_scope.count
  end

  def total_posts
    documents_scope.posts.count
  end

  def total_notes
    documents_scope.notes.count
  end

  def total_pages
    documents_scope.pages.count
  end

  def total_blocks
    Block.unscoped.joins(:document).merge(documents_scope).count
  end

  def total_views
    PageView.joins(:document).merge(documents_scope).count
  end

  def unique_visitors
    PageView.joins(:document).merge(documents_scope).distinct.count(:unique_visitor_id)
  end

  def total_comments
    Comment.where(commentable_type: "Document", commentable_id: documents_scope.pluck(:id)).count
  end

  # Time-based stats
  def documents_this_week
    documents_scope.where("created_at >= ?", 1.week.ago).count
  end

  def blocks_this_week
    Block.unscoped.joins(:document).merge(documents_scope).where("blocks.created_at >= ?", 1.week.ago).count
  end

  def views_this_week
    PageView.joins(:document).merge(documents_scope).this_week.count
  end

  def views_today
    PageView.joins(:document).merge(documents_scope).today.count
  end

  # Block type distribution
  def blocks_by_type
    Block.unscoped
         .joins(:document)
         .merge(documents_scope)
         .group(:type)
         .count
         .transform_keys { |type| type.to_s.sub("Block", "") }
  end

  # Most used tags
  def top_tags(limit = 10)
    Tag.joins(document_tags: :document)
       .merge(documents_scope)
       .group("tags.id", "tags.title")
       .order("COUNT(document_tags.id) DESC")
       .limit(limit)
       .pluck("tags.title", "COUNT(document_tags.id)")
       .to_h
  end

  # Document type distribution
  def documents_by_kind
    documents_scope.group(:kind).count
  end

  # Total word count across all documents
  def total_word_count
    documents_scope.sum("LENGTH(search_text) - LENGTH(REPLACE(search_text, ' ', '')) + 1")
  end

  # Views by country
  def views_by_country(limit = 10)
    PageView.joins(:document)
            .merge(documents_scope)
            .where.not(country: "Unknown")
            .group(:country)
            .order("COUNT(*) DESC")
            .limit(limit)
            .count
  end

  # Views by device
  def views_by_device
    PageView.joins(:document)
            .merge(documents_scope)
            .group(:device)
            .count
  end

  # Views by browser
  def views_by_browser
    PageView.joins(:document)
            .merge(documents_scope)
            .group(:browser)
            .count
  end

  # Most viewed documents
  def most_viewed_documents(limit = 10)
    documents_scope
      .joins(:page_views)
      .group("documents.id", "documents.title", "documents.slug")
      .order("COUNT(page_views.id) DESC")
      .limit(limit)
      .pluck("documents.title", "documents.slug", "COUNT(page_views.id)")
      .map { |title, slug, count| { title: title, slug: slug, views: count } }
  end

  # Recent views
  def recent_views(limit = 20)
    PageView.joins(:document)
            .merge(documents_scope)
            .includes(:document)
            .order(visited_at: :desc)
            .limit(limit)
  end

  # Views over time (last 30 days)
  def views_over_time(days = 30)
    start_date = days.days.ago.beginning_of_day

    PageView.joins(:document)
            .merge(documents_scope)
            .where("page_views.visited_at >= ?", start_date)
            .group("DATE(page_views.visited_at)")
            .order("DATE(page_views.visited_at)")
            .count
            .transform_keys { |date| date.to_s }
  end

  # Documents created over time (last 30 days)
  def documents_over_time(days = 30)
    start_date = days.days.ago.beginning_of_day

    documents_scope
      .where("created_at >= ?", start_date)
      .group("DATE(created_at)")
      .order("DATE(created_at)")
      .count
      .transform_keys { |date| date.to_s }
  end

  # Blocks created over time (last 30 days)
  def blocks_over_time(days = 30)
    start_date = days.days.ago.beginning_of_day

    Block.unscoped
         .joins(:document)
         .merge(documents_scope)
         .where("blocks.created_at >= ?", start_date)
         .group("DATE(blocks.created_at)")
         .order("DATE(blocks.created_at)")
         .count
         .transform_keys { |date| date.to_s }
  end

  private

  def documents_scope
    @author ? @author.documents : Document.all
  end
end
