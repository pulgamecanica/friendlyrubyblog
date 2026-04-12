class Arcade::GamesController < Arcade::BaseController
  before_action :set_game,             only: [ :show, :edit, :update, :destroy, :resubmit ]
  before_action :require_submitter,    only: [ :edit, :update, :destroy, :resubmit ]

  def index
    @games = Game.listed.order(created_at: :desc)
  end

  def show
    @block = @game.mlx42_block
  end

  def new
    @game = Game.new(source: { "kind" => "git" })
  end

  def create
    @game = Game.new(game_params)
    @game.submitter = current_player
    @game.status    = :draft

    apply_source_params!(@game)

    if @game.save
      GameIngestionJob.perform_later(@game.id)
      redirect_to arcade_game_path(@game), notice: "Game submitted. Ingesting…"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    @game.assign_attributes(game_params)

    if @game.save
      redirect_to arcade_game_path(@game), notice: "Game updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # Re-run ingestion + compile, e.g. after a fix push to git or a new zip.
  def resubmit
    apply_source_params!(@game)
    @game.save!
    GameIngestionJob.perform_later(@game.id)
    redirect_to arcade_game_path(@game), notice: "Re-ingesting source…"
  end

  def destroy
    @game.soft_delete!
    redirect_to arcade_dashboard_path, notice: "Game removed."
  end

  private

  def set_game
    @game = Game.visible.friendly.find(params[:id])
  end

  def require_submitter
    return if @game.submitter_id == current_player.id

    redirect_to arcade_game_path(@game), alert: "Only the submitter can edit this game."
  end

  def game_params
    params.require(:game).permit(
      :title,
      :description,
      :cover,
      :source_archive,
      scoring: [ :direction, :unit, :min, :max, :monotonic, :type ],
      _flags: [ :keep_for_review_on_failure ],
      _build: [ :make_target, :output_dir ]
    ).tap do |p|
      scoring = p.delete(:scoring)&.to_h
      flags   = p.delete(:_flags)&.to_h || {}
      build   = p.delete(:_build)&.to_h || {}

      merged_metadata = @game&.metadata.to_h
      merged_metadata["scoring"] = (merged_metadata["scoring"] || {}).merge(scoring.to_h.compact_blank) if scoring
      merged_metadata["keep_for_review_on_failure"] =
        ActiveModel::Type::Boolean.new.cast(flags["keep_for_review_on_failure"])
      merged_metadata["make_target"] = build["make_target"].to_s.strip.presence
      merged_metadata["output_dir"]  = build["output_dir"].to_s.strip.presence || "web"

      p[:metadata] = merged_metadata
    end
  end

  # Source kind + git fields live under `game[source]`, but file uploads
  # (source_archive) are top-level attachments. We fold the submitted
  # fields into Game#source jsonb and clear the other side so re-submitting
  # doesn't leave stale git_url behind a zip upload (or vice-versa).
  def apply_source_params!(game)
    src = params.require(:game).fetch(:source, {}).permit(:kind, :git_url, :git_ref).to_h
    kind = src["kind"]

    case kind
    when "git"
      unless src["git_url"].to_s.strip.start_with?("https://")
        game.errors.add(:base, "Git URL must start with https://")
      end
      game.source = {
        "kind"    => "git",
        "git_url" => src["git_url"].to_s.strip,
        "git_ref" => src["git_ref"].to_s.strip.presence
      }
      # Detach any previously uploaded zip.
      game.source_archive.purge_later if game.source_archive.attached?
    when "zip"
      archive = params.dig(:game, :source_archive)
      if archive.blank? && !game.source_archive.attached?
        game.errors.add(:base, "Please attach a .zip file")
      end
      game.source_archive.attach(archive) if archive.present?
      game.source = { "kind" => "zip" }
    else
      game.errors.add(:base, "Please choose a source type (git or zip)")
    end
  end
end
