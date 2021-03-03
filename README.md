LogScan
=======

**Sign-in and inventory logging for team deployment.**

LogScan was created for CERT and first-responder team use to efficiently sign-in members and check out barcoded equipment. It scans using the phone camera and stores time-stamped events. It exports reports similar to ICS-211 and ICS 303 in CSV format.  LogScan is a free app on the App Store: https://apps.apple.com/us/app/logscan/id1071741218

With a single-number QR code or barcode on your team ID badges, LogScan efficiently (and touchlessly) signs members in and out. Plus:

* Equipment checkout: Label items a QR code or barcode consisting of type number and item number.
* Create or use existing ID tag barcodes for your team members.
* To deploy, scan a member ID and an item.
* On return, scan the item.
* List view shows who is here, who has what, and what items are in or out, at a glance.
* All events time stamped.
* Audible check-out/check-in confirmation.
* If you don't have team member IDs, items can be checked out to a team number.
* Export report to a spreadsheet app by email, text message, or copy into another app.
* Export and import equipment and team member database for full names.
* Self-contained; works without Internet.
* Not CERT-specific, track any barcoded item.
* Can use self-naming team member barcodes.
* Organizations that operate a Mattermost server can post sign-in events into a channel for real-time status.

To check out an item, scan an inventory bar code on a piece of equipment and a team member's badge number. On return, scan the equipment bar code again. Reports are exported as comma-separated values (.csv) for display or printing in a spreadsheet app. Can check out to numbered teams instead of scanning member codes: After scanning an equipment item, tap 1 through 8 on screen.

For more information, visit https://gracion.com/logscan/

**Open-source contributions** via pull request are invited. Feedback from CERT or other response teams is welcome. Please use the standard GitHub mechanisms. I don't have a roadmap at this time, but I'm sure you can think of enhancements. Those suggested in the form of a complete pull request are more likely to be implemented. LogScan is written in Objective-C as an iPhone-only app. Nothing against Swift--version 1.0 was written earlier.

### Using the app

* Build with XCode and install on your device (or check the App Store)
* Tap + to display the scan view.
* Sign-in: Scan a person QR or bar code considing of a single number or Surname.Givenname/number. The single-number login uses an imported database to fill in names. If you haven't imported a database, you are prompted to enter the name.
* Logistics: Scan a person barcode and an item barcode (it doesn't matter which you do first).
    When both have been scanned, that item is checked out. Repeat for all persons and items. (Item names require an imported database too, see below.)
* To return (check in) an item or person, scan its barcode again. 
* To edit the name of a person, tap Edit. If an unknown persion ID is scanned, the edit view appears automatically.
* To assign a scanned item to a team number instead of a person, tap the number (1-8, that's all we handle).
* To return to the list, tap Close. 
* For details on a checkout, or to export report, tap a ">" in a main list item. From the detail view, choose Export as csv File for an email-able report.
* To export known  people and products (with names), from the scan view (+), tap the Util button.
* To import people and products, open a .csv file on your device (such as attached to an email) and use the share panel to "Copy to LogScan." For column and data layout, export a file or see example file in this project.
* Print your own barcodes on standard labels with apps such as Code128Encoder by Mobilio.

### Implementation

* Uses AVFoundation metadata capture for code scanning
* Core Data sqlite storage
* Objective-C native app
* No third-party dependencies or libraries.
* Builds/installs with Xcode (12.4 at this writing)
* Entypo pictograms by Daniel Bruce — www.entypo.com (for pre-SF Symbols runtime)
* Open source--pull requests welcome!
* Field-tested by Ashland, Oregon CERT.

### License: 
	GPLv3

### Code of Conduct
	Contributor Covenant 2.0

