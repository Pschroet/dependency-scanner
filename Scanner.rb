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

def checkFileExtension(inputFile)
	#if it is a header or source code file for C or C++...
	if(File.extname(inputFile) == ".h" or File.extname(inputFile) == ".hpp" or File.extname(inputFile) == ".c" or File.extname(inputFile) == ".cpp")
		#then scan it for it's dependencies
		puts "Scanning dependencies of file " + inputFile
		scan(inputFile, "#include", /\s+[\/][\/].+/)
	#or a Java source code file
	elsif(File.extname(inputFile) == ".java")
		#then scan it for it's dependencies
		puts "Scanning dependencies of file " + inputFile
		scan(inputFile, "import", [/\s+[\/][\/].*/, ";"])
	#or a Ruby source code file
	elsif(File.extname(inputFile) == ".rb")
		#then scan it for it's dependencies
		puts "Scanning dependencies of file " + inputFile
		scan(inputFile, "require", /\s+[#].*/)
	#or a Python source code file
	elsif(File.extname(inputFile) == ".py")
		#then scan it for it's dependencies
		puts "Scanning dependencies of file " + inputFile
		scan(inputFile, "import", /\s+[#].*/)
	#if it is not a supported file, skip it
	else
		puts "Skipping file " + inputFile
	end
end
	
def checkDependencies(args)
	args.each{
		|input|
		#if the passed input is an existing directory
		if(Dir.exist?(input))
			#get a list of files and directories
			fileList = Dir.entries(input)
			#and go through all of them
			fileList.each{
				|i|
				#attach the directory location at the beginning of the file
				fileListElement = input + File::SEPARATOR + i
				#if it is a file, it could be one worth checking
				if(File.file?(fileListElement))
					#and readable...
					if(File.readable?(fileListElement))
						checkFileExtension(fileListElement)
					else
						#else say it is not possible to read it
						puts "Can't read file " + fileListElement
					end
				#if it is a directory, check the subdirectories
				elsif(File.directory?(fileListElement) and not (i == "." or i == ".." or i.start_with?(".")))
					puts "Checking directory " + fileListElement
					checkDependencies(Array.new(1, fileListElement))
				end
			}
		#if it is an existing  file
		elsif(File.exist?(input))
			checkFileExtension(input)
		else
			#if the directory or file cannot be found
			puts "Directory " + input + " does not exist"
		end
	}
end

#the directory, in which the files will be scanned for their dependencies
checkDependencies(ARGV)