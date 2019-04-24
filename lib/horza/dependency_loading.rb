module Horza
  module DependencyLoading
    extend self

    Error = Class.new(StandardError)
    MissingFile = Class.new(Error)

    def resolve_dependency(entity_name)
      file_name = entity_name.to_s.underscore
      # Search for a matching filename in #constant_paths
      # and try to load a constant that matches.
      resolve_from_file_paths(file_name)
    end

    def resolve_from_file_paths(entity_name)
      if Horza.constant_paths.empty?
        # try in current scope, even with no lookup paths configured
        begin
          entity_name.camelize.constantize
        rescue NameError
          raise ArgumentError.new("No file paths configured to lookup constants")
        end
      else
        file_path = search_for_file(entity_name)

        resolved_name = constant_name_for_path(file_path).first

        if resolved_name.nil?
          Error.new("No constant found for: #{entity_name.inspect}")
        else
          ActiveSupport::Dependencies::Reference.safe_get(resolved_name)
        end
      end
    end


    def constant_name_for_path(file_path)
      ActiveSupport::Dependencies.loadable_constants_for_path(
        file_path, Horza.constant_paths
      ).tap do |loadables|
        if loadables.many?
          raise "It seems that your registered constant file paths are not setup correctly " +
                 "and would cause Horza to try and load the following constants:\n\n #{loadables.map(&:inspect).join(', ')}"
        end
      end
    end

     # Search for a file matching the provided suffix.
     # This recursively checks directories in the #Horza.constant_paths for matches.
    def search_for_file(path_suffix)
      path_suffix = path_suffix.sub(/(\.rb)?$/, ".rb")

      Horza.constant_paths.each do |root|
        Dir.glob(File.join(root, "**/")).each do |dir|
          path = File.join(dir, path_suffix)
          return path if File.file? path
        end
      end

      raise MissingFile.new(
        "No matching file found for: '#{path_suffix.sub(/(\.rb)?$/, "")}'\n" +
        "Searched in: (#{Horza.constant_paths.map(&:inspect).join(', ')})"
      )
    end

  end
end
