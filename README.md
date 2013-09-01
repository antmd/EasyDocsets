TomDoc to Other Format Converter
---
A set of Python and shell scripts to generate appledoc and Doxygen from TomDoc commented code in C-like languages

Only tested with Objective-C.

    Usage :  ./generate_docs.sh -s <dir> -x <path> -f <name> -c <name> -d <name>
    Options: 
        -s <dir>      The directory containing the source header files
        -x <path>     The path to the index page
        -f <name>     The name of the framework (appears on doc pages)
        -c <name>     The company/organisation name
        -d <name>     The company id in the format 'com.dervishsoftware'
        -t appledoc|doxygen  The output type (default = appledoc)
        -h            Display this message


### Appledoc

To generate appledoc docsets, you will need to install [appledoc](http://gentlebytes.com/appledoc/)

I made a couple of changes to appledoc to make it skip deprecated symbols, and to prevent it auto-linking to common English words

An updated version of appledoc is here: https://github.com/antmd/appledoc . This should be merged to the parent repository https://github.com/tomaz/appledoc soon.

You can use the 'brew' version of appledoc, but you'll get extra spurious hyperlinks in the output. The script to generate documentation checks for the presence of the extra command-line options.

This will install the docset in `~/Library/Developer/Shared/Documentation/DocSets`, and it will be available immediately in Xcode.

### Doxygen

Doxygen output generates a folder 'html' in ~/Downloads

The doxygen output draws nice inheritance and collaboration diagrams.

Doxygen is supposed to be able to generate Apple DocSets, too, but I couldn't get it to work properly. I think it's a known issue.
