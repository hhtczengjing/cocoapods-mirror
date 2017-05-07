# encoding: utf-8

require 'cocoapods'

module Powerdata
	class Spec

		def get_path_of_spec(spec)
      sets = config.sources_manager.search_by_name(spec)
      if sets.count == 1
      		set = sets.first
      elsif sets.map(&:name).include?(spec)
      		set = sets.find { |s| s.name == spec }
      else
      		names = sets.map(&:name) * ', '
      		raise Informative, "More than one spec found for '#{spec}':\n#{names}"
      end
      best_spec, spec_source = spec_and_source_from_set(set)
      spec_podspec_path = pathname_from_spec(best_spec, spec_source).to_s
      index = spec_podspec_path.index(spec)
      return spec_podspec_path[0, index].to_s
    end

    def pathname_from_spec(spec, _source)
    	Pathname(spec.defined_in_file)
    end

    def all_paths_from_set(set)
    	paths = ''
    	sources = set.sources
    	sources.each do |source|
    		versions = source.versions(set.name)
    	  	versions.each do |version|
    	    	spec = source.specification(set.name, version)
    	    	paths += "#{pathname_from_spec(spec, source)}\n"
    	  	end
    	end
    	paths
    end

    def spec_and_source_from_set(set)
    	sources = set.sources
    	best_source = best_version = nil
    	sources.each do |source|
        versions = source.versions(set.name)
        versions.each do |version|
          if !best_version || version > best_version
            best_source = source
            best_version = version
        	end
      	end
    	end
    	if !best_source || !best_version
        raise Informative, "Unable to locate highest known specification for `#{set.name}'"
    	end
    	[best_source.specification(set.name, best_version), best_source]
    end

    def config
      Pod::Config.instance
    end

  end
end
