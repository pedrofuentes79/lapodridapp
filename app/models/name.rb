class Name
  DATA_PATH = Rails.root.join("db/data/names.json").freeze

  attr_reader :name, :gender

  def initialize(name:, gender:)
    @name = name.freeze
    @gender = gender.freeze
    freeze
  end

  def ==(other)
    other.is_a?(Name) && name == other.name && gender == other.gender
  end
  alias eql? ==

  def hash
    [ name, gender ].hash
  end

  class << self
    def all
      @all ||= load_all
    end

    def find(name)
      all.find { |n| n.name == name }
    end

    def male
      all.select { |n| n.gender == "male" }
    end

    def female
      all.select { |n| n.gender == "female" }
    end

    def neutral
      all.select { |n| n.gender == "neutral" }
    end

    private

    def load_all
      data = JSON.parse(File.read(DATA_PATH))

      %w[male female neutral].flat_map do |gender|
        (data[gender] || []).map do |name|
          new(name: name, gender: gender)
        end
      end
    end
  end
end
