# Already have the app working on your iPhone?

Start with **UPDATE.md**. It installs the new features into your original project while keeping your signing settings and saved collection.

# Signing repair for the first download

If your existing project fails signing with `bundle format unrecognized, invalid, or unsuitable` in `Metadata.appintents`, use the included repair script on your **existing configured project**:

1. Close the project in Xcode.
2. Copy `repair_resource_layout.py` from this download into your original `RibbonPassport` folder, alongside `RibbonPassport.xcodeproj`.
3. Open Terminal in that original folder and run `python3 repair_resource_layout.py`.
4. Reopen your original project. Choose **Product → Clean Build Folder** (**⇧⌘K**), then **⌘R**.

The repair renames the resource folder and updates the matching code/project references. It keeps your existing Team, bundle identifiers, App Groups, capabilities and provisioning settings. It also creates backup copies of the three edited files. It does not remove App Intents metadata or change widget functionality.

The updated project in this download already uses the corrected folder layout. If you continue with that fresh project instead, follow the setup steps below.

---

# Test Ribbon Passport on your iPhone

This is a native SwiftUI iPhone app with a WidgetKit extension. It does not need Scriptable. Minimum iOS version: **17**. Use a current Xcode release with an SDK that supports your iPhone's iOS version.

## 1. Unzip and personalise the project

Unzip `RibbonPassport-iPhone.zip` on your Mac. Open Terminal in its `RibbonPassport` folder and run the command below, replacing `yourname` with a unique name:

```sh
python3 configure.py ie.yourname.RibbonPassport
```

The command sets matching app, extension and App Group identifiers. You can optionally add your ten-character Apple Team ID as a second argument. No account password is needed by the script.

If you prefer editing in Xcode, set these values manually:

| Setting | Value example |
| --- | --- |
| App bundle identifier | `ie.yourname.RibbonPassport` |
| Widget bundle identifier | `ie.yourname.RibbonPassport.Widgets` |
| Test bundle identifier | `ie.yourname.RibbonPassport.Tests` |
| App Group in both Info.plist files and AppGroups.entitlements | `group.ie.yourname.RibbonPassport` |
| Project build setting `RIBBON_APP_GROUP` | `group.ie.yourname.RibbonPassport` |

## 2. Open Xcode and configure signing

1. Open **RibbonPassport.xcodeproj**.
2. In Xcode Settings → Accounts, add your Apple developer account if needed.
3. Select the blue project icon, then the **RibbonPassport** target. In **Signing & Capabilities**, enable **Automatically manage signing** and choose your developer **Team**.
4. Under **App Groups**, create/enable the exact group printed by the configuration script, for example `group.ie.yourname.RibbonPassport`. If the capability is not visible, use **+ Capability → App Groups**.
5. Repeat for the **RibbonWidgets** target, using the **same Team and the same App Group**. Both targets already reference the shared entitlement file.
6. For **RibbonPassportTests**, choose the same signing Team if Xcode asks.

App Groups let the app and widgets read the same local collection and sprite cache. If the app reports that shared storage is unavailable, check the group on both targets and both provisioning profiles.

## 3. Run on your iPhone

1. Connect the iPhone to your Mac and trust the computer.
2. Select the **RibbonPassport** scheme and your **iPhone** as the run destination in Xcode's top toolbar.
3. If asked, enable **Settings → Privacy & Security → Developer Mode** on the iPhone, restart it and confirm enabling Developer Mode.
4. Press **⌘R** or the Run triangle. Xcode builds, signs and installs the app.

This archive contains source, not a pre-signed IPA. Signing uses your Apple developer account on your Mac. The UI update has been built and tested with the iOS simulator. See UI-UPDATE.md and TESTING.md; installing on an iPhone uses your existing signing setup.

## 4. Test the app immediately

- Tap **Try demo Pokémon** to get a six-member collection with bundled sprites. These are demo records and don't replace imported Pokémon. Use + → Add / refresh demo team to refresh them without duplicates; see DEMO.md.
- To use your real collection, export **RibbonBackup.json** from ribbons.guide and choose **+ → Import backup** in the app. Importing refreshes the website-derived Pokémon and preserves Showdown Pokémon and teams.
- To add your own Showdown team, open **+ → Paste Showdown team**, paste the text from **Teambuilder → Import/Export**, give it a name and tap **Import**.
- Nicknames, species/forms, levels, genders, shiny settings and Gigantamax are imported. Items, abilities, natures, EVs, IVs, Tera types and moves are also retained in each Pokémon's detail screen. The separate Showdown Team widget displays battle details rather than empty ribbon slots.
- Showdown exports do not contain ribbons, marks or origin games. You may set games during import and add awards in a Pokémon's detail screen afterwards.
- Swipe left on a Pokémon in the main collection to delete it and remove it from saved teams.
- Tap a Pokémon to edit its nickname, appearance, current/origin game, awards and equipped title, then **Save**. Changes remain local to this app; nothing is written back to ribbons.guide or Showdown.
- In **Teams**, create or edit a team and select up to six members in display order. Medium widgets use the first three; large widgets use up to six.

Ordinary sprites download over HTTPS and are cached locally. Open the app and let the visible sprites load before adding your widgets. The demo sprites, Shadow Lugia, game emblems, ribbon/mark images, console icons and shiny symbols are bundled. Widget rendering uses the local cache rather than waiting for a network request.

## 5. Add your Home Screen widgets

1. Hold an empty area on the Home Screen → **Edit → Add Widget**.
2. Search **Ribbon Passport**.
3. Choose **Pokémon Passport** (small, medium or large), **Ribbon Team** (medium or large), or **Showdown Team** (medium or large).
4. Hold the placed widget → **Edit Widget** to select its Pokémon/team and appearance. An unset selection follows the app's default.

The widgets use native flexible layouts and have **no outer border**. Console icons have fixed widths and separate text gaps. Light/dark mode is available in Settings, with an optional override on each widget. These layouts support Home Screen widgets; Lock Screen accessory widgets are not included in this build.

## Optional: TestFlight later

Once the app builds and you have tested it, you can archive the **RibbonPassport** scheme for an iOS device and distribute it through App Store Connect/TestFlight using your existing developer subscription. No app has been uploaded or published as part of this project.

See **TESTING.md** for the test suite and device checks.
