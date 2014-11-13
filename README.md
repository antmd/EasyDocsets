DocSet Generator plus TomDoc Converter
---
A set of Python and shell scripts to generate appledoc and Doxygen docsets easily, including a TomDoc converter

    usage: generate_docs.py [-h] [-o [OUTPUT]] [-i INDEX] -n NAME [-c COMPANY]
                            [-d COMPANY_ID] [-t] [-x] [-g {appledoc,doxygen}]
                            [-f {docset,html}] [-s] [-l {c++,objc,all}]
                            [--dot-path DOT_PATH]
                            srcdir
    
    positional arguments:
      srcdir                Directory containing the source header files
    
    optional arguments:
      -h, --help            show this help message and exit
      -o [OUTPUT], --output [OUTPUT]
                            Directory for the generated docs
      -i INDEX, --index INDEX
                            Path to the index page
      -n NAME, --name NAME  The name of the docset (appears on the doc pages)
      -c COMPANY, --company COMPANY
                            The name of the company owning the source
      -d COMPANY_ID, --company-id COMPANY_ID
                            The id of the company in reverse-DNS style
      -t, --tomdoc          Turn on TomDoc conversion of input files
      -x, --translate       Simple conversion of non-doc comments to doc-comments
      -g {appledoc,doxygen}, --generator {appledoc,doxygen}
                            The output generator
    
    doxygen-only arguments:
      Options to customise doxygen output
    
      -f {docset,html}, --format {docset,html}
                            Output format
      -s, --source          Include source browser
      -l {c++,objc,all}, --language {c++,objc,all}
                            Force the language
      --dot-path DOT_PATH   The path to "dot" for doxygen. Default is binary found
                            on PATH.



Generating the DocSet for a code-base can be a little tricky. For AppleDoc, you have to remember the long list of command-line options. For Doxygen, you need to edit a configuration file for each source tree to get the best results.

These scripts make it easier to generate DocSets, given a few simple command-line options.

### Appledoc

To generate appledoc docsets, you will need to install [appledoc](http://gentlebytes.com/appledoc/)

I made a couple of changes to appledoc to make it skip deprecated symbols, and to prevent it auto-linking to common English words

An updated version of appledoc is here: https://github.com/antmd/appledoc . This should be merged to the parent repository https://github.com/tomaz/appledoc soon.

You can use the 'brew' version of appledoc, but you'll get extra spurious hyperlinks in the output. The script to generate documentation checks for the presence of the extra command-line options.

This will install the docset in `~/Library/Developer/Shared/Documentation/DocSets`, and it will be available immediately in Xcode.

### Doxygen

The doxygen output draws nice inheritance and collaboration diagrams, but usually takes a lot longer to generate (minutes).

By default, the output will include inheritance and collaboration graphs. If necessary, Doxygen output can be customised by changing the 'DocSet.Doxygen' file in the 'doxygen-templates' sub-directory, and the new format will be used for all further generated DocSets.

Output will be installed as a DocSet

### Example

To generate the ReactiveCocoa DocSet using appledoc:

    cd ReactiveCocoa
    generate_docs.py -s ReactiveCocoaFramework/ReactiveCocoa -c "GitHub" -d com.github -t -g appledoc


