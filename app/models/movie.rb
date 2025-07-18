class Movie < ApplicationRecord
  has_and_belongs_to_many :genres
  has_many :schedules
  has_many :cinemas, through: :schedules

  VIENNA = "Wien"

  require "net/http"
  require "json"

  def self.fetch_movie
    # url = URI.parse("https://efs-varnish.film.at/api/v1/cfs/filmat/screenings/nested/movie/2025-06-08")
    # request = Net::HTTP::Get.new(url.to_s)
    # response = Net::HTTP.get(url)
    file = File.read("./public/movies.json")
    # result = JSON.parse(response)
    result = JSON.parse(file)
    result = result["result"]
    result.each do |movie_json|
      puts "   +   +   +  movie +   +   +   +  "
      puts movie_json["parent"]
      puts movie_json["parent"]["id"]
      puts movie_json["parent"]["title"]
      puts movie_json["parent"]["uri"]
      puts movie_json["parent"]["genres"]

      movie_string_id = "m-" + movie_json["parent"]["title"].downcase.gsub(" ", "-").gsub("---", "-")
      puts movie_string_id
      movie_exists = Movie.where(movie_id: movie_string_id).exists?
      puts movie_exists
      if movie_exists == true
        movie_created = Movie.find_by(movie_id: movie_string_id)
      else
        movie_created = Movie.create!(movie_id: movie_string_id, title: movie_json["parent"]["title"])
      end
      if movie_json["parent"]["genres"] != nil
        movie_json["parent"]["genres"].each do |genre_json|
          genre = create_genre(genre_json)
          unless movie_created.genres.include?(genre)
            movie_created.genres.push(genre)
          end
        end
      end
      puts "   +   +   +   +   +   +   +  "
      movie_json["nestedResults"].each do |nested_result|
        if nested_result["parent"]["county"] == VIENNA
          puts "   +   +   +   +   +   +   +  "
          cinema = create_cinema(nested_result["parent"])
          nested_result["screenings"].each do |screening|
            puts screening["time"]
            puts "3D: " + screening["3d"].to_s
            puts screening["ov"]
            puts screening["info"]
            puts screening["tags"]
            schedule = create_schedule(screening, movie_created.id, cinema.id)
            if screening["tags"] != nil
              screening["tags"].each do |tag|
                t = create_tag(tag)
                if t != nil
                  if schedule != nil
                    schedule.tags.push(t)
                  end
                end
              end
            end

          end
        end
      end
    end

  end

  private

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
                                      county: cinemal["county"],
                                      uri: cinema["uri"],
                                      cinema_id: theater_id)
    else
      cinema_created = Cinema.find_by(cinema_id: theater_id)
    end
    cinema_created
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
