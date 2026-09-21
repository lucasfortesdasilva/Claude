# Neinbox

A satirical job application simulator, in German and English. Every application
is a gamble: a fast rejection with the honest reason nobody ever gives you,
ninety days of silence, or — rarely — an interview invitation with terms
attached.

The whole site is one file: `index.html`. No build step, no dependencies to
install, no server. Open it in a browser and it works.

---

## Publishing it

The repository is public, so GitHub Pages is free.

1. Go to **github.com/lucasfortesdasilva/Claude → Settings → Pages**
2. Under **Source**, choose **Deploy from a branch**
3. **Branch:** `claude/tinder-job-hunter-app-wyavwm` — **Folder:** `/ (root)`
4. **Save**, then wait a minute or two

That gives you:

| URL | Serves |
| --- | --- |
| `https://lucasfortesdasilva.github.io/Claude/` | the personal site at the repo root |
| `https://lucasfortesdasilva.github.io/Claude/neinbox/` | **Neinbox** |

The `.nojekyll` file at the repo root stops GitHub running the files through
Jekyll, which would otherwise ignore some paths.

### Using a real domain

That URL is fine for testing and bad for sharing. To use `neinbox.de` or
similar:

1. Add a file called `CNAME` at the repo root containing only your domain,
   e.g. `neinbox.de`
2. At your registrar, point the domain at GitHub Pages:
   - four `A` records for the apex: `185.199.108.153`, `185.199.109.153`,
     `185.199.110.153`, `185.199.111.153`
   - or a `CNAME` record for `www` pointing at `lucasfortesdasilva.github.io`
3. Back in **Settings → Pages**, enter the domain and tick **Enforce HTTPS**
   once the certificate has been issued

Verify those IPs against GitHub's current documentation before relying on
them — they have changed before.

---

## Connecting the story form

The form at **Form NB-01** collects experience reports. Out of the box it runs
in demo mode: it validates, it shows the thank-you screen, and it sends
nothing. The screen says so.

To make it real, edit the `COLLECT` block near the top of the `<script>` in
`index.html`:

```js
var COLLECT = {
  mode: "supabase",                        // was "none"
  url: "https://YOURPROJECT.supabase.co",
  apiKey: "YOUR_ANON_KEY",
  table: "stories"
};
```

### Setting up Supabase

Create the project in the **EU (Frankfurt)** region. The region cannot be
changed afterwards, and for a German audience you want the data in Germany.

Then run this in the SQL editor:

```sql
create table public.stories (
  id                uuid primary key default gen_random_uuid(),
  created_at        timestamptz not null default now(),
  city              text,
  industry          text,
  waited            text,
  heard_back        text,
  ad_language       text not null,
  applications_12m  int,
  story             text not null,
  consent_publish   boolean not null default false,
  consent_contact   boolean not null default false,
  consent_updates   boolean not null default false,
  email             text,
  form_language     text,
  submitted_at      timestamptz
);

alter table public.stories enable row level security;

-- Anyone may add a story.
create policy "anon can insert" on public.stories
  for insert to anon with check (true);

-- Deliberately no select policy: with RLS on and no read policy, the public
-- key cannot read anything back. You read the stories in the Supabase
-- dashboard, where you are authenticated.
```

### The one thing you must not get wrong

**The anon key sits in the page and is readable by anyone.** That is how
Supabase is designed to work, and it is only safe because Row Level Security
decides what that key is allowed to do.

If you enable RLS and add no `select` policy, the public can insert stories
and cannot read them. If you skip `alter table ... enable row level security`,
or add a permissive read policy, **anyone can download every story anyone has
ever told you**, including the email addresses.

After setup, check it: open the site, submit a test story, then from a signed-
out browser try to fetch
`https://YOURPROJECT.supabase.co/rest/v1/stories?select=*&apikey=YOUR_ANON_KEY`.
You should get an empty array, not your data.

---

## Analytics

Off until configured. Edit the `ANALYTICS` block near the top of the `<script>`:

```js
var ANALYTICS = {
  provider: "goatcounter",   // was "none"; or "plausible"
  site: "neinbox",           // goatcounter: your code -> neinbox.goatcounter.com
                             // plausible:   your domain, e.g. "neinbox.de"
  respectDNT: true
};
```

Both options are EU-hosted, cookieless, and collect no personal data, so **no
cookie banner is required**. That matters on this site more than most: greeting
people with a consent modal would contradict everything the page says about not
taking their data. Do not swap in Google Analytics — it needs a banner, and
several German data protection authorities have ruled against its use.

- **GoatCounter** — free for personal use, open source, self-hostable.
  Sign up, pick a code, put the code in `site`.
- **Plausible** — paid, more polished dashboard. Put your domain in `site`.

`respectDNT: true` skips loading entirely when the browser sends Do Not Track
or Global Privacy Control. It costs you a few percent of visits and is
consistent with the rest of the site. Set it to `false` if you would rather
have the numbers.

### Events

Seven funnel steps are tracked by name:

| Event | Fires when |
| --- | --- |
| `cv-opened` | the CV screen is opened |
| `cv-parsed` | a CV is successfully read |
| `cv-shredded` | the shredder is run |
| `application-sent` | an application is swiped or clicked through |
| `truth-reached` | the fourth-wall card is shown |
| `story-opened` | the story form is opened |
| `story-submitted` | a story is actually sent |

That gives you the only funnel that matters: arrivals → applications → story
form opened → story submitted.

**Events carry a name and nothing else.** No CV text, no story text, no form
values, no identifiers. Keep it that way — the question is how many people
reached a step, never who they were or what they wrote.

### Where it runs

Analytics runs wherever the file is actually served — which today means the
GitHub Pages deployment. There is no separate staging site: the Pages URL is
both the test version and the live one, so your own testing will show up in
the numbers. At current volume that is noise you can ignore; once real traffic
arrives, both providers offer a way to exclude your own visits.

It does **not** run in a Claude artifact preview. Artifacts block outbound
requests, so the script never loads — which is the behaviour you want anyway,
since preview traffic would only pollute the stats.

---

## What the form collects

Structured fields first, because a pile of prose is not a dataset:

- city, industry, how long they waited, whether they ever heard back
- **whether the ad was in English while demanding C1/C2 German** — the one
  field that produces a statistic nobody currently has
- applications in the last 12 months
- the story itself

Then three separate, unticked consent boxes: publish anonymously / contact me
about it / keep me posted. The email field only appears if one of the last two
is ticked, and is required then.

### Consent notes

Under GDPR, consent has to be specific and informed, and purpose limitation
binds you to what you asked for. Collecting for a newsletter and later using
the material in a book is a violation. That is why the publication consent is
its own box, worded for publication, and asked up front.

Pre-ticked boxes are not valid consent (CJEU, *Planet49*, 2019). All three
boxes here start empty and must stay that way.

If you ever email these people, use double opt-in — it is the German standard
for proving consent, and §7 UWG governs commercial email.

---

## What is deliberately not collected

The CV feature parses PDF, DOCX and plain text **entirely in the browser**.
There is no upload, because there is no server to upload to. The extracted
text lives in one variable and the shredder overwrites it.

`buildPayload()` in the story form does not read `cvText` and must never start
to. The wall between "your CV never leaves this tab" and "you chose to send
this form" is the reason people trust the first claim. Blur it once and the
shredder becomes a lie retroactively.

---

## Editing the content

Everything is in the one `<script>` block:

| Constant | What it holds |
| --- | --- |
| `UI` | every visible string, in `de` and `en` |
| `JOBS` | the 13 fictional listings, both languages, with `level` and `tags` |
| `REASONS` | rejection reasons, `[German, English]` pairs |
| `INVITE_TERMS` | the conditions attached to an interview invitation |
| `GHOST_BEATS` | the ninety-day silence timeline |
| `ODDS` | outcome probabilities per mode |
| `SELECTS` | the story form's dropdown options |
| `COLLECT` | where the story form posts |

Every company, person and rejection is fictional, and each letter is labelled
as a simulation. Keep it that way: a generator that produced realistic
rejection letters attributed to real named companies would be a different and
much worse thing.
