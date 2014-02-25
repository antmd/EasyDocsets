DocSet Generator plus TomDoc Converter
---
A set of Python and shell scripts to generate appledoc and Doxygen docsets easily, including a TomDoc converter

    Usage :  ./generate_docs.sh -s <dir> -x <path> -f <name> -c <name> -d <name>
    Options: 
        -s <dir>      The directory containing the source header files
        -x <path>     The path to the index page
        -f <name>     The name of the framework (appears on doc pages)
        -c <name>     The company/organisation name
        -d <name>     The company id in the format 'com.dervishsoftware'
        -t appledoc|doxygen  The output type (default = appledoc)
        -h            Display this message
        -a            Turn on TomDoc conversion (e.g. for ReactiveCocoa). This can sometimes help for code that
                      hasn't been commented with special Documentation comments (/** */, ///, etc.)


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
    generate_docs.sh -s ReactiveCocoaFramework/ReactiveCocoa -c "GitHub" -d com.github -a -t appledoc


