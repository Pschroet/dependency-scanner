require 'optparse'

#this hash object collects all the dependencies of the project files, the keys are the file names
$projectDependencies = Hash.new()
$save2File = false
$file
$options = {}

def putOut(output)
	puts output
	if($save2File)
		$file.write(output + $/)
	end
end

def scan(file, includeString, removeRegex, situationStartRegex, situationEndRegex)
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
	ifLine = ""
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
				putOut("\t-> line " + counter.to_s + ": dependency to " + dependency + ifLine)
			else
				dependency = line.sub(includeString, "").sub(removeRegex, "").strip()
				dependencyArray.push(dependency)
				putOut("\t-> line " + counter.to_s + ": dependency to " + dependency + ifLine)
			end
		elsif(situationStartRegex != "" && line.lstrip().start_with?(situationStartRegex))
			ifLine = line.sub(situationStartRegex, " when")
		elsif(ifLine != "" && line.lstrip().start_with?(situationEndRegex))
			ifLine = ""
		end
		counter+=1
	}
	if(dependencyArray.length() == 0)
		putOut("\t-> this file has no dependencies")
	end
	$projectDependencies[file] = dependencyArray
	f.close()
end

def checkFileExtension(inputFile)
	#if it is a header or source code file for C or C++...
	if(File.extname(inputFile) == ".h" or File.extname(inputFile) == ".hpp" or File.extname(inputFile) == ".c" or File.extname(inputFile) == ".cpp")
		#then scan it for it's dependencies
		putOut("Scanning dependencies of file " + inputFile)
		scan(inputFile, "#include", /\s+[\/][\/].+/, "#ifdef", "#endif")
	#or a Java source code file
	elsif(File.extname(inputFile) == ".java")
		#then scan it for it's dependencies
		putOut("Scanning dependencies of file " + inputFile)
		scan(inputFile, "import", [/\s+[\/][\/].*/, ";"], "", "")
	#or a Ruby source code file
	elsif(File.extname(inputFile) == ".rb")
		#then scan it for it's dependencies
		putOut("Scanning dependencies of file " + inputFile)
		scan(inputFile, "require", /\s+[#].*/, "", "")
	#or a Python source code file
	elsif(File.extname(inputFile) == ".py")
		#then scan it for it's dependencies
		putOut("Scanning dependencies of file " + inputFile)
		scan(inputFile, "import", /\s+[#].*/, "", "")
	#if it is not a supported file, skip it
	else
		puts "Skipping file " + inputFile
	end
end

def checkDependencies(args)
	if(args.length < 1)
		puts "One or more files or directories must be given as arguments"
	else
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
end

def setSavingFile(file)
	$save2File = true
	if(File.file?(file))
		puts "Writing to existing file " + file + "\n-> will be overwritten"
	else
		puts "Writing to file " + file
	end
	$file = File.new(file,  "w+")
end

def parse(args)
	opt_parser = OptionParser.new do |opts|
		opts.banner = "Usage: Scanner.rb [options] file [files...]"
		opts.on("-s [FILE]", "--save [FILE]", "Saves to file [FILE]") do |file|
			#$options[:save] = file
			setSavingFile(file)
		end
	end
	opt_parser.parse!(args)
end

#the directory, in which the files will be scanned for their dependencies
#checkDependencies(ARGV)
$options = parse(ARGV)

checkDependencies($options)