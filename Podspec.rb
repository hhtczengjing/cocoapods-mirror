# encoding: utf-8

require 'uri'
require 'fileutils'
require 'multi_json'
require 'cocoapods'

module Powerdata
	class Podspec

		attr_reader :repo_mirror_path, :pods_with_dependency, :spec_name, :repo_store_path

    	def initialize(spec_name)
      		@spec_name = spec_name # pod库的名称
      		@pods_with_dependency = []
      		@repo_mirror_path = "git@gitlab.powerdata.com.cn:mirrors_github"
      		@repo_store_path = File.join(Dir.pwd, 'Specs')
      	end

		def parse()
			check_exist_specs = Dir[File.join(self.repo_root_path, "*")]
  			check_exist_repo = check_exist_specs.select { |s| File.basename(s) == @spec_name }.first
  			if check_exist_repo
  				do_parse()
  			end
		end

		def do_parse() 
			# 将master目录下面的repo拷贝到Specs目录下面
			puts " -> copy #{self.repo_path} to #{@repo_store_path}"
    		FileUtils.cp_r repo_path, @repo_store_path
    		puts " * updating repo url"
		    Dir["#{@repo_store_path}/#{@spec_name}/*"].each do |f|
		      pod_file = File.join(f, "#{@spec_name}.podspec.json")
		      save_pod_file = File.join(f, "#{@spec_name}-pd.podspec.json")
		      json = File.read(pod_file)
		      data = MultiJson.load json
		      if data['source']['git']
		        puts " -> #{data['version']}: git -> #{data['source']['git']}"
		        # 在名字的后面加上-pd
		        orginal_spec_name = data['name']
		        coverted_spec_name = "#{orginal_spec_name}-pd"
		        data['name'] = coverted_spec_name
		        # 转换为内部的地址
		        orginal_repo_url = data['source']['git']
		        coverted_repo_name = URI.parse(orginal_repo_url).path[1..-1].gsub('/', '-').gsub('.git', '').downcase
		        data['source']['git'] = "#{@repo_mirror_path}/#{coverted_repo_name}.git"
		        # 获取dependencies
		        parse_dependencies(data)
		        # 文件另存为
		        FileUtils.rm(pod_file)
		        File.write(save_pod_file, JSON.pretty_generate(data))
		      elsif data['source']['http']
		        puts " -> #{data['version']}: http, -> #{data['source']['http']}"
		        # 在名字的后面加上-pd
		        orginal_spec_name = data['name']
		        coverted_spec_name = "#{orginal_spec_name}-pd"
		        data['name'] = coverted_spec_name
		        # 文件另存为
		        FileUtils.rm(pod_file)
		        File.write(save_pod_file, JSON.pretty_generate(data))
		      elsif data['source']['svn']
		        puts " -> #{data['version']}: svn, -> #{data['source']['svn']}"
		        # 在名字的后面加上-pd
		        orginal_spec_name = data['name']
		        coverted_spec_name = "#{orginal_spec_name}-pd"
		        data['name'] = coverted_spec_name
		        # 文件另存为
		        FileUtils.rm(pod_file)
		        File.write(save_pod_file, JSON.pretty_generate(data))
		      end
		    end
		end

		def parse_dependencies(data)
			# 解析 dependencies
			dependencies = data['dependencies']
			if dependencies
				dependencies.each do |dependency|
					if dependency
						dependency_spec_name = dependency.first
						dependency_spec_name = dependency_spec_name.split('/').first
						if !have_dependency_parsed(dependency_spec_name)
							if dependency_spec_name != @spec_name
								puts " dependencies -> #{dependency_spec_name}"
								Powerdata::Podspec.new(dependency_spec_name).parse()
								@pods_with_dependency.push(dependency_spec_name)
							end
						end
					end
				end
			end

			# 解析 subspecs
			subspecs = data['subspecs']
			if subspecs
				subspecs.each do |subspec|
					subspec_dependencies = subspec['dependencies']
					if subspec_dependencies
						subspec_dependencies.each do |subspec_dependency|
							if subspec_dependency
								subspec_dependency_spec_name = subspec_dependency.first
								subspec_dependency_spec_name = subspec_dependency_spec_name.split('/').first
								if !have_dependency_parsed(subspec_dependency_spec_name)
									if subspec_dependency_spec_name != @spec_name
										puts " subspecs -> #{subspec_dependency_spec_name}"
										Powerdata::Podspec.new(subspec_dependency_spec_name).parse()
										@pods_with_dependency.push(subspec_dependency_spec_name)
									end
								end
							end
						end
					end
				end
			end
		end

		def get_path_of_spec(spec)
			config = Pod::Config.instance
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
      		spec_podspec_path = Pathname(best_spec.defined_in_file).to_s
      		index = spec_podspec_path.index(spec)
      		return spec_podspec_path[0, index].to_s
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

    	def have_dependency_parsed(dependency_spec_name)
    		stauts = false
    		@pods_with_dependency.each do |name|
    			if name == dependency_spec_name
    				stauts = true
    				break
    			end
    		end
    		return stauts
    	end

    	def repo_path
    		path1 = get_path_of_spec(@spec_name)
    		path2 = File.join(path1, @spec_name)
    		return path2 # 本地的pod库的podspec文件存放路径
    	end

    	def repo_root_path
    		path1 = get_path_of_spec(@spec_name)
    		return path1 # 本地的pod库的podspec文件存放路径
    	end

	end
end