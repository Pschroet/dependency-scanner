#this hash object collects all the dependencies of the project files, the keys are the file names
$projectDependencies = Hash.new()

def scan(file, includeString, removeRegex)
	isIteratable = false
	#check if removeRegex can be iterated, e. g. when semicolons and comments need to be removed
	if(removeRegex.respond_to?(:each))
		isIteratable = true
	end
	#open the file...
	f = File.open(file, "r")
	#and read all of it's lines
	lines = File.readlines(file)
	#counter to show the number of the current line
	counter = 1
	#show if the current file has any dependencies
	dependencyArray = Array.new()
	lines.each{
		|i|
		#remove newlines and make sure the encoding does not cause problems
		line = i.chomp.force_encoding("ISO-8859-1").encode("utf-8", replace=nil)
		#if it matches the style of the given include string
		if(line.lstrip().start_with?(includeString))
			if(isIteratable)
				dependency = line.sub(includeString, "").strip()
				removeRegex.each{
					|remove|
					dependency = dependency.sub(remove, "")
				}
				dependencyArray.push(dependency)
				puts "\t-> line " + counter.to_s + ": dependency to " + dependency
			else
				dependency = line.sub(includeString, "").sub(removeRegex, "").strip()
				dependencyArray.push(dependency)
				puts "\t-> line " + counter.to_s + ": dependency to " + dependency
			end
		end
		counter+=1
	}
	if(dependencyArray.length() == 0)
		puts "\t-> this file has no dependencies"
	end
	$projectDependencies[file] = dependencyArray
	f.close()
end

def scanCAndCPP(file)
	scan(file, "#include", /\s+[\/][\/].+/)
end

def scanJava(file)
	scan(file, "import", [/\s+[\/][\/].*/, ";"])
end

def scanRuby(file)
	scan(file, "require", /\s+[#].*/)
end

def scanPython(file)
	scan(file, "import", /\s+[#].*/)
end

def checkDependencies(directories)
	directories.each{
		|directory|
		#if the passed directory exists
		if(Dir.exist?(directory))
			#get a list of files and directories
			fileList = Dir.entries(directory)
			#and go through all of them
			fileList.each{
				|i|
				#attach the directory location at the beginning of the file
				input = directory + File::SEPARATOR + i
				#if it is a file, it could be one worth checking
				if(File.file?(input))
					#and readable...
					if(File.readable?(input))
						#if it is a header for C or C++...
						if(File.extname(input) == ".h" or File.extname(input) == ".hpp")
							#then scan it for it's dependencies
							puts "Scanning dependencies of file " + input
							scanCAndCPP(input)
						#or a C or C++ source code file
						elsif(File.extname(input) == ".c" or File.extname(input) == ".cpp")
							#then scan it for it's dependencies
							puts "Scanning dependencies of file " + input
							scanCAndCPP(input)
						elsif(File.extname(input) == ".java")
							#then scan it for it's dependencies
							puts "Scanning dependencies of file " + input
							scanJava(input)
						elsif(File.extname(input) == ".rb")
							#then scan it for it's dependencies
							puts "Scanning dependencies of file " + input
							scanRuby(input)
						elsif(File.extname(input) == ".py")
							#then scan it for it's dependencies
							puts "Scanning dependencies of file " + input
							scanPython(input)
						else
							#or skip it
							puts "Skipping file " + input
						end
					else
						#else say it is not possible to read it
						puts "Can't read file " + input
					end
				#if it is a directory, check the subdirectories
				elsif(File.directory?(input) and not (i == "." or i == ".." or i.start_with?(".")))
					puts "Checking directory " + input
					checkDependencies(Array.new(1, input))
				end
			}
		else
			#if the directory cannot be found
			puts "Directory " + directory + " does not exist"
		end
	}
end

#the directory, in which the files will be scanned for their dependencies
checkDependencies(ARGV)