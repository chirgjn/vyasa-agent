# Writing Prose Style

How to write clear, scannable prose in reference docs, tutorials, and guides. For structure and sizing, see `framework/guides/writing-reference-docs.md`. For conventions that go in `AGENTS.md`, see `framework/guides/writing-conventions.md`.

______________________________________________________________________

## Voice and Tone

- **Active voice, present tense** — "Select the file" not "The file should be selected." Use future tense only when something genuinely hasn't happened yet.
- **Always use contractions** — it's, you'll, don't, can't, doesn't, won't. Never write "do not" when "don't" works. Contractions make docs feel human, not robotic.
- **Don't call things "easy" or "simple"** — if the reader finds it hard, you lose trust. Describe what to do, not how hard it is.
- **Lead with the point** — bury context, not the answer. The first sentence of any section should tell the reader what they'll get.
- **Address the reader as "you"** — not "we" or "the user." Second person is direct and unambiguous.
- **Replace weak verbs with precise ones** — "is", "occurs", "happens" dilute meaning. The verb is the engine of a sentence.

Weak verb patterns to replace:

| Weak | Strong |
|---|---|
| "An error occurs when…" | "The compiler throws an error when…" |
| "There is a function that…" | "The `distribute` function…" |

______________________________________________________________________

## Terminology

- **One term per concept** — pick one name and use it throughout the doc. Don't alternate between "Protocol Buffers" and "protobufs" unpredictably. Inconsistency forces the reader to wonder if you mean two different things.
- **Define on first use** — every new term gets a definition or a link to one the first time it appears. Readers shouldn't have to guess.
- **Acronyms** — spell out on first use: "Transmission Control Protocol (TCP)." Use the acronym only after that. If the full term appears fewer than 3 times, don't bother with an acronym — just spell it out each time.

______________________________________________________________________

## Pronouns

- **Repeat the noun if the antecedent is more than 5 words away** — or if another noun intervenes. Ambiguous pronouns are a top source of confusion.
- **Attach a noun to every demonstrative** — "this setting", "that parameter", not bare "this" or "that."

______________________________________________________________________

## Procedures and Instructions

These rules apply when writing step-by-step instructions in reference docs or tutorials.

### Step rules

- **Every step starts with a verb** (imperative): Select, Open, Enter, Go to, Clear.
- **Location before action:** "In the **Settings** panel, select **Advanced**" — not the reverse.
- **Max 7 steps.** More than 7 means split into sub-procedures.
- Numbered list for sequences. Bullet for a single step or unordered options.
- End each step with a period. Exception: if the step ends with user-typed input that has no punctuation, omit the period.

### Input-neutral verbs

Use verbs that don't assume a specific input device.

| Action | Use | Not |
|---|---|---|
| Choose an item | **Select** | click, tap, hit |
| Navigate | **Go to** | navigate to |
| Launch app/file | **Open** | launch, click |
| Remove a checkmark | **Clear** | uncheck, deselect |
| Flip a toggle | **Turn on / Turn off** | enable, disable, toggle |
| Type something | **Enter** | type, input |

______________________________________________________________________

## Lists

### When to use a list

Use a list when:

- 3+ items that would otherwise form a long sentence.
- Sequential steps (numbered).
- Parallel items that benefit from visual separation.
- Don't use a list for fewer than 3 items — write it inline.

### Punctuation

End punctuation varies by item type:

| Item type | Punctuation |
|---|---|
| Complete sentences | End with period |
| Short phrases (3 words or fewer) | No end punctuation |
| Mixed lengths | Use periods on all for consistency |
| Intro sentence before a list | Colon |

- Items in a list must be grammatically parallel.
- Don't mix sentence fragments and full sentences in the same list.

______________________________________________________________________

## Tables

- Every table needs a header row.
- Left column is the row identifier (command name, setting, feature).
- All cells in a column must be parallel in structure.
- Don't leave cells blank — use "None" or "N/A" if needed.
- Intro before a table must be a complete sentence ending in a colon.

______________________________________________________________________

## Numbers in Prose

Follow these rules for numerals vs. spelled-out numbers:

| Case | Rule | Example |
|---|---|---|
| 0–9 | Spell out | "three files" |
| 10 and above | Numerals | "15 steps" |
| Starts a sentence | Always spell out | "Twenty users reported…" |
| Ranges | En dash, no spaces | "5–10 minutes" |

______________________________________________________________________

## Common Substitutions

Cut filler. Replace formal phrasing with direct alternatives.

| Don't write | Write instead |
|---|---|
| "Please note that…" | Cut it — state the fact directly |
| "In order to" | "To" |
| "Utilize" | "Use" |
| "Prior to" | "Before" |
| "At this point in time" | "Now" |
| "It is recommended that" | "We recommend" or just state it |
| "There is a way to…" | Start with the verb: "To do X, …" |
| "End user" / "the user" | "you" |

______________________________________________________________________

## Sentence Structure

- One idea per sentence.
- Keep sentences under ~25 words. Longer than that — split or convert to a list.
- Don't chain 3+ clauses with and/or/but. Max two conjunctions per sentence.
- Include "that" and "who" for clarity — "Verify that the file exists" not "Verify the file exists."
- Place conditions before actions — "If the build fails, run `make clean`" not "Run `make clean` if the build fails." Readers who don't meet the condition can skip ahead.

______________________________________________________________________

## Links

- Use meaningful link text: "Learn about accessibility" not "click here" or "read more."
- Don't use bare URLs in prose — wrap them in descriptive text.

______________________________________________________________________

## Formatting Quick-Reference

Apply these conventions consistently across all docs:

| Element | Format | Example |
|---|---|---|
| Headings | Sentence case | "Configure the build environment" |
| Code (API names, filenames, CLI commands) | `code font` | "Run `gcloud init`." |
| UI elements | **Bold** | "Select **Submit**." |
| New terms on first use | *Italics* | "A *pod* is the smallest deployable unit." |
| Placeholder variables | `UPPER_SNAKE_CASE` in code font | "Replace `PROJECT_ID` with your project ID." |
| Dates | Unambiguous format | "January 3, 2025" — never "01/03/2025" |

______________________________________________________________________

## Code Samples

- **Correct, concise, and runnable** — readers copy-paste. Broken samples destroy trust.
- **Comment only the non-obvious** — don't comment `i++ // increment i`.
- **Show examples and anti-examples** — when demonstrating a pattern, also show what not to do. Anti-examples inoculate readers against common mistakes.
- **Production-ready** — no security holes, no placeholder auth. Readers treat samples as templates.

______________________________________________________________________

*Rules in this guide are synthesised from [Google Developer Documentation Style Guide](https://developers.google.com/style), [Technical Writing One](https://developers.google.com/tech-writing/one), [Technical Writing Two](https://developers.google.com/tech-writing/two) (CC BY 4.0, Google), and the [Microsoft Writing Style Guide](https://learn.microsoft.com/en-us/style-guide/welcome/).*
