import sys, re
content = open(sys.argv[1]).read()
content = re.sub(r'(\d+)u', r'\1', content)
open(sys.argv[2], 'w').write(content)
