class FetchMoviesController < ApplicationController
  def get
    Movie.set_date
  end
end
