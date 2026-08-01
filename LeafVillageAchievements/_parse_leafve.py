import re, os, json

path = os.path.join(os.path.dirname(__file__), 'LeafVillageAchievements.lua')
with open(path, 'r', encoding='utf-8', errors='ignore') as f:
    text = f.read()

# Find ACHIEVEMENTS table start/end
m = re.search(r'local ACHIEVEMENTS = \{', text)
if not m:
    print('ACHIEVEMENTS table not found'); sys.exit()
start = m.end()
# find matching closing brace by counting braces
braces = 1
end = start
while end < len(text) and braces > 0:
    c = text[end]
    if c == '{': braces += 1
    elif c == '}': braces -= 1
    end += 1
block = text[start:end]

# Each entry is key={id="...", name="...", desc="...", category="...", points=N, icon="...", ...}
entries = []
# pattern for key={...} entries
for m in re.finditer(r'\s+([a-zA-Z0-9_]+)=\{id="([^"]+)"\s*,\s*name="([^"]+)"\s*,\s*desc="([^"]*)"\s*,\s*category="([^"]+)"\s*,\s*points=(\d+)', block):
    key = m.group(1)
    ach = {
        'id': m.group(2),
        'name': m.group(3),
        'desc': m.group(4),
        'category': m.group(5),
        'points': int(m.group(6)),
    }
    # look for progress/goal fields in the rest of the entry
    rest = block[m.end():]
    # find end of entry by brace count from m.end
    rb = 1
    i = 1
    while i < len(rest) and rb > 0:
        if rest[i] == '{': rb += 1
        elif rest[i] == '}': rb -= 1
        i += 1
    eblock = rest[:i]
    if 'criteria_type="dungeon"' in eblock:
        ach['dungeon_clear'] = True
    if 'criteria_type="raid"' in eblock:
        ach['raid_clear'] = True
    entries.append(ach)

print('Parsed entries:', len(entries))
cats = {}
for a in entries:
    cats.setdefault(a['category'], []).append(a)
for c in sorted(cats):
    print('\n=== %s (%d) ===' % (c, len(cats[c])))
    for a in cats[c]:
        extra = ''
        if a.get('dungeon_clear'): extra += ' [dungeon clear]'
        if a.get('raid_clear'): extra += ' [raid clear]'
        print('  %s - %s - %s (%d pts)%s' % (a['id'], a['name'], a['desc'], a['points'], extra))
