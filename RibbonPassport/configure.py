#!/usr/bin/env python3
"""Set unique bundle identifiers for your developer account before opening Xcode."""
from pathlib import Path
import json, re, sys

root = Path(__file__).resolve().parent
if len(sys.argv) not in (2, 3) or not re.fullmatch(r'[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+){2,}', sys.argv[1]):
    raise SystemExit('Usage: python3 configure.py ie.yourname.RibbonPassport [APPLE_TEAM_ID]')
prefix = sys.argv[1]
team = sys.argv[2] if len(sys.argv) == 3 else None
if team is not None and not re.fullmatch(r'[A-Z0-9]{10}', team):
    raise SystemExit('The optional Apple Team ID should be ten uppercase letters/digits.')
state = root/'CONFIGURATION.json'
previous = json.loads(state.read_text()) if state.exists() else {'prefix':'com.example.RibbonPassport'}
for path in [root/'RibbonPassport.xcodeproj/project.pbxproj',root/'App/Info.plist',root/'Widgets/Info.plist',
             root/'Shared/AppGroups.entitlements',root/'Shared/SharedStore.swift']:
    text = path.read_text().replace(previous['prefix'], prefix)
    if team is not None and path.name == 'project.pbxproj':
        text = re.sub(r'DEVELOPMENT_TEAM = "[^"]*";', 'DEVELOPMENT_TEAM = "'+team+'";', text)
    path.write_text(text)
state.write_text(json.dumps({'prefix':prefix,'team':team},indent=2))
print('App:       '+prefix)
print('Widgets:   '+prefix+'.Widgets')
print('App Group: group.'+prefix)
print('Now open RibbonPassport.xcodeproj. Choose your signing team for both targets and enable this App Group on both.')
