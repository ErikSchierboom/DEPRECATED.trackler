module Trackler
  class MetadataFile
    attr_reader :content

    def self.for(problem:, track:)
      x = [TrackMetadataFile, CommonMetadataFile].detect(-> {NullMetadataFile}) do |d|
        d.exists?(problem: problem, track: track)
      end
        x.new(problem: problem, track: track)
    end

    def self.exists?(problem:, track:)
      File.exists?(location(problem: problem, track: track))
    end

    def initialize(problem:, track:)
      @content = File.read(self.class.location(problem: problem, track: track))
    end

    def to_h
      YAML.load(@content)
    end
  end

  class TrackMetadataFile < MetadataFile
    def self.location(problem:, track:)
      File.join(problem.root, 'tracks', track.id, 'exercises', problem.slug, 'metadata.yml')
    end
  end

  class CommonMetadataFile < MetadataFile
    def self.location(problem:, **_track)
      File.join(problem.root, 'common', 'exercises', problem.slug, 'metadata.yml')
    end
  end

  class NullMetadataFile < BasicObject
    def method_missing(*)
      # NOOP
    end

    def respond_to?(*)
      true
    end

    def inspect
      "<null>"
    end

    def exists?
      false
    end

    def to_h
      {}
    end

    def initialize(*)
      self
    end

    klass = self
    define_method(:class) { klass }
  end
end
