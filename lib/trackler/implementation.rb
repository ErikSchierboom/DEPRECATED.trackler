require 'pathname'
require_relative 'file_bundle'

module Trackler
  # Implementation is a language-specific implementation of an exercise.
  class Implementation
    IGNORE_PATTERNS = [
      "\/HINTS\.md$",
      "\/\.$",
      "/\.meta/"
    ]

    attr_reader :track, :problem
    attr_writer :files
    def initialize(track, problem)
      @track = track
      @problem = problem
    end

    def file_bundle
      @file_bundle ||= FileBundle.new(implementation_dir, regexes_to_ignore)
    end

    def exists?
      File.exist?(implementation_dir)
    end

    def files
      @files ||= Hash[file_bundle.paths.map {|path|
        [path.relative_path_from(implementation_dir).to_s, File.read(path)]
      }].merge("README.md" => readme)
    end

    def zip
      @zip ||= file_bundle.zip do |io|
        io.put_next_entry('README.md')
        io.print readme
      end
    end

    def readme
      @readme ||= assemble_readme
    end

    def exercise_dir
      if File.exist?(track_dir.join('exercises'))
        File.join('exercises', problem.slug)
      else
        problem.slug
      end
    end

    def git_url
      [track.repository, "tree/master", exercise_dir].join("/")
    end

    private

    def regexes_to_ignore
      (IGNORE_PATTERNS + [@track.ignore_pattern]).map do |pattern|
        Regexp.new(pattern, Regexp::IGNORECASE)
      end
    end

    def implementation_dir
      @implementation_dir ||= track_dir.join(exercise_dir)
    end

    def track_dir
      root = Pathname.new(track.root)
      @track_dir ||= root.join('tracks', track.id)
    end

    def assemble_readme
      <<-README
# #{readme_title}

#{problem.blurb}

#{readme_body}

#{readme_source}

#{incomplete_solutions_body}
      README
    end

    def readme_title
      problem.name
    end

    def readme_body
      [
        problem.description,
        implementation_hint,
        track_hint,
      ].reject(&:empty?).join("\n").strip
    end

    def readme_source
      problem.source_markdown
    end

    def incomplete_solutions_body
      <<-README
## Submitting Incomplete Problems
It's possible to submit an incomplete solution so you can see how others have completed the exercise.
      README
    end

    def track_hint
      track_hints_filename = track_dir.join('exercises','TRACK_HINTS.md')
      unless File.exist?(track_hints_filename)
        track_hints_filename = track_dir.join('SETUP.md')
      end
      read track_hints_filename
    end

    def implementation_hint
      read File.join(implementation_dir, 'HINTS.md')
    end

    def read(f)
      if File.exist?(f)
        File.read(f)
      else
        ""
      end
    end
  end
end
