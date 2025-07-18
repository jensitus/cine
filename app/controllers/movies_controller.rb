class MoviesController < ApplicationController
  before_action :set_movie, only: [:show]

  def index
    @movies = Movie.all
  end

  def show
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_movie
    @cinema = Movie.find(params.expect(:id))
  end

  # Only allow a list of trusted parameters through.
  def movie_params
    params.expect(movie: [:movie_id, :title, :description])
  end

end
