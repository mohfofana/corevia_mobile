import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = <Locale>[
    Locale('fr'),
    Locale('en'),
  ];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    final localizations =
        Localizations.of<AppLocalizations>(context, AppLocalizations);
    assert(
      localizations != null,
      'AppLocalizations is not available in the widget tree.',
    );
    return localizations!;
  }

  bool get isFrench => locale.languageCode == 'fr';

  String tr({required String fr, required String en}) =>
      isFrench ? fr : en;

  String helloUser(String name) => tr(fr: 'Bonjour, $name', en: 'Hello, $name');
  String get hello => tr(fr: 'Bonjour', en: 'Hello');

  String genericError(String message) => tr(
        fr: 'Erreur : $message',
        en: 'Error: $message',
      );
  String get genericErrorNoDetails =>
      tr(fr: 'Une erreur est survenue.', en: 'Something went wrong.');

  String uploadFailed(String message) => tr(
        fr: 'Échec du téléversement : $message',
        en: 'Upload failed: $message',
      );
  String get uploadFailedNetwork =>
      tr(fr: 'Échec du téléversement réseau', en: 'Network upload failed');
  String get uploadFailedFileTooLarge => tr(
        fr: 'Le fichier dépasse la taille autorisée',
        en: 'The file is too large',
      );

  String filesUploaded(int count) => tr(
        fr: '$count fichier(s) téléversé(s)',
        en: '$count file(s) uploaded',
      );

  String fileTooLarge(String fileName) => tr(
        fr: '$fileName dépasse la limite de 25 Mo',
        en: '$fileName exceeds 25 MB limit',
      );

  String failedToDownload(String message) => tr(
        fr: 'Échec du téléchargement : $message',
        en: 'Failed to download: $message',
      );

  String deleteDocumentConfirm(String fileName) => tr(
        fr: 'Supprimer "$fileName" ? Cette action est irréversible.',
        en: 'Delete "$fileName"? This action cannot be undone.',
      );

  String failedToDelete(String message) => tr(
        fr: 'Échec de la suppression : $message',
        en: 'Failed to delete: $message',
      );

  String pageNotFound(String uri) => tr(
        fr: 'Page introuvable : $uri',
        en: 'Page not found: $uri',
      );

  String get retry => tr(fr: 'Réessayer', en: 'Retry');
  String get cancel => tr(fr: 'Annuler', en: 'Cancel');
  String get save => tr(fr: 'Enregistrer', en: 'Save');
  String get saveChanges => tr(fr: 'Enregistrer les modifications', en: 'Save changes');
  String get delete => tr(fr: 'Supprimer', en: 'Delete');
  String get edit => tr(fr: 'Modifier', en: 'Edit');
  String get add => tr(fr: 'Ajouter', en: 'Add');
  String get approve => tr(fr: 'Approuver', en: 'Approve');
  String get reject => tr(fr: 'Refuser', en: 'Reject');
  String get approved => tr(fr: 'Approuvé', en: 'Approved');
  String get rejected => tr(fr: 'Refusé', en: 'Rejected');
  String get back => tr(fr: 'Retour', en: 'Back');
  String get loading => tr(fr: 'Chargement…', en: 'Loading…');
  String get email => tr(fr: 'Email', en: 'Email');
  String get password => tr(fr: 'Mot de passe', en: 'Password');
  String get connectToContinue =>
      tr(fr: 'Connectez-vous pour continuer', en: 'Sign in to continue');
  String get forgotPassword =>
      tr(fr: 'Mot de passe oublié?', en: 'Forgot password?');
  String get emailSentSuccess =>
      tr(fr: 'Email envoyé avec succès!', en: 'Email sent successfully!');
  String get emailSent => tr(fr: 'Email envoyé !', en: 'Email sent!');
  String get personalInformation =>
      tr(fr: 'Informations personnelles', en: 'Personal information');
  String get howShouldWeCallYou =>
      tr(fr: 'Comment devons-nous vous appeler ?', en: 'How should we address you?');
  String get yourEmail => tr(fr: 'Votre email', en: 'Your email');
  String get weWillUseItToConnect =>
      tr(fr: 'Nous l’utiliserons pour vous connecter', en: 'We will use it to sign you in');
  String get secureYourAccount =>
      tr(fr: 'Sécurisez votre compte', en: 'Secure your account');
  String get chooseStrongPassword =>
      tr(fr: 'Choisissez un mot de passe fort', en: 'Choose a strong password');
  String get confirmPassword =>
      tr(fr: 'Confirmer le mot de passe', en: 'Confirm password');
  String get invalidCredentials =>
      tr(fr: 'Email ou mot de passe incorrect', en: 'Invalid email or password');
  String get invalidDoctor =>
      tr(fr: 'Médecin invalide', en: 'Invalid doctor');
  String get createAppointmentFailed =>
      tr(fr: 'Erreur lors de la création du rendez-vous', en: 'Failed to create appointment');
  String get pleaseTryAgain =>
      tr(fr: 'Veuillez réessayer.', en: 'Please try again.');
  String get registrationFailed =>
      tr(fr: 'Échec de l\'inscription. Veuillez réessayer.', en: 'Registration failed. Please try again.');
  String get firstName => tr(fr: 'Prénom', en: 'First name');
  String get lastName => tr(fr: 'Nom', en: 'Last name');
  String get phone => tr(fr: 'Téléphone', en: 'Phone');
  String get dateOfBirth => tr(fr: 'Date de naissance', en: 'Date of birth');
  String get address => tr(fr: 'Adresse', en: 'Address');
  String get gender => tr(fr: 'Genre', en: 'Gender');
  String get requiredField =>
      tr(fr: 'Champ requis', en: 'Required field');
  String get pleaseEnterFirstName =>
      tr(fr: 'Veuillez saisir votre prénom', en: 'Please enter your first name');
  String get pleaseEnterLastName =>
      tr(fr: 'Veuillez saisir votre nom', en: 'Please enter your last name');
  String get pleaseEnterEmail =>
      tr(fr: 'Veuillez saisir votre email', en: 'Please enter your email');
  String get pleaseEnterValidEmail =>
      tr(fr: 'Veuillez saisir un email valide', en: 'Please enter a valid email');
  String get pleaseEnterPhone =>
      tr(fr: 'Veuillez saisir votre numéro de téléphone', en: 'Please enter your phone number');
  String get male => tr(fr: 'Homme', en: 'Male');
  String get female => tr(fr: 'Femme', en: 'Female');
  String get other => tr(fr: 'Autre', en: 'Other');
  String get selectGender =>
      tr(fr: 'Veuillez sélectionner votre genre', en: 'Please select your gender');
  String get profileUpdatedSuccessfully =>
      tr(fr: 'Profil mis à jour avec succès !', en: 'Profile updated successfully!');
  String get profileUpdateFailed =>
      tr(fr: 'Échec de la mise à jour du profil', en: 'Profile update failed');
  String get changeProfilePhoto =>
      tr(fr: 'Fonction de changement de photo', en: 'Profile photo change feature');
  String get changePassword =>
      tr(fr: 'Changer le mot de passe', en: 'Change password');
  String get myAccount => tr(fr: 'Mon compte', en: 'My Account');
  String get accountInformation =>
      tr(fr: 'Informations du compte', en: 'Account information');
  String get notifications => tr(fr: 'Notifications', en: 'Notifications');
  String get privacySecurity =>
      tr(fr: 'Confidentialité et sécurité', en: 'Privacy and security');
  String get helpSupport =>
      tr(fr: 'Aide et support', en: 'Help and support');
  String get about => tr(fr: 'À propos', en: 'About');
  String get security => tr(fr: 'Sécurité', en: 'Security');
  String get language => tr(fr: 'Langue', en: 'Language');
  String get french => tr(fr: 'Français', en: 'French');
  String get english => tr(fr: 'Anglais', en: 'English');
  String get documents => tr(fr: 'Documents', en: 'Documents');
  String get settings => tr(fr: 'Paramètres', en: 'Settings');
  String get logout => tr(fr: 'Déconnexion', en: 'Logout');
  String get cancelAction => tr(fr: 'Annuler', en: 'Cancel');
  String get doctor => tr(fr: 'Médecin', en: 'Doctor');
  String get patient => tr(fr: 'Patient', en: 'Patient');
  String get search => tr(fr: 'Recherche', en: 'Search');
  String get writeMessage => tr(fr: 'Tapez un message...', en: 'Type a message...');
  String get searchMedication =>
      tr(fr: 'Rechercher un médicament', en: 'Search for a medication');
  String get minimum3Characters =>
      tr(fr: 'Minimum 3 caractères', en: 'Minimum 3 characters');
  String get noResultsFound =>
      tr(fr: 'Aucun résultat. Essayez un nom de molécule (ex: paracétamol).', en: 'No results. Try a molecule name (e.g. paracetamol).');
  String get none => tr(fr: 'Aucune', en: 'None');
  String get custom => tr(fr: 'Autre', en: 'Custom');
  String get morning => tr(fr: 'Matin', en: 'Morning');
  String get noon => tr(fr: 'Midi', en: 'Noon');
  String get evening => tr(fr: 'Soir', en: 'Evening');
  String get bedtime => tr(fr: 'Coucher', en: 'Bedtime');
  String minutesAgo(int minutes) =>
      tr(fr: 'Il y a $minutes min', en: '$minutes min ago');
  String hoursAgo(int hours) =>
      tr(fr: 'Il y a $hours h', en: '$hours h ago');
  String get yesterday => tr(fr: 'Hier', en: 'Yesterday');
  String get searchDoctor =>
      tr(fr: 'Rechercher un médecin…', en: 'Search for a doctor…');
  String get consultDoctorsToBook =>
      tr(fr: 'Consultez la liste des médecins pour prendre rendez-vous.', en: 'Browse the doctor list to book an appointment.');
  String get noDoctorsAvailable =>
      tr(fr: 'Aucun médecin disponible', en: 'No doctors available');
  String get noAvailableSlotsMessage =>
      tr(fr: 'Aucun créneau disponible pour cette date.', en: 'No available slots for this date.');
  String get confirmBooking => tr(fr: 'Confirmer le rendez-vous', en: 'Confirm appointment');
  String get myAppointments => tr(fr: 'Mes rendez-vous', en: 'My appointments');
  String get noUpcomingAppointments =>
      tr(fr: 'Aucun rendez-vous à venir', en: 'No upcoming appointments');
  String get noPastAppointments =>
      tr(fr: 'Aucun rendez-vous passé', en: 'No past appointments');
  String get noCancelledAppointments =>
      tr(fr: 'Aucun rendez-vous annulé', en: 'No cancelled appointments');
  String get bookFromDoctorsList =>
      tr(fr: 'Prenez rendez-vous depuis la liste des médecins.', en: 'Book an appointment from the doctor list.');
  String get pastConsultationsWillAppearHere =>
      tr(fr: 'Vos consultations terminées apparaîtront ici.', en: 'Your completed consultations will appear here.');
  String get cancelledAppointmentsWillAppearHere =>
      tr(fr: 'Les rendez-vous annulés apparaîtront ici.', en: 'Cancelled appointments will appear here.');
  String get appointmentStatus =>
      tr(fr: 'Statut du rendez-vous', en: 'Appointment status');
  String get requestSent =>
      tr(fr: 'Demande envoyée !', en: 'Request sent!');
  String get waitingConfirmation =>
      tr(fr: 'En attente de confirmation', en: 'Waiting for confirmation');
  String get appointmentDetails =>
      tr(fr: 'Détails du rendez-vous', en: 'Appointment details');
  String get dateLabel => tr(fr: 'Date', en: 'Date');
  String get timeLabel => tr(fr: 'Heure', en: 'Time');
  String get addressLabel => tr(fr: 'Adresse', en: 'Address');
  String get andNow => tr(fr: 'Et maintenant ?', en: 'And now?');
  String get youWillReceiveNotification => tr(
        fr: 'Vous recevrez une notification une fois que le médecin aura confirmé votre demande de rendez-vous.',
        en: 'You will receive a notification once the doctor confirms your appointment request.',
      );
  String get backToHome => tr(fr: "Retour à l'accueil", en: 'Back to home');
  String get seeMyAppointments => tr(fr: 'Voir mes rendez-vous', en: 'See my appointments');
  String get statisticsTitle => tr(fr: 'Statistiques', en: 'Statistics');
  String get trackYourHealth =>
      tr(fr: 'Suivez vos mesures de santé', en: 'Track your health measurements');
  String get evolution => tr(fr: 'Évolution', en: 'Trend');
  String get day => tr(fr: 'Jour', en: 'Day');
  String get week => tr(fr: 'Semaine', en: 'Week');
  String get month => tr(fr: 'Mois', en: 'Month');
  String get year => tr(fr: 'Année', en: 'Year');
  String get bloodPressure => tr(fr: 'Tension', en: 'Blood pressure');
  String get bloodGlucose => tr(fr: 'Glycémie', en: 'Blood glucose');
  String get heartRate => tr(fr: 'Fréquence cardiaque', en: 'Heart rate');
  String get temperature => tr(fr: 'Température', en: 'Temperature');
  String get newTrackingData =>
      tr(fr: 'Nouvelle donnée de suivi', en: 'New tracking data');
  String get treatment => tr(fr: 'Traitement', en: 'Treatment');
  String get value => tr(fr: 'Valeur', en: 'Value');
  String get measureDate => tr(fr: 'Date de mesure', en: 'Measurement date');
  String get noteOptionnel =>
      tr(fr: 'Note (optionnel)', en: 'Note (optional)');
  String get contextField =>
      tr(fr: 'Contexte, symptômes, ressenti...', en: 'Context, symptoms, feeling...');
  String get addMeasure => tr(fr: 'Ajouter une donnée', en: 'Add measurement');
  String get today => tr(fr: "Aujourd'hui", en: 'Today');
  String get confirmed => tr(fr: 'Confirmé', en: 'Confirmed');
  static const String appName = 'CoreVia Mobile';
  String get exampleValue => tr(fr: 'Ex: 120', en: 'Ex: 120');
  String get editing => tr(fr: 'Modifier', en: 'Edit');
  String get appointmentDate => tr(fr: 'Date', en: 'Date');
  String get appointmentTime => tr(fr: 'Heure', en: 'Time');
  String get appointmentAddress => tr(fr: 'Adresse', en: 'Address');
  String get myAppointmentsTitle => tr(fr: 'Mes rendez-vous', en: 'My appointments');
  String get appointmentsOverview =>
      tr(fr: 'Résumé du tableau de bord', en: 'Dashboard summary');
  String get appointmentsPerMonth =>
      tr(fr: 'RDV/mois', en: 'Appointments/month');
  String get completed => tr(fr: 'Terminés', en: 'Completed');
  String get pending => tr(fr: 'En attente', en: 'Pending');
  String get adherence => tr(fr: 'Adhérence', en: 'Adherence');
  String get average => tr(fr: 'Moyenne', en: 'Average');
  String get maximum => tr(fr: 'Maximum', en: 'Maximum');
  String get minimum => tr(fr: 'Minimum', en: 'Minimum');
  String get addData => tr(fr: 'Ajouter une donnée', en: 'Add data');
  String get recentHistory => tr(fr: 'Historique récent', en: 'Recent history');
  String get noTrackingData =>
      tr(fr: 'Aucune donnée de suivi pour cette métrique.', en: 'No tracking data for this metric.');
  String get valueFormatInvalid =>
      tr(fr: 'Valeur numérique invalide.', en: 'Invalid numeric value.');
  String get dataSavedMessage =>
      tr(fr: 'Donnée enregistrée.', en: 'Data saved.');
  String get messages => tr(fr: 'Messages', en: 'Messages');
  String get calendar => tr(fr: 'Calendrier', en: 'Calendar');
  String get schedule => tr(fr: 'Programme', en: 'Schedule');
  String get lists => tr(fr: 'Listes', en: 'Lists');
  String get upcoming => tr(fr: 'À venir', en: 'Upcoming');
  String get past => tr(fr: 'Passés', en: 'Past');
  String get cancelled => tr(fr: 'Annulés', en: 'Cancelled');
  String get total => tr(fr: 'Total', en: 'Total');
  String get active => tr(fr: 'Actifs', en: 'Active');
  String get inactive => tr(fr: 'Inactifs', en: 'Inactive');
  String get all => tr(fr: 'Tous', en: 'All');
  String get loadMore => tr(fr: 'Charger plus', en: 'Load more');
  String get myDocuments => tr(fr: 'Mes documents', en: 'My Documents');
  String get yourDocuments => tr(fr: 'Vos documents', en: 'Your Documents');
  String get uploading => tr(fr: 'Téléversement…', en: 'Uploading…');
  String get uploadingTitle => tr(fr: 'Téléversement', en: 'Uploading');
  String get uploadDocuments =>
      tr(fr: 'Téléverser des documents', en: 'Upload documents');
  String get noDocumentsYet =>
      tr(fr: 'Aucun document pour le moment', en: 'No documents yet');
  String get uploadFirstDocument => tr(
        fr: 'Téléversez votre premier document pour commencer',
        en: 'Upload your first document to get started',
      );
  String get deleteDocumentTitle =>
      tr(fr: 'Supprimer le document', en: 'Delete document');
  String get documentDeleted =>
      tr(fr: 'Document supprimé', en: 'Document deleted');
  String confirmUploadFailed(String message) => tr(
        fr: 'Échec de la confirmation du téléversement : $message',
        en: 'Upload confirmation failed: $message',
      );
  String get bookAppointment =>
      tr(fr: 'Prendre rendez-vous', en: 'Book an appointment');
  String get addMedication =>
      tr(fr: 'Ajouter un médicament', en: 'Add medication');
  String get addMedicationsWithSchedules => tr(
        fr: 'Ajoutez des médicaments avec des horaires',
        en: 'Add medications with schedules',
      );
  String get addToPillbox =>
      tr(fr: 'Ajouter au pilulier', en: 'Add to pillbox');
  String get medicationPlan =>
      tr(fr: 'Plan de médicaments', en: 'Medication plan');
  String get medicationNotFound =>
      tr(fr: 'Médicament introuvable', en: 'Medication not found');
  String get medicationDetails =>
      tr(fr: 'Détail du médicament', en: 'Medication details');
  String get information => tr(fr: 'Informations', en: 'Information');
  String get dosage => tr(fr: 'Posologie', en: 'Dosage');
  String get notProvided =>
      tr(fr: 'Non renseigné', en: 'Not provided');
  String get noInstruction =>
      tr(fr: 'Aucune instruction', en: 'No instructions');
  String get activeSubstances =>
      tr(fr: 'Substances actives', en: 'Active ingredients');
  String get noScheduleConfigured =>
      tr(fr: 'Aucun horaire configuré', en: 'No schedule configured');
  String get addScheduleToTrack =>
      tr(fr: 'Ajoutez un horaire pour suivre vos prises', en: 'Add a schedule to track your doses');
  String get disableMedication =>
      tr(fr: 'Désactiver le médicament', en: 'Disable medication');
  String get enableMedication =>
      tr(fr: 'Réactiver le médicament', en: 'Enable medication');
  String get editMedication =>
      tr(fr: 'Modifier le médicament', en: 'Edit medication');
  String get deleteMedication =>
      tr(fr: 'Supprimer le médicament', en: 'Delete medication');
  String get confirmDeleteMedication =>
      tr(fr: 'Supprimer ce médicament ?', en: 'Delete this medication?');
  String get medicationDeleteWarning => tr(
        fr: 'Le médicament et tous ses horaires seront supprimés définitivement.',
        en: 'The medication and all its schedules will be permanently deleted.',
      );
  String get deleteScheduleConfirm =>
      tr(fr: 'Supprimer cet horaire ?', en: 'Delete this schedule?');
  String get irreversibleAction =>
      tr(fr: 'Cette action est irréversible.', en: 'This action cannot be undone.');
  String get noDetails =>
      tr(fr: 'Aucun détail', en: 'No details');
  String get instructions => tr(fr: 'Instructions', en: 'Instructions');
  String get quantity => tr(fr: 'Quantité', en: 'Quantity');
  String get unit => tr(fr: 'Unité', en: 'Unit');
  String get unitExamples =>
      tr(fr: 'Unité (mg, ml...)', en: 'Unit (mg, ml...)');
  String get notesOptional =>
      tr(fr: 'Notes (optionnel)', en: 'Notes (optional)');
  String get momentOfDay =>
      tr(fr: 'Moment de la journée', en: 'Time of day');
  String get timeOfIntake => tr(fr: 'Heure de prise', en: 'Intake time');
  String get addSchedule =>
      tr(fr: 'Ajouter un horaire', en: 'Add schedule');
  String get modifySchedule =>
      tr(fr: 'Modifier l\'horaire', en: 'Edit schedule');
  String get scheduleTimes =>
      tr(fr: 'Horaires de prise', en: 'Intake times');
  String get actions => tr(fr: 'Actions', en: 'Actions');
  String get frequency => tr(fr: 'Fréquence', en: 'Frequency');
  String get start => tr(fr: 'Début', en: 'Start');
  String get end => tr(fr: 'Fin', en: 'End');
  String get description => tr(fr: 'Description', en: 'Description');
  String get markAsTaken =>
      tr(fr: 'Marquer comme pris', en: 'Mark as taken');
  String get skip => tr(fr: 'Ignorer', en: 'Skip');
  String get approveAll =>
      tr(fr: 'Tout approuver', en: 'Approve all');
  String get rejectAll =>
      tr(fr: 'Tout refuser', en: 'Reject all');
  String get soonAvailable =>
      tr(fr: 'Bientôt disponible…', en: 'Coming soon…');
  String get chooseSpecialty =>
      tr(fr: 'Choisir une spécialité', en: 'Choose a specialty');
  String get specialties => tr(fr: 'Spécialités', en: 'Specialties');
  String get askDocAi =>
      tr(fr: 'Posez votre question à DocAI', en: 'Ask DocAI a question');
  String get docAiAssistant =>
      tr(fr: 'Assistant DocAI', en: 'DocAI Assistant');
  String get writingStatus =>
      tr(fr: 'En train d\'écrire…', en: 'Typing…');
  String get online => tr(fr: 'En ligne', en: 'Online');
  String get viewAll => tr(fr: 'Voir tout', en: 'View all');
  String get history => tr(fr: 'Historique', en: 'History');
  String get recentActivity =>
      tr(fr: 'Activité récente', en: 'Recent activity');
  String get proMember => tr(fr: 'Membre Pro', en: 'Pro member');
  String get todayIntakes =>
      tr(fr: 'Prises du jour', en: 'Today\'s intakes');
  String todayIntakeProgress(int taken, int total) =>
      tr(fr: '$taken/$total prises effectuées', en: '$taken/$total taken');
  String get noIntakesToday => tr(
        fr: 'Aucune prise prévue aujourd\'hui',
        en: 'No intakes scheduled today',
      );
  String get noMedicationsScheduled =>
      tr(fr: 'Pas de médicaments programmés', en: 'No medications scheduled');
  String get startChatDocAi =>
      tr(fr: 'Commencer un chat avec DocAI', en: 'Start a chat with DocAI');
  String intakeAlreadyTaken(String medicationName) =>
      tr(fr: '$medicationName : prise déjà effectuée', en: '$medicationName: already taken');
  String intakeSkipped(String medicationName) =>
      tr(fr: '$medicationName : prise ignorée', en: '$medicationName: skipped');
  String markedAsTaken(String medicationName) =>
      tr(fr: '$medicationName marqué comme pris !', en: '$medicationName marked as taken!');
  String skippedMedication(String medicationName) =>
      tr(fr: '$medicationName ignoré', en: '$medicationName skipped');
  String get emptyPillboxTitle =>
      tr(fr: 'Votre pilulier est vide', en: 'Your pillbox is empty');
  String get emptyPillboxSubtitle => tr(
        fr: 'Ajoutez votre premier médicament pour commencer votre suivi.',
        en: 'Add your first medication to start tracking.',
      );
  String get noMedicationsActive =>
      tr(fr: 'Aucun médicament actif', en: 'No active medication');
  String get noMedicationsInactive =>
      tr(fr: 'Aucun médicament inactif', en: 'No inactive medication');
  String get medicationName =>
      tr(fr: 'Nom du médicament', en: 'Medication name');
  String get confirmUploadFailedTitle =>
      tr(fr: 'Échec de la confirmation', en: 'Confirmation failed');
  String get editProfile =>
      tr(fr: 'Modifier le profil', en: 'Edit profile');
  String get welcome => tr(fr: 'Bienvenue', en: 'Welcome');
  String get noAccountYet =>
      tr(fr: 'Pas encore de compte ?', en: 'No account yet?');
  String get signUp => tr(fr: 'S\'inscrire', en: 'Sign up');
  String get signIn => tr(fr: 'Se connecter', en: 'Sign in');
  String get createAccount =>
      tr(fr: 'Créer un compte', en: 'Create an account');
  String get createMyAccount =>
      tr(fr: 'Créer mon compte', en: 'Create my account');
  String get next => tr(fr: 'Suivant', en: 'Next');
  String get resetPasswordTitle =>
      tr(fr: 'Réinitialisation', en: 'Reset password');
  String get resetPasswordHelp => tr(
        fr: 'Pas de souci ! Entrez votre adresse email et nous vous enverrons un lien pour réinitialiser votre mot de passe',
        en: 'No worries! Enter your email address and we will send you a link to reset your password',
      );
  String resetEmailSentTo(String email) => tr(
        fr: 'Nous avons envoyé un lien de réinitialisation à $email',
        en: 'We have sent a reset link to $email',
      );
  String get resetCheckInbox => tr(
        fr: 'Vérifiez votre boîte de réception et cliquez sur le lien pour réinitialiser votre mot de passe',
        en: 'Check your inbox and click the link to reset your password',
      );
  String get resendEmail => tr(fr: 'Renvoyer l\'email', en: 'Resend email');
  String get sendLink =>
      tr(fr: 'Envoyer le lien', en: 'Send the link');
  String get chooseSpecialist =>
      tr(fr: 'Choisir un spécialiste', en: 'Choose a specialist');
  String get close => tr(fr: 'Fermer', en: 'Close');
  String get clearHistory =>
      tr(fr: 'Effacer l\'historique', en: 'Clear history');
  String get connecting => tr(fr: 'Connexion…', en: 'Connecting…');
  String get generalPractitioner =>
      tr(fr: 'Médecin généraliste', en: 'General practitioner');
  String get generalMedicine =>
      tr(fr: 'Médecine générale', en: 'General medicine');
  String get dermatologist =>
      tr(fr: 'Dermatologue', en: 'Dermatologist');
  String get dermatology =>
      tr(fr: 'Dermatologie', en: 'Dermatology');
  String get nutritionist =>
      tr(fr: 'Nutritionniste', en: 'Nutritionist');
  String get nutrition => tr(fr: 'Nutrition', en: 'Nutrition');
  String get psychologist =>
      tr(fr: 'Psychologue', en: 'Psychologist');
  String get mentalHealth =>
      tr(fr: 'Santé mentale', en: 'Mental health');
  String get lungSpecialist =>
      tr(fr: 'Spécialiste des poumons', en: 'Lung specialist');
  String get appointmentConfirmedTomorrowAt1030 => tr(
        fr: 'Votre rendez-vous est confirmé pour demain à 10h30',
        en: 'Your appointment is confirmed for tomorrow at 10:30 AM',
      );
  String get takeMedicationThisMorning => tr(
        fr: 'N\'oubliez pas de prendre votre médicament ce matin',
        en: 'Do not forget to take your medication this morning',
      );
  String get examResultsAvailable => tr(
        fr: 'Vos résultats d\'examen sont disponibles',
        en: 'Your test results are available',
      );
  String get searchConversations =>
      tr(fr: 'Rechercher des conversations…', en: 'Search conversations…');
  String get lungCheckup =>
      tr(fr: 'Pour un contrôle pulmonaire', en: 'For a lung checkup');
  String aiDoctorGreeting(String patientName, String name, String specialty) => tr(
        fr: 'Bonjour $patientName ! Je suis $name, spécialiste en $specialty. Comment puis-je vous aider aujourd\'hui ?',
        en: 'Hello $patientName! I am $name, a specialist in $specialty. How can I help you today?',
      );
  String get confirmationRequired =>
      tr(fr: 'Confirmation requise', en: 'Confirmation required');
  String get passwordsDifferent =>
      tr(fr: 'Mots de passe différents', en: 'Passwords do not match');
  String fieldRequired(String fieldName) =>
      tr(fr: '$fieldName est requis', en: '$fieldName is required');
  String fieldMustContainAtLeast(String fieldName, int min) => tr(
        fr: '$fieldName doit contenir au moins $min caractères',
        en: '$fieldName must contain at least $min characters',
      );
  String fieldCannotExceed(String fieldName, int max) => tr(
        fr: '$fieldName ne peut pas dépasser $max caractères',
        en: '$fieldName cannot exceed $max characters',
      );
  String get pleaseEnterPassword => tr(
        fr: 'Veuillez saisir un mot de passe',
        en: 'Please enter a password',
      );
  String get passwordMustContainLowercase => tr(
        fr: 'Le mot de passe doit contenir au moins une minuscule',
        en: 'Password must contain at least one lowercase letter',
      );
  String get passwordMustContainUppercase => tr(
        fr: 'Le mot de passe doit contenir au moins une majuscule',
        en: 'Password must contain at least one uppercase letter',
      );
  String get passwordMustContainDigit => tr(
        fr: 'Le mot de passe doit contenir au moins un chiffre',
        en: 'Password must contain at least one digit',
      );
  String get passwordMustContainSpecialCharacter => tr(
        fr: 'Le mot de passe doit contenir au moins un caractère spécial',
        en: 'Password must contain at least one special character',
      );
  String get passwordMustBeBetween8And100Characters => tr(
        fr: 'Le mot de passe doit contenir entre 8 et 100 caractères',
        en: 'Password must be between 8 and 100 characters long',
      );
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales
      .any((supported) => supported.languageCode == locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture(AppLocalizations(locale));
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}

extension AppLocalizationsContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
