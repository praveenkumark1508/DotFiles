#!/home/praveen/anaconda3/bin/python
'''
Script to commit and push all the changes in the local repo
'''

import os
import sys
import pickle
from subprocess import call
import logging
import re


def get_timestamps(root_dir):
    '''
    Get the timestamp of all the files in the root_dir and return it in
    a dictionary.
    '''
    timestamp_dict = {}
    for root, folder, files in os.walk(root_dir):
        folder = folder
        for filename in files:
            timestamp_dict[os.path.join(root, filename)] = os.path.getmtime(
                os.path.join(root, filename))

    return timestamp_dict


def is_ignored(filename):
    '''
    Check if the filename is ignored or not
    '''
    for pattern in IGNORE_FILES:
        if re.match(pattern, filename):
            return True

    return False


def is_modified(timestamps_file, folderpath):
    '''
    find the modified files
    '''
    try:
        current_timestamps = get_timestamps(folderpath)
        old_timestamps = load_timestamp(timestamps_file)
    except FileNotFoundError:
        save_timestamps(current_timestamps, timestamps_file)
        return True

    state = False
    for filename in current_timestamps:
        try:
            if not is_ignored(filename):
                if current_timestamps[filename] != old_timestamps[filename]:
                    state = True
                    break
        except KeyError:
            state = True
            break

    save_timestamps(current_timestamps, timestamps_file)
    return state


def save_timestamps(timestamp_dict, filename):
    '''
    Save the timestamp_dict to a file
    '''
    with open(filename, 'wb') as pickle_file:
        pickle.dump(timestamp_dict, pickle_file)


def load_timestamp(pickle_filename):
    '''
    Load the timestamp_dict from a file
    '''
    with open(pickle_filename, 'rb') as pickle_file:
        return pickle.load(pickle_file)


def create_zip(zipfile_name, folder):
    '''
    Function to create zipfile splitted to 40MB size
    '''
    logging.info("Creating zipfile of %s", folder)
    call("zip -r {}.zip {} --out temp.zip".format(zipfile_name, folder),
         shell=True)

    logging.info("Deleting old zip file")
    call("rm -f {}.z*".format(zipfile_name), shell=True)

    logging.info("Renaming the zipfiles")
    for i in range(15):
        call("mv temp.z{:02d} {}.z{:02d} 2> /dev/null".format(
            i, zipfile_name, i), shell=True)
    call('mv temp.zip {}.zip'.format(zipfile_name), shell=True)


if __name__ == '__main__':
    logging.basicConfig(level=logging.INFO,
                        format="%(levelname)s : %(message)s")

    IGNORE_FILES = (r'.*\.sw?', r'.*\/\.vimundo\/\%.*',
                    r'.*\/\.vimbackup\/.*\~$', r'.*\=\+.*\=$',
                    r'.*\.cache\/.*')

    if len(sys.argv) == 1:
        COMMIT_MSG = "Adding many small misc changes"
    else:
        COMMIT_MSG = sys.argv[1]

    # Creating zipfile of .vim
    os.chdir("Vimrc")
    if is_modified('vimfiles.pkl', '.vim'):
        create_zip("vimfiles", ".vim")
    os.chdir("..")

    # Creating zipfile of .oh-my-zsh
    os.chdir("Zshrc")
    if is_modified('oh-my-zsh.pkl', '.oh-my-zsh'):
        create_zip("oh-my-zsh", ".oh-my-zsh")
    os.chdir("..")

    # Committing and pushing in git
    logging.info("Committing and pushing in git")
    call("git add *", shell=True)
    call('git commit -m {}'.format(COMMIT_MSG), shell=True)
    call('git push')
    print("Git push done")
