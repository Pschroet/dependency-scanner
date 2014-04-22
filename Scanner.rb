#this hash object collects all the dependencies of the project files, the keys are the file names
$projectDependencies = Hash.new()

def scanCAndCPP(file)
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
		#if it matches the style of an include in C or C++
		if(line.start_with?("#include"))
			dependency = line.sub("#include", "").strip()
			dependencyArray.push(dependency)
			puts "\t-> line " + counter.to_s + " includes " + dependency
		end
		counter+=1
	}
	if(dependencyArray.length() == 0)
		puts "\t-> this file has no dependencies"
	end
	$projectDependencies[file] = dependencyArray
	f.close()
end

def scanJava(file)
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
		#if it matches the style of an import in Java
		if(line.start_with?("import"))
			dependency = line.sub("import", "").sub(";", "").strip()
			dependencyArray.push(dependency)
			puts "\t-> line " + counter.to_s + " imports " + dependency
		end
		counter+=1
	}
	if(dependencyArray.length() == 0)
		puts "\t-> this file has no dependencies"
	end
	$projectDependencies[file] = dependencyArray
	f.close()
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