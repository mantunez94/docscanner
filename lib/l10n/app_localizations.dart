import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'DocScanner'**
  String get appTitle;

  /// AppBar title for the scanner screen
  ///
  /// In en, this message translates to:
  /// **'Scan Document'**
  String get scanDocument;

  /// Scan button label
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get scan;

  /// AppBar title when scanning with pages
  ///
  /// In en, this message translates to:
  /// **'Scan ({count} page)'**
  String scanNPages(int count);

  /// AppBar title when scanning with pages (plural)
  ///
  /// In en, this message translates to:
  /// **'Scan ({count} pages)'**
  String scanNPages_plural(int count);

  /// Back tooltip
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// Torch on tooltip
  ///
  /// In en, this message translates to:
  /// **'Torch on'**
  String get torchOn;

  /// Torch off tooltip
  ///
  /// In en, this message translates to:
  /// **'Torch off'**
  String get torchOff;

  /// SnackBar when torch not available
  ///
  /// In en, this message translates to:
  /// **'Torch not available on this device'**
  String get torchNotAvailable;

  /// Black and white mode tooltip
  ///
  /// In en, this message translates to:
  /// **'B&W mode'**
  String get bwMode;

  /// Color mode tooltip
  ///
  /// In en, this message translates to:
  /// **'Color mode'**
  String get colorMode;

  /// Done scanning tooltip
  ///
  /// In en, this message translates to:
  /// **'Done scanning'**
  String get doneScanning;

  /// Capture photo tooltip
  ///
  /// In en, this message translates to:
  /// **'Capture photo'**
  String get capturePhoto;

  /// Error message when camera permission permanently denied
  ///
  /// In en, this message translates to:
  /// **'Camera permission is permanently denied. Please enable it in app settings.'**
  String get cameraPermissionDenied;

  /// Dialog title for camera permission
  ///
  /// In en, this message translates to:
  /// **'Camera permission needed'**
  String get cameraPermissionNeeded;

  /// Permission rationale text
  ///
  /// In en, this message translates to:
  /// **'DocScanner needs access to your camera to scan documents. No photos are taken without your action.'**
  String get cameraPermissionRationale;

  /// Deny button
  ///
  /// In en, this message translates to:
  /// **'Deny'**
  String get deny;

  /// Allow button
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get allow;

  /// Error when permission not granted
  ///
  /// In en, this message translates to:
  /// **'Camera permission is required to scan documents.'**
  String get cameraPermissionRequired;

  /// Error when no camera available
  ///
  /// In en, this message translates to:
  /// **'No camera found'**
  String get noCameraFound;

  /// Error when camera fails to open
  ///
  /// In en, this message translates to:
  /// **'Failed to open camera. Please try again.'**
  String get failedOpenCamera;

  /// Button to open system settings
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// Button to go back
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get goBack;

  /// Retry button
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Dialog title for discarding pages
  ///
  /// In en, this message translates to:
  /// **'Discard pages?'**
  String get discardPages;

  /// Body text for discard pages dialog
  ///
  /// In en, this message translates to:
  /// **'You have {count} page in progress. Discard them?'**
  String discardPagesBody(int count);

  /// Body text for discard pages dialog (plural)
  ///
  /// In en, this message translates to:
  /// **'You have {count} pages in progress. Discard them?'**
  String discardPagesBody_plural(int count);

  /// Stay button
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get stay;

  /// Discard button
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// Error processing page
  ///
  /// In en, this message translates to:
  /// **'Failed to process page. Please try again.'**
  String get failedProcessPage;

  /// Error during capture
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while capturing. Please try again.'**
  String get failedCapture;

  /// SnackBar after reordering pages
  ///
  /// In en, this message translates to:
  /// **'Pages reordered'**
  String get pagesReordered;

  /// Dialog title
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get discardChanges;

  /// Dialog body
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes to the page order.'**
  String get discardChangesBody;

  /// Button to keep editing
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get keepEditing;

  /// Reorder pages title
  ///
  /// In en, this message translates to:
  /// **'Reorder pages'**
  String get reorderPages;

  /// Done button/tooltip
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// Select pages tooltip
  ///
  /// In en, this message translates to:
  /// **'Select pages'**
  String get selectPages;

  /// Delete selected tooltip
  ///
  /// In en, this message translates to:
  /// **'Delete selected'**
  String get deleteSelected;

  /// Cancel selection tooltip
  ///
  /// In en, this message translates to:
  /// **'Cancel selection'**
  String get cancelSelection;

  /// Cancel reorder tooltip
  ///
  /// In en, this message translates to:
  /// **'Cancel reorder'**
  String get cancelReorder;

  /// No pages text
  ///
  /// In en, this message translates to:
  /// **'No pages'**
  String get noPages;

  /// No pages body text
  ///
  /// In en, this message translates to:
  /// **'This document has no pages'**
  String get noPagesBody;

  /// Add page tooltip
  ///
  /// In en, this message translates to:
  /// **'Add page'**
  String get addPage;

  /// Page number label
  ///
  /// In en, this message translates to:
  /// **'Page {index}'**
  String pageN(int index);

  /// SnackBar when trying to delete all pages
  ///
  /// In en, this message translates to:
  /// **'Cannot delete all pages. Delete the document instead.'**
  String get cannotDeleteAllPages;

  /// SnackBar when no pages selected
  ///
  /// In en, this message translates to:
  /// **'No pages selected'**
  String get noPagesSelected;

  /// Delete document action
  ///
  /// In en, this message translates to:
  /// **'Delete document'**
  String get deleteDocument;

  /// Dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete pages'**
  String get deletePages;

  /// Confirmation text
  ///
  /// In en, this message translates to:
  /// **'Delete {count} page?'**
  String deleteNPages(int count);

  /// Confirmation text (plural)
  ///
  /// In en, this message translates to:
  /// **'Delete {count} pages?'**
  String deleteNPages_plural(int count);

  /// Cancel button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Deletion confirmation
  ///
  /// In en, this message translates to:
  /// **'{count} page deleted'**
  String nPagesDeleted(int count);

  /// Deletion confirmation (plural)
  ///
  /// In en, this message translates to:
  /// **'{count} pages deleted'**
  String nPagesDeleted_plural(int count);

  /// Delete button
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Select documents text
  ///
  /// In en, this message translates to:
  /// **'Select documents'**
  String get selectDocuments;

  /// Number of items selected
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String nSelected(int count);

  /// Deselect all tooltip
  ///
  /// In en, this message translates to:
  /// **'Deselect all'**
  String get deselectAll;

  /// Select all tooltip
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get selectAll;

  /// Change theme tooltip
  ///
  /// In en, this message translates to:
  /// **'Change theme'**
  String get changeTheme;

  /// Theme mode tooltip
  ///
  /// In en, this message translates to:
  /// **'Theme mode'**
  String get themeMode;

  /// Export PDF tooltip
  ///
  /// In en, this message translates to:
  /// **'Export PDF'**
  String get exportPdf;

  /// Show onboarding tooltip
  ///
  /// In en, this message translates to:
  /// **'Show onboarding'**
  String get showOnboarding;

  /// Error text
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// Search hint text
  ///
  /// In en, this message translates to:
  /// **'Search documents...'**
  String get searchDocuments;

  /// Clear search tooltip
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearch;

  /// No results text
  ///
  /// In en, this message translates to:
  /// **'No documents match'**
  String get noDocumentsMatch;

  /// Scan tooltip
  ///
  /// In en, this message translates to:
  /// **'Scan a document'**
  String get scanADocument;

  /// Dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete documents'**
  String get deleteDocuments;

  /// Delete confirmation
  ///
  /// In en, this message translates to:
  /// **'Delete {count} document? This cannot be undone.'**
  String deleteNDocuments(int count);

  /// Delete confirmation (plural)
  ///
  /// In en, this message translates to:
  /// **'Delete {count} documents? This cannot be undone.'**
  String deleteNDocuments_plural(int count);

  /// Deletion confirmation
  ///
  /// In en, this message translates to:
  /// **'{count} document deleted'**
  String nDocumentsDeleted(int count);

  /// Deletion confirmation (plural)
  ///
  /// In en, this message translates to:
  /// **'{count} documents deleted'**
  String nDocumentsDeleted_plural(int count);

  /// Undo action
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// SnackBar for added pages
  ///
  /// In en, this message translates to:
  /// **'Pages added'**
  String get pagesAdded;

  /// SnackBar for saved document
  ///
  /// In en, this message translates to:
  /// **'Document saved'**
  String get documentSaved;

  /// Dialog title
  ///
  /// In en, this message translates to:
  /// **'Rename document'**
  String get renameDocument;

  /// Field label
  ///
  /// In en, this message translates to:
  /// **'Document name'**
  String get documentName;

  /// Rename button
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// Delete document confirmation
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"?'**
  String deleteDocumentConfirm(String name);

  /// Deletion confirmation with name
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" deleted'**
  String nameDeleted(String name);

  /// SnackBar while generating PDF
  ///
  /// In en, this message translates to:
  /// **'Generating PDF...'**
  String get generatingPdf;

  /// Export error
  ///
  /// In en, this message translates to:
  /// **'Failed to export PDF. Please try again.'**
  String get failedExportPdf;

  /// Auto theme mode
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get auto;

  /// Light theme mode
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// Dark theme mode
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// Empty state title
  ///
  /// In en, this message translates to:
  /// **'No documents yet'**
  String get noDocumentsYet;

  /// Empty state body
  ///
  /// In en, this message translates to:
  /// **'Scan your first document\nto get started'**
  String get scanFirstDocument;

  /// Arcade theme name
  ///
  /// In en, this message translates to:
  /// **'Arcade'**
  String get arcade;

  /// Kawaii theme name
  ///
  /// In en, this message translates to:
  /// **'Kawaii'**
  String get kawaii;

  /// Professional theme name
  ///
  /// In en, this message translates to:
  /// **'Professional'**
  String get professional;

  /// OCR error
  ///
  /// In en, this message translates to:
  /// **'Text extraction failed. Please try again.'**
  String get textExtractionFailed;

  /// OCR header
  ///
  /// In en, this message translates to:
  /// **'Extracted Text'**
  String get extractedText;

  /// Text blocks count
  ///
  /// In en, this message translates to:
  /// **'{count} text block found'**
  String nTextBlocksFound(int count);

  /// Text blocks count (plural)
  ///
  /// In en, this message translates to:
  /// **'{count} text blocks found'**
  String nTextBlocksFound_plural(int count);

  /// Copy button
  ///
  /// In en, this message translates to:
  /// **'Copy to Clipboard'**
  String get copyToClipboard;

  /// Copy confirmation
  ///
  /// In en, this message translates to:
  /// **'Text copied to clipboard'**
  String get textCopiedToClipboard;

  /// Preview loading title
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// Discard crop changes body
  ///
  /// In en, this message translates to:
  /// **'You have made adjustments to the crop area. Do you want to discard them?'**
  String get discardCropChanges;

  /// AppBar title
  ///
  /// In en, this message translates to:
  /// **'Adjust & Confirm'**
  String get adjustAndConfirm;

  /// Tooltip
  ///
  /// In en, this message translates to:
  /// **'Reset corners'**
  String get resetCorners;

  /// Tooltip
  ///
  /// In en, this message translates to:
  /// **'Extract text from this page'**
  String get extractTextFromPage;

  /// Tooltip
  ///
  /// In en, this message translates to:
  /// **'Take photo again'**
  String get takePhotoAgain;

  /// Tooltip
  ///
  /// In en, this message translates to:
  /// **'Save scan'**
  String get saveScan;

  /// Fallback message
  ///
  /// In en, this message translates to:
  /// **'Processing failed. Using original image.'**
  String get processingFailedUsingOriginal;

  /// Processing error
  ///
  /// In en, this message translates to:
  /// **'Failed to process image. Please try again.'**
  String get failedProcessImage;

  /// Review title
  ///
  /// In en, this message translates to:
  /// **'Review ({count} page)'**
  String reviewNPages(int count);

  /// Review title (plural)
  ///
  /// In en, this message translates to:
  /// **'Review ({count} pages)'**
  String reviewNPages_plural(int count);

  /// Delete all tooltip
  ///
  /// In en, this message translates to:
  /// **'Delete all'**
  String get deleteAll;

  /// Saving state
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// Save button
  ///
  /// In en, this message translates to:
  /// **'Save as document'**
  String get saveAsDocument;

  /// Dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete all pages?'**
  String get deleteAllPages;

  /// Dialog body
  ///
  /// In en, this message translates to:
  /// **'All captured pages will be discarded.'**
  String get deleteAllPagesBody;

  /// Dialog title
  ///
  /// In en, this message translates to:
  /// **'Save as'**
  String get saveAs;

  /// Duplicate name error
  ///
  /// In en, this message translates to:
  /// **'A document named \"{name}\" already exists.'**
  String documentAlreadyExists(String name);

  /// Save button
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// File size in KB
  ///
  /// In en, this message translates to:
  /// **'{size} KB'**
  String nKb(int size);

  /// Tooltip
  ///
  /// In en, this message translates to:
  /// **'Edit page'**
  String get editPage;

  /// Tooltip
  ///
  /// In en, this message translates to:
  /// **'Delete page'**
  String get deletePage;

  /// Save error
  ///
  /// In en, this message translates to:
  /// **'Failed to save document. Please try again.'**
  String get failedSaveDocument;

  /// Onboarding page 1 title
  ///
  /// In en, this message translates to:
  /// **'Scan Documents'**
  String get onboardingScanTitle;

  /// Onboarding page 1 description
  ///
  /// In en, this message translates to:
  /// **'Capture documents with your camera. Auto-crop and enhance them for a clean result.'**
  String get onboardingScanDesc;

  /// Onboarding page 2 title
  ///
  /// In en, this message translates to:
  /// **'Adjust & Refine'**
  String get onboardingAdjustTitle;

  /// Onboarding page 2 description
  ///
  /// In en, this message translates to:
  /// **'Fine-tune corners, adjust perspective, and enhance the image for a crisp, clean scan.'**
  String get onboardingAdjustDesc;

  /// Onboarding page 3 title
  ///
  /// In en, this message translates to:
  /// **'Extract Text'**
  String get onboardingOcrTitle;

  /// Onboarding page 3 description
  ///
  /// In en, this message translates to:
  /// **'Extract text from any scanned document. Just tap and copy the result.'**
  String get onboardingOcrDesc;

  /// Onboarding page 4 title
  ///
  /// In en, this message translates to:
  /// **'Export & Share'**
  String get onboardingExportTitle;

  /// Onboarding page 4 description
  ///
  /// In en, this message translates to:
  /// **'Export documents as PDF, rename, or share them directly from the app.'**
  String get onboardingExportDesc;

  /// Skip button
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// Finish button
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// Next button
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// Broken image hint
  ///
  /// In en, this message translates to:
  /// **'Tap to reload'**
  String get tapToReload;

  /// Document page count
  ///
  /// In en, this message translates to:
  /// **'{count} page'**
  String nPages(int count);

  /// Document page count (plural)
  ///
  /// In en, this message translates to:
  /// **'{count} pages'**
  String nPages_plural(int count);

  /// Rename action
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get renameLabel;

  /// View pages action
  ///
  /// In en, this message translates to:
  /// **'View pages ({count})'**
  String viewPages(int count);

  /// Share action
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// Validation error
  ///
  /// In en, this message translates to:
  /// **'Name cannot be empty'**
  String get nameCannotBeEmpty;

  /// Validation error
  ///
  /// In en, this message translates to:
  /// **'Name is too long'**
  String get nameTooLong;

  /// Validation error
  ///
  /// In en, this message translates to:
  /// **'Name contains invalid characters'**
  String get nameInvalidChars;

  /// January abbreviation
  ///
  /// In en, this message translates to:
  /// **'Jan'**
  String get jan;

  /// February abbreviation
  ///
  /// In en, this message translates to:
  /// **'Feb'**
  String get feb;

  /// March abbreviation
  ///
  /// In en, this message translates to:
  /// **'Mar'**
  String get mar;

  /// April abbreviation
  ///
  /// In en, this message translates to:
  /// **'Apr'**
  String get apr;

  /// May abbreviation
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get may;

  /// June abbreviation
  ///
  /// In en, this message translates to:
  /// **'Jun'**
  String get jun;

  /// July abbreviation
  ///
  /// In en, this message translates to:
  /// **'Jul'**
  String get jul;

  /// August abbreviation
  ///
  /// In en, this message translates to:
  /// **'Aug'**
  String get aug;

  /// September abbreviation
  ///
  /// In en, this message translates to:
  /// **'Sep'**
  String get sep;

  /// October abbreviation
  ///
  /// In en, this message translates to:
  /// **'Oct'**
  String get oct;

  /// November abbreviation
  ///
  /// In en, this message translates to:
  /// **'Nov'**
  String get nov;

  /// December abbreviation
  ///
  /// In en, this message translates to:
  /// **'Dec'**
  String get dec;

  /// About dialog title
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// Privacy Policy link label
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// About dialog body text
  ///
  /// In en, this message translates to:
  /// **'DocScanner is a 100% offline document scanner. Your data never leaves your device.'**
  String get aboutBody;

  /// Contact / report issues link
  ///
  /// In en, this message translates to:
  /// **'Report issues on GitHub'**
  String get contactEmail;

  /// Help screen title
  ///
  /// In en, this message translates to:
  /// **'How to Use'**
  String get howToUse;

  /// Scanner feature title in help
  ///
  /// In en, this message translates to:
  /// **'Document Scanner'**
  String get helpScanner;

  /// Scanner feature description in help
  ///
  /// In en, this message translates to:
  /// **'Scan documents in Color or Black & White mode. Toggle modes before capturing. The app automatically detects document boundaries in real-time.'**
  String get helpScannerDesc;

  /// Boundary detection feature title in help
  ///
  /// In en, this message translates to:
  /// **'Boundary Detection & Crop'**
  String get helpBoundary;

  /// Boundary detection feature description in help
  ///
  /// In en, this message translates to:
  /// **'Green corners show detected document edges. Drag them to adjust the crop area manually. A magnifier helps with precise corner placement.'**
  String get helpBoundaryDesc;

  /// Multi-page feature title in help
  ///
  /// In en, this message translates to:
  /// **'Multi-Page Scanning'**
  String get helpMultiPage;

  /// Multi-page feature description in help
  ///
  /// In en, this message translates to:
  /// **'Capture multiple pages in one session without leaving the scanner. Review, reorder, edit, or delete pages before saving as a single document.'**
  String get helpMultiPageDesc;

  /// OCR feature title in help
  ///
  /// In en, this message translates to:
  /// **'Text Extraction (OCR)'**
  String get helpOcr;

  /// OCR feature description in help
  ///
  /// In en, this message translates to:
  /// **'Extract text from any scanned page using Google ML Kit. Copy the recognized text to your clipboard with one tap.'**
  String get helpOcrDesc;

  /// PDF feature title in help
  ///
  /// In en, this message translates to:
  /// **'PDF Export & Share'**
  String get helpPdf;

  /// PDF feature description in help
  ///
  /// In en, this message translates to:
  /// **'Export any document as a PDF file. Share it directly from the app via email, messaging apps, or save to cloud storage.'**
  String get helpPdfDesc;

  /// Search feature title in help
  ///
  /// In en, this message translates to:
  /// **'Search & Batch Operations'**
  String get helpSearch;

  /// Search feature description in help
  ///
  /// In en, this message translates to:
  /// **'Search documents by name. Select multiple documents to delete them in batch or export as PDF.'**
  String get helpSearchDesc;

  /// Themes feature title in help
  ///
  /// In en, this message translates to:
  /// **'Custom Themes'**
  String get helpThemes;

  /// Themes feature description in help
  ///
  /// In en, this message translates to:
  /// **'Choose between 3 themes: Arcade (neon retro), Kawaii (pastel cute), or Professional (clean minimal).'**
  String get helpThemesDesc;

  /// Undo feature title in help
  ///
  /// In en, this message translates to:
  /// **'Undo Actions'**
  String get helpUndo;

  /// Undo feature description in help
  ///
  /// In en, this message translates to:
  /// **'After deleting a document, a snackbar appears with an Undo button. You have 4 seconds to restore the document before it is permanently deleted.'**
  String get helpUndoDesc;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
