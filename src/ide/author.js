// Help > About the Author: who made Baysik, in the same DOS dialog style as the rest.
(function (RC) {
  'use strict';
  const { h } = RC.UI;
  const link = (href, text) => h('a', { href, target: '_blank', rel: 'noopener' }, text);

  const AUTHOR = {
    name: 'Jyotiprakash Mishra',
    roles: [
      'Assistant Professor of Computer Science, KIIT',
      'Co-founder and CEO, ENineHQ Technologies',
      'PhD candidate (thesis submitted), BITS Pilani',
    ],
    profile: 'Computer scientist, teacher and engineer: sixteen years across enterprise software, healthcare technology, '
      + 'university teaching and hardware-security research on RISC-V. Doctoral research at BITS Pilani on the security of the '
      + 'hardware-software interface (microarchitectural side channels, memory encryption and hardware-assisted malware '
      + 'detection), with the degree expected in December 2026. Formerly a Team Lead at Epic in the USA and a Senior Member of '
      + 'Technical Staff at Oracle.',
    education: [
      ['PhD in Computer Science', 'BITS Pilani', '2021 to 2026 (expected)'],
      ['MS in Computer Science', 'University of Wisconsin-Madison', '2014 to 2016, GPA 3.9/4.0, with distinction'],
      ['BE (Hons.) in Computer Science', 'BITS Pilani', '2006 to 2010, CGPA 9.53/10, with distinction'],
    ],
    work: [
      ['Co-founder and CEO', 'ENineHQ Technologies', '2022 to now'],
      ['Assistant Professor', 'KIIT, Bhubaneswar', '2020 to now'],
      ['Team Lead, earlier Software Developer', 'Epic Systems, Madison, USA', '2015 to 2020'],
      ['Teaching Assistant, Introduction to Operating Systems', 'University of Wisconsin-Madison', '2014 to 2016'],
      ['Senior Member of Technical Staff', 'Oracle, Bangalore', '2010 to 2014'],
    ],
    books: [
      'RISC-V Architecture and XV6: Instruction Set Architecture, Systems Programming, and Kernel Development (De Gruyter Brill, 2026)',
      'Cryptographic Foundations: Symmetric and Public-Key Cryptography, Hashes, Digital Signatures, and Protocols (De Gruyter Brill, 2026)',
    ],
    numbers: [['16', 'years of experience'], ['2', 'books'], ['6', 'published patents'], ['16', 'research publications'], ['78', 'free lectures on YouTube']],
    made: [
      ['xv6, line by line', 'https://xv6.jyotiprakash.org', 'every line of a teaching operating system explained'],
      ['µSystem 8086', 'https://8086.jyotiprakash.org', 'a PC/XT you wire chip by chip, which boots FreeDOS'],
      ['Lohgo', 'https://lohgo.jyotiprakash.org', 'Logo with turtle graphics and a debugger'],
      ['See', 'https://see.jyotiprakash.org', 'C89 step by step, down to the byte'],
      ['Strux', 'https://strux.jyotiprakash.org', 'data structures animated from real C code'],
      ['NetSim', 'https://netsim.jyotiprakash.org', 'a network simulator you can watch packet by packet'],
      ['Compy', 'https://compy.jyotiprakash.org', 'a C compiler you can see through'],
    ],
    links: [
      ['mail@jyotiprakash.org', 'mailto:mail@jyotiprakash.org'],
      ['blog.jyotiprakash.org', 'https://blog.jyotiprakash.org'],
      ['eninehq.com', 'https://eninehq.com'],
      ['LinkedIn', 'https://www.linkedin.com/in/mishrajp88/'],
      ['GitHub', 'https://github.com/ShowMeTheStack'],
    ],
  };

  RC.authorDialog = function () {
    const A = AUTHOR;
    const photo = h('div.author-photo', h('img', { src: 'data:image/png;base64,@@AUTHOR_PNG@@', alt: 'Photo of ' + A.name, width: '192', height: '240' }));
    const head = h('div.author-head', photo,
      h('div', h('div.author-name', A.name), ...A.roles.map((r) => h('div.author-role', r)),
        h('div.author-nums', ...A.numbers.map(([n, l]) => h('div', h('b', n), ' ' + l))),
        h('div.author-links', ...A.links.map(([t, u], i) => [i ? ' · ' : '', link(u, t)]))));
    const section = (title, rows) => h('div.author-sec', h('div.author-sec-t', title), ...rows);
    const body = h('div.author',
      head,
      h('p', A.profile),
      section('Education', A.education.map(([d, s, y]) => h('div.author-row', h('b', d), ', ' + s + ' (' + y + ')'))),
      section('Work', A.work.map(([r, o, y]) => h('div.author-row', h('b', r), ', ' + o + ' (' + y + ')'))),
      section('Books', A.books.map((b) => h('div.author-row', b))),
      section('Other things I made', A.made.map(([n, u, d]) => h('div.author-row', link(u, n), ': ' + d))),
      h('p.muted', { style: { marginTop: '10px' } }, 'Baysik grew out of a first love for BASIC. If it brings back memories or teaches someone their first program, I would love to hear about it.'));
    return RC.UI.modal({ title: 'About the Author', body, wide: true, buttons: [{ label: 'OK', value: true, primary: true }], enterValue: true });
  };
})(RC);
