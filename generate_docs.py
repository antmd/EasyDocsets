#!/usr/bin/env python
from __future__ import print_function

__author__ = 'Whirliwig'
__license__ = 'MIT'
__version__ = '0.5'
__email__ = 'ant@dervishsoftware.com'

from os import path, chdir, listdir, walk, putenv
import shutil
import sys
import tomdoc_converter_objc
import subprocess
from tomdoc_converter_objc import OutputGenerator, InputTranslator
script_path = path.dirname(path.realpath(__file__))
# Add 'Python' in the same directory as this script to sys.path
sys.path.append(path.join(script_path, "Python"))

import argparse
import distutils
from tempfile import mkdtemp
from pprint import pprint as pp

def which(program):
    import os
    def is_exe(fpath):
        return os.path.isfile(fpath) and os.access(fpath, os.X_OK)

    fpath, fname = os.path.split(program)
    if fpath:
        if is_exe(program):
            return program
    else:
        for path in os.environ["PATH"].split(os.pathsep):
            path = path.strip('"')
            exe_file = os.path.join(path, program)
            if is_exe(exe_file):
                return exe_file

    return None

doxygen_binary=which('doxygen')
appledoc_binary=which('appledoc')

def convert_tomdoc(input_dir, temp_dir, translator, generator):
    src_dirs = [x[0] for x in walk(input_dir)]
    tomdoc_converter_objc.generate(src_dirs, temp_dir, translator, generator, False)



def bool_str(truthy):
    if truthy:
        return 'YES'
    else:
        return 'NO'


def generate_docs(doxygen_templates_dir, args):
    temp_dir = mkdtemp('','gendocs.')
    print("doxygen = {}, appledoc = {}".format(doxygen_binary, appledoc_binary))

    # Pre-requisites
    if args.generator == 'appledoc':
        if not appledoc_binary:
            print("Cannot find appledoc binary.", file=sys.stderr)
            exit(1)
        generator = OutputGenerator.appledoc
    elif args.generator == 'doxygen':
        if not doxygen_binary:
            print("Cannot find doxygen binary.", file=sys.stderr)
            exit(1)
        generator = OutputGenerator.doxygen

    company_name = args.company
    if not company_name: company_name = 'unknown'
    company_id=args.company_id
    if not company_id: company_id = '.'.join(['com', company_name])

    docset_name = args.name
    docset_id = '.'.join([company_id, args.name])

    src_dir = args.srcdir
    index_path = args.index
    dot_path = args.dot_path
    output_dir = args.output
    if not output_dir:
        output_dir = path.join(temp_dir,'doc')
    doxygen_template = path.extsep.join([args.format, args.language, 'Doxyfile'])
    source_browser_yn = bool_str(args.source)

    print('Docset =',docset_id)

    """
    Convert headers from Tomdoc, if required
    """
    if args.tomdoc or args.translate:
        if args.tomdoc:
            header_translator = InputTranslator.tomdoc
        else:
            header_translator = InputTranslator.simple
        print("Converting headers in", src_dir)
        if (index_path):
            shutil.copy(index_path, temp_dir)
        reformatted_headers_dir = path.join(temp_dir, 'reformatted_headers')
        convert_tomdoc(src_dir, reformatted_headers_dir, header_translator, generator)
        src_dir = reformatted_headers_dir


    if generator == OutputGenerator.appledoc:
        """
        Appledoc
        """
        print("Generating appledoc in",temp_dir)
    elif generator == OutputGenerator.doxygen:
        """
        Doxygen
        """
        print("Generating doxygen in",temp_dir)
        if dot_path:
            if not path.exists(dot_path):
                print("Cannot find dot at {}".format(dot_path), file=sys.stderr)
                exit(1)
        else:
            dot_path = which('dot')
            if not dot_path:
                print("Cannot find dot on PATH. Will not generate diagrams")

        if dot_path:
            putenv('DOT_PATH', dot_path)
            putenv('HAVE_DOT', 'YES')
        else:
            putenv('HAVE_DOT', 'NO')
        putenv('INPUT_DIR', '"{}"'.format(src_dir))
        putenv('HTML_HEADER','')
        putenv('DOCSET_PUBLISHER_ID', company_id)
        putenv('DOCSET_PUBLISHER', company_name)
        putenv('DOCSET_BUNDLE_ID', docset_id)
        putenv('FRAMEWORK', docset_name)
        putenv('OUTPUT_DIRECTORY', output_dir)
        putenv('SOURCE_BROWSER', source_browser_yn)

        """
    TODO
    # Generate the index page
    pushd "${GeneratedHeadersDir}" >/dev/null 2>&1
    cat > mainpage.h <<-EOF
    /*! \\mainpage ${FRAMEWORK} Main Page
     *
EOF
    if [[ ! -z "$INDEX_FILE" ]]; then
        cat < "../${INDEX_FILE}" >> mainpage.h
    fi
    cat >> mainpage.h <<-EOF
    */
EOF
    popd >/dev/null 2>&1
        """

        try:
            subprocess.check_call([doxygen_binary, path.join(doxygen_templates_dir, doxygen_template)])
            subprocess.check_call("cd {} && make install".format(output_dir), shell=True)
        except subprocess.CalledProcessError as e:
            print("Doxygen failed with error".format(e), file=sys.stderr)


    # Clean-up temporary directory
    #shutil.rmtree(temp_dir)


def parse_args(doxygen_templates):
    arg_parser = argparse.ArgumentParser()
    arg_parser.add_argument('srcdir', help='Directory containing the source header files', default = '.')
    arg_parser.add_argument('-o', '--output', help='Directory for the generated docs', nargs='?')
    arg_parser.add_argument('-i', '--index', help='Path to the index page', required=False)
    arg_parser.add_argument('-n', '--name', help='The name of the docset (appears on the doc pages)', required=True)
    arg_parser.add_argument('-c', '--company', help='The name of the company owning the source', required=False)
    arg_parser.add_argument('-d', '--company-id', help='The id of the company in reverse-DNS style', required=False)
    arg_parser.add_argument('-t', '--tomdoc', help='Turn on TomDoc conversion of input files', action='store_true')
    arg_parser.add_argument('-x', '--translate', help='Simple conversion of non-doc comments to doc-comments', action='store_true')
    arg_parser.add_argument('-g', '--generator', help='The output generator', choices=['appledoc', 'doxygen'], default='appledoc')
    doxygen_group = arg_parser.add_argument_group('doxygen-only arguments', 'Options to customise doxygen output')
    doxygen_group.add_argument('-f', '--format', help='Output format', choices=['docset', 'html'], default='docset', required=False)
    doxygen_group.add_argument('-s', '--source', help='Include source browser', action='store_true', required=False)
    doxygen_group.add_argument('-l', '--language', help='Force the language', choices=['c++', 'objc', 'all'], default='all', required=False)
    doxygen_group.add_argument('--dot-path', help='The path to "dot" for doxygen. Default is binary found on PATH.', required=False)



    args = arg_parser.parse_args()
    return args


def get_doxygen_templates(template_dir):
    return [path.splitext(t)[0] for t in listdir(path.abspath(template_dir))]


if __name__ == '__main__':
    doxygen_templates_dir = path.join(script_path,'doxygen-templates')
    doxygen_templates = get_doxygen_templates(doxygen_templates_dir)
    args = parse_args(doxygen_templates)
    generate_docs(doxygen_templates_dir, args)

