require "optparse"
require "pathname"

#this hash object collects all the dependencies of the project files, the keys are the file names
$projectDependencies = Hash.new()
$save2File = false
$file = ""
$save2XML = true
$xmlFile = ""
$xmlText = ""
$options = {}
$quiet = false
$verbose = false

#echos the given output, if output in general is not prevented by using '-q' or '--quiet'
#some messages will be filtered out (when the method is called with true as second argument)
# if the global variable verbose is set to false
def putOut(output, isVerbose=true)
	if((!$quiet && !isVerbose) || (isVerbose && $verbose))
		puts output
	end
	if($save2File)
		$file.write("[" + Time.now.to_s + "] " + output + $/)
	end
end

def writeDependencies2XML()
  if($save2XML)
    $xmlFile.write($xmlText)
  end
end

#check if an object is iterable
# returns true, if the given object responds to 'each'
# returns false, otherwise
def isIterable(input)
	if(input.respond_to?(:each))
		return true
	else
		return false
	end
end

#scan the given file for the include string line by line
# removeRegex can be a string as well as an iterable object
# - removeRegex can be used for parts of the include that are not part of the include keyword, but need to be removed to get
#  only the dependency itself
def scan(file, includeString, removeRegex=nil)
	#check which of the regex strings can be iterated, e. g. in removeRegex when semicolons and comments need to be removed
	includeStringIsIteratable = isIterable(includeString)
	if(removeRegex != nil && removeRegex != "")
	  removeRegexIsIteratable = isIterable(removeRegex)
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
			#if there is more than one keyword to be removed, remove them one after another
		  if(removeRegexIsIteratable)
				dependency = line.sub(includeString, "").strip()
				removeRegex.each{
					|remove|
					dependency = dependency.sub(remove, "")
				}
				dependencyArray.push(dependency)
				putOut("\t-> line " + counter.to_s + ": dependency to " + dependency + ifLine, false)
        $xmlText += "<Dependency><File name=\"" + dependency + "\"></File></Dependency>" + $/
      #if there is only one keyword, just remove it
			else
				dependency = line.sub(includeString, "").sub(removeRegex, "").strip()
				dependencyArray.push(dependency)
				putOut("\t-> line " + counter.to_s + ": dependency to " + dependency + ifLine, false)
        $xmlText += "<Dependency><File name=\"" + dependency + "\"></File></Dependency>" + $/
			end
		end
		counter+=1
	}
	if(dependencyArray.length() == 0)
		putOut("\t-> this file has no dependencies", false)
	end
	$projectDependencies[file] = dependencyArray
	f.close()
end

#checks if the given file is supported and if it is, then it will be scanned for dependencies
def checkFileExtension(inputFile)
	#if it is a header or source code file for C or C++...
	if(File.extname(inputFile) == ".h" or File.extname(inputFile) == ".hpp" or File.extname(inputFile) == ".c" or File.extname(inputFile) == ".cpp")
		#then scan it for it's dependencies
		putOut("Scanning dependencies of file " + inputFile, false)
		$xmlText += "<File name=\"" + inputFile + "\" type=\"" + File.extname(inputFile) + "\">" + $/
		scan(inputFile, "#include", /\s+[\/][\/].+/)
		$xmlText += "</File>" + $/
	#or a Java source code file
	elsif(File.extname(inputFile) == ".java")
		#then scan it for it's dependencies
		putOut("Scanning dependencies of file " + inputFile, false)
    $xmlText += "<File name=\"" + inputFile + "\" type=\"" + File.extname(inputFile) + "\">" + $/
		scan(inputFile, "import", [/\s+[\/][\/].*/, ";"])
    $xmlText += "</File>" + $/
	#or a Ruby source code file
	elsif(File.extname(inputFile) == ".rb")
		#then scan it for it's dependencies
		putOut("Scanning dependencies of file " + inputFile, false)
    $xmlText += "<File name=\"" + inputFile + "\" type=\"" + File.extname(inputFile) + "\">" + $/
		scan(inputFile, "require", /\s+[#].*/)
    $xmlText += "</File>" + $/
	#or a Python source code file
	elsif(File.extname(inputFile) == ".py")
		#then scan it for it's dependencies
		putOut("Scanning dependencies of file " + inputFile, false)
    $xmlText += "<File name=\"" + inputFile + "\" type=\"" + File.extname(inputFile) + "\">" + $/
		scan(inputFile, "import", /\s+[#].*/)
    $xmlText += "</File>" + $/
	#if it is not a supported file, skip it
	else
		putOut("Skipping file " + inputFile, true)
	end
end

#goes through the given directories and if files are found, they will be passed to 'checkFileExtension'
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
					fileListElement = Pathname.new(input + File::SEPARATOR + i).realpath.to_s
					#if it is a file, it could be one worth checking
					if(File.file?(fileListElement))
						#and readable...
						if(File.readable?(fileListElement))
							checkFileExtension(fileListElement)
						else
							#else say it is not possible to read it
							putOut("Can't read file " + fileListElement, false)
						end
					#if it is a directory, check the subdirectories
					elsif(File.directory?(fileListElement) and not (i == "." or i == ".." or i.start_with?(".")))
						putOut("Checking directory " + fileListElement, false)
						checkDependencies(Array.new(1, fileListElement))
					end
				}
			#if it is an existing  file
			elsif(File.exist?(input))
				checkFileExtension(input)
			else
				#if the directory or file cannot be found
				putOut("Directory " + input + " does not exist", false)
			end
		}
	end
  if($save2XML)
    writeDependencies2XML()
  end
end

#parse the arguments, looks for the following
# -s and --save: output will be saved into a file
# -q and --quiet: output will not be shown on the console
# -v and --verbose: fewer output will be shown (only those with false as second argument in putOut)
def parse(args)
  #add the possible arguments to the argument parser
	opt_parser = OptionParser.new do |opts|
		opts.banner = "Usage: Scanner.rb [options] file [files...]"
		opts.on("-s [FILE]", "--save [FILE]", "Saves to file [FILE]") do |file|
			$save2File = true
			$file = File.new(Pathname.new(file).realpath,  "w+")
		end
    opts.on("-x [FILE]", "--xml [FILE]", "Saves to XML file [FILE]") do |file|
      $save2XML = true
      $xmlFile = File.new(Pathname.new(file).realpath,  "w+")
    end
		opts.on("-q", "--quiet", "Do not show output on console") do
			$quiet = true
		end
    opts.on("-v", "--verbose", "Show additional output on the console, overwrites quiet") do
      $verbose = true
    end
	end
	#start the parsing of the arguments
	opt_parser.parse!(args)
end

#parse the given options
$options = parse(ARGV)
#announce if the output should be saved into a file, but only if the program does not run quietly
if($save2File)
	putOut("Writing to file " + File.absolute_path($file), false)
	if(File.file?($file))
		putOut("-> exists and will be overwritten", true)
	end
end

if($save2XML)
  putOut("Writing XML formatted to file " + File.absolute_path($xmlFile), false)
  if(File.file?($xmlFile))
    putOut("-> exists and will be overwritten", true)
  end
end
#run through the given files and directories
checkDependencies($options)