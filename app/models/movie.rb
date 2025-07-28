class Movie < ApplicationRecord

  require 'nokogiri'
  require 'open-uri'

  has_and_belongs_to_many :genres
  has_many :schedules
  has_many :cinemas, through: :schedules

  VIENNA = "Wien"
  SEVEN_DAYS = 4
  TOKEN = "eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiI5MzNjZGQ3MTcxYzUxMDZlNDQ5MjU3N2YzZjAwOGM1ZCIsIm5iZiI6MTM2NDc1NzgxNy4wLCJzdWIiOiI1MTU4OGQzOTE5YzI5NTY3NDQwZDlhYWUiLCJzY29wZXMiOlsiYXBpX3JlYWQiXSwidmVyc2lvbiI6MX0.sNb6zKWkCKY600bpUOn2WKac1GUOJW6-E-0O0PIBfjc"

  require "net/http"
  require "json"

  def self.set_date
    date = Date.today
    condition_date = Date.today.plus_with_duration(SEVEN_DAYS)
    while date < condition_date do
      url = URI.parse("https://efs-varnish.film.at/api/v1/cfs/filmat/screenings/nested/movie/" + date.to_s)
      date = date.plus_with_duration(1)
      fetch_movie(url)
    end
    delete_old_schedules(date)
    delete_movies_without_schedules
  end

  def self.delete_old_schedules(date)
    Schedule.all.each do |schedule|
      today = Date.today
      if schedule.time.to_date < today
        schedule.delete
      end
    end
  end

  def self.delete_movies_without_schedules
    Movie.all.each do |movie|
      if movie.schedules.empty?
        movie.delete
      end
    end
  end

  def self.fetch_movie(url)

    date = Date.today
    puts date

    # request = Net::HTTP::Get.new(url.to_s)
=begin
    file = File.read("./public/knochenmann.json")
    result = JSON.parse(file)
=end

    response = Net::HTTP.get(url)
    result = JSON.parse(response)

    result = result["result"]
    result.each do |movie_json|
      film_at_uri = movie_json["parent"]["uri"].gsub("/filmat", "")
      movie_string_id = "m-" + movie_json["parent"]["title"].downcase.gsub(" ", "-").gsub("---", "-")
      movie_created = find_or_create_movie(movie_string_id, film_at_uri, movie_json["parent"]["title"])
      if movie_json["parent"]["genres"] != nil
        create_genres(movie_json["parent"]["genres"], movie_created)
      end
      get_cinema_and_schedule(movie_json, movie_created.id)
    end
  end

  private

  def self.find_or_create_movie(movie_string_id, film_at_uri, movie_title)
    movie_exists = Movie.where(movie_id: movie_string_id).exists?
    if movie_exists == true
      movie_created = Movie.find_by(movie_id: movie_string_id)
      get_additional_info_for_movie(movie_created, film_at_uri)
    else
      movie_created = Movie.create!(movie_id: movie_string_id, title: movie_title)
      get_additional_info_for_movie(movie_created, film_at_uri)
    end
    movie_created
  end

  def self.get_cinema_and_schedule(movie_json, movie_id)
    movie_json["nestedResults"].each do |nested_result|
      if nested_result["parent"]["county"] == VIENNA
        cinema = create_cinema(nested_result["parent"])
        nested_result["screenings"].each do |screening|
          schedule = create_schedule(screening, movie_id, cinema.id)
          if screening["tags"] != nil
            screening["tags"].each do |tag|
              t = create_tag(tag)
              if t != nil
                if schedule != nil && !schedule.tags.include?(t)
                  schedule.tags.push(t)
                end
              end
            end
          end
        end
      end
    end
  end

  def self.create_genres(genres, movie_created)
    genres.each do |genre_json|
      genre = create_genre(genre_json)
      unless movie_created.genres.include?(genre)
        movie_created.genres.push(genre)
      end
    end
  end

  def self.get_additional_info(uri)
    docs = nil
    begin
      docs = Nokogiri::HTML(URI.open("https://film.at" + uri))
    rescue OpenURI::HTTPError => error
      Rails.logger.error error.message
    end
    docs
  end

  def self.get_additional_info_for_movie(movie, uri)
    docs = get_additional_info(uri)
    if docs != nil

      movie_query_string = get_movie_querystring(docs, movie.title)
      puts movie_query_string.inspect

      docs.css('article div p span.release').each do |link|
        additional_info = link.content.gsub(" ", "").split(",")
        year = additional_info[-1].gsub("\n", "")
        additional_info.delete_at(-1)
        countries = additional_info.join(", ")
        country_string = countries.chomp(', ').gsub("\n", "")
        movie.update(countries: country_string, year: year)
        tmdb_id = get_tmdb_id(movie_query_string, year)
        if tmdb_id != nil
          description = get_additional_info_from_tmdb(tmdb_id.to_s, "overview")
          poster_path = get_additional_info_from_tmdb(tmdb_id.to_s, "poster_path")
          credits = get_cast(tmdb_id.to_s)
          set_cast_to_movie(movie, credits["cast"])
          set_crew_to_movie(movie, credits["crew"])
        end
        movie.update(tmdb_id: tmdb_id) unless tmdb_id == nil
        movie.update(description: description) unless description == nil
        movie.update(poster_path: poster_path) unless poster_path == nil
      end

    end
  end

  def self.set_cast_to_movie(movie, cast)
    actors = ""
    cast.each do |c|
      if c["known_for_department"] == "Acting"
        actors << c["name"] + ", "
      end
    end
    movie.update(actors: actors.chomp(", "))
  end

  def self.set_crew_to_movie(movie, crew)
    director = ""
    crew.each do |c|
      if c["known_for_department"] == "Directing" and c["job"] == "Director"
        director << c["name"] + ", "
      end
    end
    movie.update(director: director.chomp(", "))
  end

  def self.get_movie_querystring(docs, movie_title_json)
    movie_query_string = nil
    docs.css('article div p span.ov-title').each do |link|
      movie_query_string = link.content
    end
    if movie_query_string == nil || movie_query_string == ""
      movie_query_string = movie_title_json
    end
    change_umlaut_to_vowel(movie_query_string)
  end

  def self.get_additional_info_from_tmdb(tmdb_id, kind_of_info)
    url = URI("https://api.themoviedb.org/3/movie/" + tmdb_id + "?language=de-DE&region=DE")
    tmdb_results = get_tmdb_results(url)
    additional_info = tmdb_results["#{kind_of_info}"]
    additional_info
  end

  def self.get_tmdb_id(movie_title, year)
    puts "+ + + + + + + + + + + + "
    puts movie_title
    puts year
    begin
      url = URI("https://api.themoviedb.org/3/search/movie?query=" + movie_title + "&language=de-DE&region=DE")
    rescue URI::InvalidURIError
      Rails.logger.error 'invalid uri'
    end
    tmdb_results = get_tmdb_results(url)
    potential_id = nil
    puts tmdb_results.inspect

    if tmdb_results != nil
      tmdb_results["results"].each do |tmdb_result|
        original_title = tmdb_result["original_title"].downcase
        if movie_title.eql? tmdb_result["original_title"] or movie_title.downcase.eql?(tmdb_result["original_title"].downcase)
          release_date = tmdb_result["release_date"]
          if release_date != nil
            if release_date.to_date != nil
              release_year = release_date.to_date.strftime("%Y")
            end
          end
        end
        puts "original_title " + original_title
        puts "movie_title " + movie_title
        puts "release_year " + release_year.inspect
        puts "year " + year
        puts " h i m m e l "
        if original_title == movie_title && release_year == year
          potential_id = tmdb_result['id']
        elsif original_title == movie_title && year.to_i == release_year.to_i + 1
          potential_id = tmdb_result['id']
        elsif original_title == movie_title && year.to_i == release_year.to_i - 1
          potential_id = tmdb_result['id']
        else
          puts false
        end
        puts "potential_id inside loop: #{potential_id}"
      end
    end
    puts "potential_id outside loop: #{potential_id}"
    potential_id
  end

  def self.change_umlaut_to_vowel(querystring)
    querystring.downcase.gsub("ä", "a").gsub("ö", "o").gsub("ü", "u").gsub("ß", "ss")
  end

  def self.get_cast(tmdb_id)
    url = URI("https://api.themoviedb.org/3/movie/#{tmdb_id}/credits")
    puts url
    tmdb_results = get_tmdb_results(url)
    tmdb_results
  end

  def self.get_tmdb_results(url)
    begin
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true if url.scheme == 'https'
      request = Net::HTTP::Get.new(url)
      request['Content-Type'] = 'application/json'
      request['Authorization'] = "Bearer #{TOKEN}"
      response = http.request(request)
      tmdb_results = JSON.parse(response.body)
      return tmdb_results
    rescue NoMethodError
      Rails.logger.error 'no method error, because of invalid URI'
    end
    return nil
  end

  def self.create_genre(genre_name)
    genre_id = "g-" + genre_name.downcase.gsub(" ", "-")
    if Genre.where(genre_id: genre_id).exists? == false
      genre = Genre.create!(genre_id: genre_id,
                            name: genre_name)
    else
      genre = Genre.find_by(genre_id: genre_id)
    end
    genre
  end

  def self.create_cinema(cinema)
    theater_id = "t-" + cinema["title"].gsub(" ", "-").downcase
    if Cinema.where(cinema_id: theater_id).exists? == false
      cinema_created = Cinema.create!(title: cinema["title"],
                                      county: cinema["county"],
                                      uri: get_cinema_url(cinema["uri"].gsub("/filmat", "")),
                                      cinema_id: theater_id)
    else
      cinema_created = Cinema.find_by(cinema_id: theater_id)
    end
    cinema_created
  end

  def self.get_cinema_url(uri)
    cinema_url = nil
    docs = get_additional_info(uri)
    if docs != nil
      docs.css('main div section div div p a').each do |link|
        if link.content.start_with?("http")
          cinema_url = link.content
        end
      end
    end
    return cinema_url
  end

  def self.create_schedule(screening, movie_id, cinema_id)
    schedule_id = "s-" + movie_id.to_s + "-" + cinema_id.to_s + "-" + screening["time"]
    begin
      schedule_created = Schedule.create!(time: screening["time"],
                                          three_d: screening["3d"],
                                          ov: screening["ov"],
                                          info: screening["info"],
                                          movie_id: movie_id,
                                          cinema_id: cinema_id,
                                          schedule_id: schedule_id)
    rescue Exception => ex
      Rails.logger.error "ERROR " + ex.to_s
      schedule_created = Schedule.find_by(schedule_id: schedule_id)
    end
    schedule_created
  end

  def self.create_tag(tag)
    if Tag.where(name: tag).exists? == false
      tag_id = "t-" + tag.downcase.gsub(" ", "-").downcase
      t = Tag.create!(name: tag, tag_id: tag_id)
    else
      t = Tag.find_by(name: tag)
    end
    t
  end

end
