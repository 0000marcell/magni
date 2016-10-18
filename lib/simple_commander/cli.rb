# REF: 0
require 'yaml'
require 'simple_commander/helpers/io'
require 'fileutils'
require 'byebug'

module SimpleCommander
	class CLI
		include IO_helper
		DEFAULT_PATH = "#{File.dirname(__FILE__)}/config.yml"
		TEMPLATE_PATH = File.expand_path "#{File.dirname(__FILE__)}" + 
																			'/../../templates'
		attr_accessor :config_file
		
		class UndefinedSCPath < StandardError
			def initialize
				msg = <<-END 
You need to set a path to commander
use simple_commander init <path> or cd to
the folder you want to use an repo for your 
simple commander scripts  and run 
simple_commander init
				END
				super(msg)
			end
		end

		class InvalidProgram < StandardError; end

		def initialize(path=DEFAULT_PATH)
			@config_file = path
			FileUtils.touch(@config_file) if !File.file?(@config_file)
			yml = YAML.load_file(@config_file)
			if(!yml)
				obj = {
					'path'=> '',
					'exec_path'=> ''
				}
				File.open(@config_file, 'w+'){|f| f.write(obj.to_yaml)}
			end
		end

		def init(path='./')
			if path
				local_path = File.expand_path(path)
			else
				local_path = File.expand_path('./')
			end
			yml = YAML.load_file(@config_file)
			yml[:path] = local_path 
			File.open(@config_file, 'w+'){|f| f.write(yml)}
		end

		def show_config
			raise UndefinedSCPath if !File.file?(@config_file)
			say YAML.load_file(@config_file)
		end

		def new(*args)
			sc_path = YAML.load_file(@config_file)[:path]
			raise UndefinedSCPath if !sc_path
			s_path = "#{sc_path}/#{args[0]}"
			fail InvalidProgram, "program #{args[0]} already exists!", caller if File.directory?(s_path)
			@program_name = args[0]
			@lib_path = "#{s_path}/lib" 
			mkdir s_path 
			mkdir "#{s_path}/bin"
			mkdir "#{s_path}/spec"
			mkdir "#{s_path}/lib"
			mkdir "#{s_path}/lib/#{@program_name}"
			template "#{TEMPLATE_PATH}/lib.erb",
				"#{s_path}/lib/#{@program_name}.rb"

			template "#{TEMPLATE_PATH}/version.erb",
				"#{s_path}/lib/#{@program_name}/version.rb"

			template "#{TEMPLATE_PATH}/bin.erb",
				"#{s_path}/bin/#{@program_name}"
			FileUtils.chmod "+x", "#{s_path}/bin/#{@program_name}"
			cp "#{s_path}/bin/#{@program_name}", exec_path if exec_path
		end

		##
		# if set the bin/executable* file of any program created will be put in this folder
		def exec_path
			YAML.load_file(@config_file)[:exec_path]
		end

		##
		# set exec path
		def set_exec_path(path)
			yml = YAML.load_file(@config_file)
			yml[:exec_path] = File.expand_path(path)
			File.open(@config_file, 'w+'){|f| f.write(yml)}
		end
	end
end
