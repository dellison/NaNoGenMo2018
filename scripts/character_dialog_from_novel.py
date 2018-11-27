import argparse
import os
import re

SAID_WORDS = {
    'said',
    'remarked',
    'exclaimed',
    'asked',
    'answered',
    'replied',
    'cried'
}

SAID_RX = re.compile(r'(' + r'|'.join([r'\b'+word+r'\b' for word in SAID_WORDS]) + r')',
                     re.IGNORECASE)

def getargs():
    ap = argparse.ArgumentParser(description='')
    ap.add_argument('--input-file', help='', required=True)
    ap.add_argument('--character-name', help='', required=True)
    return ap.parse_args()

def find_dialog(text, name):
    name = name.lower()
    name_said = re.compile(SAID_RX.pattern + r'\s+' + name + \
                           r'|' + name + r'\s' + SAID_RX.pattern)
    for paragraph in re.split(r'\n\n+', text):
        para = paragraph.lower().replace('\n', ' ')
        if name in para and re.search(SAID_RX, para) is not None:
            if re.search(name_said, para) is not None:
                yield paragraph.replace('\n', ' ')
                

def main():
    args = getargs()
    if not os.path.isfile(args.input_file):
        raise(ArgumentError(f'input file {args.input_file} does not exist!'))

    with open(args.input_file) as f:
        for paragraph in find_dialog(f.read(), args.character_name):
            print(paragraph)
            

    
if __name__ == '__main__':
    main()
