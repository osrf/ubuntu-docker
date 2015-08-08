#!/usr/bin/env python3

import os
import subprocess
import sys
import yaml

from argparse import ArgumentParser
from collections import OrderedDict


class DockerfileArgParser(ArgumentParser):
    """Argument parser class Dockerfile auto generation"""

    def set(self):
        """Setup parser for Dockerfile auto generation"""

        # create the top-level parser
        subparsers = self.add_subparsers(help='help for subcommand', dest='subparser_name')

        # create the parser for the "explicit" command
        parser_explicit = subparsers.add_parser(
            'explicit',
            help='explicit --help')
        parser_explicit.add_argument(
            '-c', '--config',
            required=True,
            help="Path to platform config")
        parser_explicit.add_argument(
            '-o', '--output',
            required=True,
            help="Path to write generate Dockerfiles")

        # create the parser for the "dir" command
        parser_dir = subparsers.add_parser(
            'dir',
            help='dir --help')
        parser_dir.add_argument(
            '-d', '--directory',
            required=True,
            help="Path to read config and write output")


def main(argv=sys.argv[1:]):
    """Make docker images form yaml config"""

    # Create the top-level parser
    parser = DockerfileArgParser(
        description="Generate the 'Dockerfile's for the base docker images")
    parser.set()
    args = parser.parse_args(argv)

    # If paths were given explicitly
    if args.subparser_name == 'explicit':
        config_path = args.config
        output_path = args.output

    # Else just use the given directory path
    elif args.subparser_name == 'dir':
        config_path = 'config.yaml'
        config_path = os.path.join(args.directory, config_path)
        output_path = args.directory

    # Read config perams
    with open(config_path, 'r') as f:
        # use safe_load instead load
        config = yaml.safe_load(f)

    # For each image tag
    for arch_name, arch in config['architectures'].items():
        for suite in arch['suites']:
            print('suite:', suite)
            tag_name = arch_name + ":" + suite
            core_name = "ubuntu_core_" + tag_name
            image_name = "ubuntu_" + tag_name
            core_repo_name = config['username'] + "/" + core_name
            image_repo_name = config['username'] + "/" + image_name

            if(config['build_core']):
                cmd = ["./build_core.sh",
                       "--arch", arch_name,
                       "--suite",
                       suite]
                if(config['dry']):
                    print('cmd:', " ".join(cmd))
                else:
                    subprocess.check_call(cmd)
            if(config['push_core']):
                cmd = ["docker",
                       "tag",
                       core_name,
                       core_repo_name]
                if(config['dry']):
                    print('cmd:', " ".join(cmd))
                else:
                    subprocess.check_call(cmd)
                cmd = ["docker push",
                       core_repo_name]
                if(config['dry']):
                    print('cmd:', " ".join(cmd))
                else:
                    subprocess.check_call(cmd)
            if(config['build_image']):
                cmd = ["docker",
                       "build",
                       "--tag",
                       image_repo_name,
                       arch_name + "/" + suite + "/."]
                if(config['dry']):
                    print('cmd:', " ".join(cmd))
                else:
                    subprocess.check_call(cmd)
            if(config['push_image']):
                cmd = ["docker",
                       "push",
                       image_repo_name]
                if(config['dry']):
                    print('cmd:', " ".join(cmd))
                else:
                    subprocess.check_call(cmd)

if __name__ == '__main__':
    main()
