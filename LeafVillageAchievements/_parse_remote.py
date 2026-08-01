import re, json, os, sys

# Parse _remote_Database.lua for achievements
db_path = os.path.join(os.path.dirname(__file__), '_remote_Database.lua')
with open(db_path, 'r', encoding='utf-8') as f:
    text = f.read()

# Extract category list
cat_re = re.compile(r'RelationshipsAchievements_Categories\s*=\s*\{(.*?)\n\}', re.S)
cats = []
m = cat_re.search(text)
if m:
    for line in m.group(1).splitlines():
        idm = re.search(r'id\s*=\s*(\d+).*name\s*=\s*"([^"]+)"', line)
        if idm:
            cats.append({'id': int(idm.group(1)), 'name': idm.group(2)})

# Extract achievement entries (lines starting with { id=... })
ach_re = re.compile(r'^\s*\{\s*id\s*=\s*(\d+)\s*,\s*cat\s*=\s*(\d+)\s*,\s*name\s*=\s*"([^"]+)"\s*,\s*desc\s*=\s*"([^"]*)"(?:[^\n]*?)points\s*=\s*(\d+)(?:[^\n]*?)(?:account\s*=\s*(true|false))?', re.M)
achievements = []
for m in ach_re.finditer(text):
    ach = {
        'id': int(m.group(1)),
        'cat': int(m.group(2)),
        'name': m.group(3),
        'desc': m.group(4),
        'points': int(m.group(5)),
        'account': m.group(6) == 'true' if m.group(6) else False,
    }
    # find progress in the match region
    start = m.start()
    end = m.end()
    block = text[start:end]
    pm = re.search(r'progress\s*=\s*\{\s*stat\s*=\s*"([^"]+)"\s*,\s*max\s*=\s*(\d+)', block)
    if pm:
        ach['progress'] = {'stat': pm.group(1), 'max': int(pm.group(2))}
    achievements.append(ach)

print('Categories:', len(cats))
print('Achievements parsed:', len(achievements))
by_cat = {}
for a in achievements:
    by_cat.setdefault(a['cat'], []).append(a)
for c in sorted(cats, key=lambda x: x['id']):
    lst = by_cat.get(c['id'], [])
    print('\n=== %s (%d) ===' % (c['name'], len(lst)))
    for a in lst:
        prog = ''
        if a.get('progress'):
            prog = ' [progress %s/%d]' % (a['progress']['stat'], a['progress']['max'])
        print('  %5d %s - %s (%d pts%s)%s' % (a['id'], a['name'], a['desc'], a['points'], prog, ' account' if a['account'] else ''))

# Parse Events.lua for unlock/trigger patterns
print('\n\n=== EVENT TRIGGERS ===')
evt_path = os.path.join(os.path.dirname(__file__), '_remote_Events.lua')
if os.path.exists(evt_path):
    with open(evt_path, 'r', encoding='utf-8') as f:
        ev = f.read()
    # find Unlock(id) calls and UpdateStat/AddStat calls
    unlocks = re.findall(r':Unlock\((\d+)\)(?:\s*--\s*(.*))?', ev)
    for uid, comment in unlocks:
        ach = next((a for a in achievements if a['id']==int(uid)), None)
        name = ach['name'] if ach else '???'
        print('  Unlock %s -> %s %s' % (uid, name, '-- '+comment if comment else ''))
    stats = re.findall(r':(?:AddStat|UpdateStat)\("([^"]+)"\s*,\s*([^\)]+)\)', ev)
    print('\nStats used:')
    for s, v in stats:
        print('  %s += %s' % (s, v))
