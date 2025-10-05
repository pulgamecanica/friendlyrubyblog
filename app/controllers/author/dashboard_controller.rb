class Author::DashboardController < Author::BaseController
  def index
    @stats = DashboardStatsService.new(current_author)
  end
end
