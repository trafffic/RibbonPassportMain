# Update your working iPhone app to 0.3

Use the included script to apply this update to your **original, configured project**. It keeps your signing Team, app/extension bundle identifiers, App Groups, Info.plist files and entitlements. Changed project files are backed up. Your saved collection uses the same format.

1. Close Xcode and unzip the new download.
2. Open Terminal in the **new download's RibbonPassport folder**.
3. Type `python3 update_existing.py` followed by a **space**. Drag your **original configured RibbonPassport folder** from Finder into Terminal, then press Return. The original folder is the one you used to install the working app, containing `RibbonPassport.xcodeproj`.
4. Reopen the **original** Xcode project, select your iPhone and choose **Product → Clean Build Folder** (**Shift + Command + K**). Press **Command + R**.
5. Keep the app installed on your iPhone so Xcode updates it in place. There is no need to run `configure.py` again or repeat signing setup.

After installing:

- In the app, tap **+ → Add / refresh demo team** to replace the old demo records. This preserves imported Pokémon, reuses demo IDs where possible and avoids duplicate demo teams. The old demo Swampert is replaced by Sylveon.
- Existing Showdown teams are recognised automatically. Add a **Showdown Team** Home Screen widget and choose your team in **Edit Widget**. Medium displays the first three; large displays up to six. This is a separate widget from **Ribbon Team**.
- Showdown widgets show held items, abilities, Tera types and levels. Large also shows natures and up to four moves. EVs and IVs remain available in the app's detail screen.
- Swipe left on a Pokémon in the main collection to reveal **Delete**, or swipe all the way left to delete immediately. Deletion removes that Pokémon from your saved teams and refreshes widgets. It only changes the local app collection; a later ribbons.guide reimport can restore a Pokémon from your backup.

For a fresh install rather than an update, follow START-HERE.md. See DEMO.md for the six demo journeys and TESTING.md for validation and iPhone checks.

Version 0.3 adds pixel held-item icons with item-coloured names in the Showdown widgets, collection and build details. Equipped titles on single and ribbon-team widgets have their corresponding ribbon or mark beside them, including automatic Memory Ribbon variants, with text matched to the icon’s main colour. Colours adjust for legibility in both themes. All artwork is bundled for offline widget use.

If the updater reports missing files, it now lists their exact names. Keep the updater inside the complete new RibbonPassport folder; moving only the script into another folder does not include the update files. Markdown documentation is optional and no longer blocks the update.
