import os, re, glob

def extract_string_or_table(s, key):
    # find key = "value" or key = { ... }
    pat = re.compile(r'\b' + re.escape(key) + r'\s*=\s*"([^"]*)"', re.S)
    m = pat.search(s)
    if m:
        return m.group(1)
    return None

def parse_entry_block(block):
    out = {}
    for k in ['id','name','desc','category','points','icon']:
        out[k] = extract_string_or_table(block, k)
    if out.get('points'):
        try: out['points'] = int(out['points'])
        except: pass
    return out

files = glob.glob(os.path.join(os.path.dirname(__file__), '*.lua')) + glob.glob(os.path.join(os.path.dirname(__file__), 'data', '*.lua'))
all = []
for f in files:
    with open(f, 'r', encoding='utf-8', errors='ignore') as fp:
        text = fp.read()
    # AddAchievement("id", { ... })
    for m in re.finditer(r'AddAchievement\s*\(\s*"([^"]+)"\s*,\s*\{', text):
        start = m.end() - 1
        # find matching brace
        i = start + 1
        depth = 1
        while i < len(text) and depth > 0:
            if text[i] == '{': depth += 1
            elif text[i] == '}': depth -= 1
            # skip strings naively
            elif text[i] == '"' and text[i-1] != '\\':
                i += 1
                while i < len(text) and not (text[i] == '"' and text[i-1] != '\\'):
                    i += 1
            i += 1
        block = text[start:i]
        e = parse_entry_block(block)
        e['file'] = os.path.basename(f)
        if e.get('name') or e.get('desc'):
            all.append(e)

# Also central ACHIEVEMENTS table entries
main = os.path.join(os.path.dirname(__file__), 'LeafVillageAchievements.lua')
if os.path.exists(main):
    with open(main, 'r', encoding='utf-8', errors='ignore') as fp:
        text = fp.read()
    m = re.search(r'local ACHIEVEMENTS = \{', text)
    if m:
        start = m.end()
        # find the matching closing brace
        i = start
        depth = 1
        while i < len(text) and depth > 0:
            c = text[i]
            if c == '{': depth += 1
            elif c == '}': depth -= 1
            elif c == '"':
                # skip string
                i += 1
                while i < len(text) and not (text[i] == '"' and text[i-1] != '\\'):
                    i += 1
            i += 1
        block = text[start:i]
        # top-level key=value entries
        for m in re.finditer(r'\n\s+([a-zA-Z0-9_]+)=\{', block):
            key = m.group(1)
            e = parse_entry_block(block[m.start():])
            e['id'] = key
            e['file'] = 'LeafVillageAchievements.lua'
            all.append(e)

print('Total parsed:', len(all))
by_cat = {}
for a in all:
    c = a.get('category') or a.get('cat') or 'Unknown'
    by_cat.setdefault(c, []).append(a)
for c in sorted(by_cat):
    print('\n=== %s (%d) ===' % (c, len(by_cat[c])))
    for a in by_cat[c][:40]:
        print('  %s - %s - %s (%s pts)' % (a.get('id',''), a.get('name',''), a.get('desc',''), a.get('points','?')))
    if len(by_cat[c]) > 40:
        print('  ... and', len(by_cat[c])-40, 'more')
