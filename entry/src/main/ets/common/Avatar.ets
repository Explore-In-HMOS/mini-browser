const AVATAR_PALETTE: string[] = [
  '#38BDF8', // sky
  '#F97316', // accent orange
  '#22C55E', // green
  '#818CF8', // indigo
  '#F472B6', // pink
  '#34D399', // emerald
  '#FB7185', // rose
  '#CBD5E1', // slate
  '#FBBF24', // amber
  '#A78BFA'  // violet
];

export class Avatar {
  static colorFor(seed: string): string {
    if (!seed || seed.length === 0) {
      return AVATAR_PALETTE[0];
    }
    let hash = 0;
    for (let i = 0; i < seed.length; i++) {
      hash = (hash * 31 + seed.charCodeAt(i)) & 0x7fffffff;
    }
    return AVATAR_PALETTE[hash % AVATAR_PALETTE.length];
  }

  static monogram(text: string): string {
    const t = text ? text.trim() : '';
    if (t.length === 0) {
      return '?';
    }
    const c = t.charAt(0).toUpperCase();
    return c;
  }

  static host(url: string): string {
    if (!url) {
      return '';
    }
    let s = url;
    const scheme = s.indexOf('://');
    if (scheme >= 0) {
      s = s.substring(scheme + 3);
    }
    const slash = s.indexOf('/');
    if (slash >= 0) {
      s = s.substring(0, slash);
    }
    if (s.indexOf('www.') === 0) {
      s = s.substring(4);
    }
    return s;
  }
}
