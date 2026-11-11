/// The data-privacy notice a student must agree to before registering.
///
/// The backend stores the version the student agreed to and refuses to create
/// an account, enrol a face, or queue a student whose agreement is missing or
/// older than its own CONSENT_VERSION. Change [kConsentVersion] together with
/// the backend setting whenever this text changes, so everyone is asked again.
const String kConsentVersion = '2026-11-v1';

class NoticeSection {
  final String heading;
  final String body;
  const NoticeSection(this.heading, this.body);
}

const String kNoticeIntro =
    'QueuEx is the queue system of the Naga College Foundation, Inc. cashiering '
    'office. Before you register, please read how your information is used.';

const List<NoticeSection> kNoticeSections = [
  NoticeSection(
    'What we collect',
    'Your name and NCF Gbox email from Google sign-in, your student ID number, '
        'and photos of your face taken in this app. From the photos we compute a '
        'face signature, a list of numbers; the photos themselves are discarded '
        'right away and never stored. We also keep a record of your queue '
        'numbers and when you were served.',
  ),
  NoticeSection(
    'Why we collect it',
    'To recognise you at the cashier\'s queue area, so that a queue number is '
        'issued only to you and only after you tap "Get a Queue Number", and to show '
        'you your position and estimated wait.',
  ),
  NoticeSection(
    'Who can see it',
    'Authorised cashier staff and the system administrator. Your data is not '
        'shared with third parties or used for marketing.',
  ),
  NoticeSection(
    'How long we keep it',
    'Until you delete your account. If you do not sign in or join a queue for '
        'one year, your account is archived and your face signature is erased. '
        'After one more year in the archive, the account is deleted.',
  ),
  NoticeSection(
    'Your rights',
    'Under the Data Privacy Act of 2012 (Republic Act No. 10173), you may '
        'withdraw your consent and delete your account at any time from '
        'Profile, Delete my account. Registering is voluntary: you can always '
        'take a printed ticket from the office kiosk instead.',
  ),
];

const String kConsentStatement =
    'I have read this notice and I agree to the collection and use of my '
    'personal data and face photos as described.';
