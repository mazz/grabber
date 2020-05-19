#!/usr/bin/env python

import argparse
import sys
import http.client
import json
import os
import subprocess

class Stream(object):
    def __init__(self):
        parser = argparse.ArgumentParser(
            description='stream a file to a streaming service',
            usage='''ytchanneldata <channel_url>

''')
        parser.add_argument('command', help='Subcommand to run')
        # parse_args defaults to [1:] for args, but you need to
        # exclude the rest of the args too, or validation will fail
        args = parser.parse_args(sys.argv[1:2])
        if not hasattr(self, args.command):
            print('Unrecognized command')
            parser.print_help()
            exit(1)
        # use dispatch pattern to invoke method with same name
        getattr(self, args.command)()

    def ytchanneldata(self):
        parser = argparse.ArgumentParser(
            description='youtube channel to get metadata')
        # prefixing the argument with -- means it's optional
        # parser.add_argument('dir')
        parser.add_argument('channel_url')
        # now that we're inside a subcommand, ignore the first
        # TWO argvs, ie the command (git) and the subcommand (commit)
        args = parser.parse_args(sys.argv[2:])
        # print('Running stream, dir: {}'.format(repr(args.dir)))

        # video_files = Stream.walk_folder(args.dir)
        # print('video_files: {}'.format(repr(video_files)))

        # item = 0
        # while len(video_files) > 0:
        #     print('len(video_files): {}'.format(repr(len(video_files))))
            
        #     f = video_files[item]
        #     # subprocess.call(['ffmpeg', '-i', f, '-f', 'mpegts', 'udp://127.0.0.1:23000'])

        # youtube-dl/youtube-dl --config-location youtube-dl.conf
        # subprocess.call(['ffmpeg', '-re', '-i', f, '-c', 'copy', '-bsf:a', 'aac_adtstoasc', '-f', 'flv', args.channel_url])

        ## ~~ downloads channel/video ~~ ##
        # subprocess.call(['youtube-dl/youtube-dl', '-i', '-o', '\"%(uploader)s-(%(uploader_id)s)/%(upload_date)s-%(title)s-(%(duration)ss)-[%(resolution)s]-[%(id)s].%(ext)s\"', args.channel_url])

        subprocess.call(['youtube-dl/youtube-dl', '-i', '-j', '--no-check-certificate', '--skip-download', args.channel_url])

        # youtube-dl/youtube-dl -v --no-check-certificate --restrict-filenames --format "bestvideo[vcodec^=avc1]+bestaudio[ext=m4a]/bestvideo+bestaudio/best" --output "%(uploader)s-(%(uploader_id)s)/%(upload_date)s-%(title)s-(%(duration)ss)-[%(resolution)s]-[%(id)s].%(ext)s" "https://www.youtube.com/watch?v=CLxpgRqxtEA" 



        #     item = item + 1
        #     if item == len(video_files):
        #         item = 0
        #     print('item: {}', repr(item))

    @staticmethod
    def walk_folder(media_dir):
        print('walk_folder media_dir: {}'.format(repr(media_dir)))
        print('os.path.abspath(f): {}'.format(repr(os.path.abspath(media_dir))))

        all_file_paths = Stream._get_filepaths(os.path.abspath(media_dir))
        ts_paths = []
        for f in all_file_paths:
            if f.endswith('.ts') or f.endswith('.mp4'):
                ts_paths.append(f)
                print('output_name: {}'.format(f))
                basename = os.path.basename(f)
                print('basename: {}'.format(basename))
        return sorted(ts_paths, key=lambda i: os.path.splitext(os.path.basename(i))[0])

    def _get_filepaths(directory):
        """
        This function will generate the file names in a directory
        tree by walking the tree either top-down or bottom-up. For each
        directory in the tree rooted at directory top (including top itself),
        it yields a 3-tuple (dirpath, dirnames, filenames).
        """
        file_paths = []  # List which will store all of the full filepaths.

        # Walk the tree.
        for root, directories, files in os.walk(directory):
            for filename in files:
                # Join the two strings in order to form the full filepath.
                filepath = os.path.join(root, filename)
                file_paths.append(filepath)  # Add it to the list.

        return file_paths # Self-explanatory.

    @staticmethod
    def _get_url(base, path, headers) -> str:
        print('_get_url: {} {}'.format(repr(base), repr(headers)))
        conn = http.client.HTTPConnection(base)
        conn.connect()
        conn.request('GET', path)
        response = conn.getresponse()
        data = response.read()
        response_string = data.decode('utf-8')
        print('response_string: {}'.format(repr(response_string)))

        conn.close()
        return response_string

    @staticmethod
    def _post_url(base, path, headers, body) -> json:
        print('_post_url: {} {} {}'.format(repr(base), repr(headers), repr(body)))

        conn = http.client.HTTPConnection(base)
        conn.request("POST", path, body, headers)
        # conn.request("POST", "/request?foo=bar&foo=baz", headers)

        res = conn.getresponse()
        data = res.read()

        response_string = data.decode('utf-8')
        result = json.loads(response_string)
        print('result: {}'.format(repr(result)))
        conn.close()
        
        return result

if __name__ == '__main__':
    Stream()
