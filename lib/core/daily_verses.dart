/// Scripture shown on the home page when the church has not published a verse for today.
/// King James Version (public domain). One verse per day, rotating through the list.
const dailyVerses = <({String reference, String text})>[
  (
    reference: 'Psalm 118:24',
    text:
        'This is the day which the LORD hath made; we will rejoice and be glad in it.',
  ),
  (
    reference: 'Lamentations 3:22-23',
    text:
        "It is of the LORD's mercies that we are not consumed, because his compassions fail not. They are new every morning: great is thy faithfulness.",
  ),
  (
    reference: 'Proverbs 3:5-6',
    text:
        'Trust in the LORD with all thine heart; and lean not unto thine own understanding. In all thy ways acknowledge him, and he shall direct thy paths.',
  ),
  (
    reference: 'Acts 1:8',
    text:
        'But ye shall receive power, after that the Holy Ghost is come upon you: and ye shall be witnesses unto me both in Jerusalem, and in all Judaea, and in Samaria, and unto the uttermost part of the earth.',
  ),
  (
    reference: 'Isaiah 40:31',
    text:
        'But they that wait upon the LORD shall renew their strength; they shall mount up with wings as eagles; they shall run, and not be weary; and they shall walk, and not faint.',
  ),
  (
    reference: 'Philippians 4:13',
    text: 'I can do all things through Christ which strengtheneth me.',
  ),
  (reference: 'Psalm 23:1', text: 'The LORD is my shepherd; I shall not want.'),
  (
    reference: 'Joshua 1:9',
    text:
        'Have not I commanded thee? Be strong and of a good courage; be not afraid, neither be thou dismayed: for the LORD thy God is with thee whithersoever thou goest.',
  ),
  (
    reference: 'Romans 8:28',
    text:
        'And we know that all things work together for good to them that love God, to them who are the called according to his purpose.',
  ),
  (
    reference: 'Matthew 6:33',
    text:
        'But seek ye first the kingdom of God, and his righteousness; and all these things shall be added unto you.',
  ),
  (
    reference: 'Psalm 46:1',
    text: 'God is our refuge and strength, a very present help in trouble.',
  ),
  (
    reference: 'Galatians 5:22-23',
    text:
        'But the fruit of the Spirit is love, joy, peace, longsuffering, gentleness, goodness, faith, meekness, temperance: against such there is no law.',
  ),
  (
    reference: 'Psalm 119:105',
    text: 'Thy word is a lamp unto my feet, and a light unto my path.',
  ),
  (
    reference: 'Jeremiah 29:11',
    text:
        'For I know the thoughts that I think toward you, saith the LORD, thoughts of peace, and not of evil, to give you an expected end.',
  ),
  (
    reference: '2 Corinthians 5:17',
    text:
        'Therefore if any man be in Christ, he is a new creature: old things are passed away; behold, all things are become new.',
  ),
  (
    reference: 'Hebrews 13:8',
    text: 'Jesus Christ the same yesterday, and to day, and for ever.',
  ),
  (
    reference: 'Nehemiah 8:10',
    text: 'For the joy of the LORD is your strength.',
  ),
  (
    reference: 'Psalm 34:8',
    text:
        'O taste and see that the LORD is good: blessed is the man that trusteth in him.',
  ),
];

/// The verse for [day] (today by default); the same all day, a different one tomorrow.
({String reference, String text}) verseForDay([DateTime? day]) {
  final d = day ?? DateTime.now();
  final dayNumber =
      DateTime.utc(d.year, d.month, d.day).millisecondsSinceEpoch ~/
      Duration.millisecondsPerDay;
  return dailyVerses[dayNumber % dailyVerses.length];
}
