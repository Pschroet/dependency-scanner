dependency-scanner
==================

This project aims to create a dependency scanner for various programming languages.
It searches files of a project for it's dependencies and lists them, to give an overview on projects.

Supported programming languages and file extensions so far:
- C: .h, .c
- C++: .hpp, .cpp
- Java: .java
- Ruby: .rb
- Python: .py


Usage:
ruby Scanner.rb [OPTIONS] <directory-or-file-to-be-scanned> [<directory-or-file-to-be-scanned> ...]

Possible options are:
- -s [FILE], --save [FILE]

Saves the dependencies into file FILE

- -q, --quiet

Suppresses all output

- -x [FILE], --xml [FILE]

Saves dependencies into a XML formatted file

- -v, --verbose

Generates additional output
