---
name: simplified-technical-english
description: Write technical text — documentation, READMEs, PR/commit descriptions, error messages, UI copy, explanations — in plain, controlled English instead of jargon-heavy AI prose. Use this skill whenever producing user-facing or documentation text, when the user asks to "simplify this", "remove the jargon", "write in plain English", or complains that AI writing invents abbreviations, acronyms, or buzzwords that make text harder to read.
---

# Simplified Technical English

Rules adapted from ASD-STE100 (Simplified Technical English, built for aerospace maintenance manuals so non-native speakers and translators can't misread them). This skill keeps the spirit — short sentences, one word per meaning, no invented shorthand — without the full 900-word aerospace dictionary, which doesn't fit general software writing.

The rule that matters most for AI-generated text: **never coin an abbreviation, acronym, or shorthand on the fly.** Spell the term out. If a real, already-established abbreviation exists (API, URL, ID), it's fine — but check it's genuinely standard, not something invented mid-paragraph to sound efficient.

## Rules

1. **No invented abbreviations.** Don't shorten a term because you used it three times ("the Config Mgmt Sys (CMS)" for something nobody outside this text calls that). Spell it out every time, or use the plain word.
2. **One word, one meaning.** Pick a plain word for a concept and reuse the same word throughout — don't vary vocabulary for style ("delete" / "remove" / "purge" for the same action). Varied synonyms read as elegant in prose; in technical text they read as three different operations.
3. **Short sentences.** Cap around 20 words for instructions and steps, 25 for description/explanation. One instruction per sentence.
4. **Active voice.** "The build fails when X" not "X causes the build to be failed by the pipeline." Use passive only when the actor genuinely doesn't matter.
5. **Plain verb forms.** Simple present, past, future, imperative, or infinitive. Avoid stacked auxiliaries and hedging chains ("would have been able to", "may potentially need to").
6. **Noun clusters ≤ 3 words.** "database connection pool timeout" is at the edge; "distributed database connection pool timeout retry handler config" is not readable — break it up or use a short sentence instead.
7. **Don't drop words to sound terse.** Keep the subject, verb, and article. Telegraphic style ("Config missing, retry fails, check logs") reads as cryptic, not concise.
8. **One topic per paragraph**, roughly six sentences max. Use a vertical list the moment a sentence starts enumerating steps or conditions.
9. **Cut hedge-and-inflate filler.** Words like "leverage," "utilize," "seamless," "robust," "delve," "unlock," "streamline" almost always have a shorter plain synonym ("use," "smooth," "solid," "look into," "enable," "simplify"). See [references/watchlist.md](https://github.com/steingran/skills/blob/main/simplified-technical-english/references/watchlist.md) for the full swap list and before/after examples.

## Self-check before sending technical text

- Any abbreviation I just invented? Spell it out.
- Any word doing two jobs (used with two different meanings in this text)? Split it.
- Any sentence over ~25 words, or with more than one instruction in it? Split it.
- Any noun cluster of 4+ words? Rebuild as a short phrase or sentence.
- Any filler word from the watchlist? Cut or replace it.

This is a discipline for technical/instructional writing, not a constraint on ordinary conversational replies — don't flatten casual chat into manual-speak.
