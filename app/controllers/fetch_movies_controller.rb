class FetchMoviesController < ApplicationController
  def get
    Movie.fetch_movie
  end
end
